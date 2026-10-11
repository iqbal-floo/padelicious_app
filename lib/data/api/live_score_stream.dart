import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/live_score.dart';
import 'api_config.dart';

/// Subscribes to the backend's Server-Sent Events stream for one match.
///
/// Emits a [LiveScore] whenever the server pushes a change, and reconnects
/// automatically if the connection drops.
class LiveScoreStream {
  LiveScoreStream(this.matchId, {Dio? dio}) : _dio = dio ?? Dio();

  final String matchId;
  final Dio _dio;

  StreamController<LiveScore>? _controller;
  StreamSubscription<String>? _lines;
  Timer? _retry;
  bool _closed = false;

  Stream<LiveScore> get stream {
    _controller ??= StreamController<LiveScore>.broadcast(
      onListen: _connect,
      onCancel: dispose,
    );
    return _controller!.stream;
  }

  Future<void> _connect() async {
    if (_closed) return;

    try {
      final response = await _dio.get<ResponseBody>(
        ApiConfig.liveStreamUrl(matchId),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // The stream is long-lived; no receive timeout.
          receiveTimeout: Duration.zero,
        ),
      );

      final body = response.data;
      if (body == null) return _scheduleRetry();

      String? event;

      _lines = utf8.decoder
          .bind(body.stream.map((chunk) => chunk.toList()))
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('event: ')) {
            event = line.substring(7).trim();
            return;
          }
          if (line.startsWith('data: ')) {
            final payload = line.substring(6);
            if (event == 'score') _emit(payload);
            return;
          }
          // Blank line terminates an event; ': comment' is a keep-alive.
          if (line.isEmpty) event = null;
        },
        onDone: _scheduleRetry,
        onError: (_) => _scheduleRetry(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleRetry();
    }
  }

  void _emit(String payload) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      _controller?.add(LiveScore.fromJson(json));
    } catch (_) {
      // Ignore a malformed frame rather than killing the stream.
    }
  }

  void _scheduleRetry() {
    if (_closed) return;
    _lines?.cancel();
    _lines = null;
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), _connect);
  }

  Future<void> dispose() async {
    _closed = true;
    _retry?.cancel();
    await _lines?.cancel();
    await _controller?.close();
    _controller = null;
  }
}
