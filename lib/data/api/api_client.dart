import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'api_exception.dart';

/// Thin Dio wrapper: attaches the bearer token, and turns Dio errors into
/// [ApiException] so repositories and UI never import Dio types.
class ApiClient {
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? ApiConfig.apiRoot,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {'Accept': 'application/json'},
              // We map status codes ourselves rather than letting Dio throw.
              validateStatus: (_) => true,
            )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static const _tokenKey = 'padelicious.api_token';

  final Dio _dio;
  String? _cachedToken;

  Dio get raw => _dio;

  // ---- token ---------------------------------------------------------------

  Future<String?> _readToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    return _cachedToken = prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<bool> get hasToken async {
    final t = await _readToken();
    return t != null && t.isNotEmpty;
  }

  // ---- verbs ---------------------------------------------------------------

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) async =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(
    String path, {
    Object? body,
  }) async =>
      _send(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> patch(
    String path, {
    Object? body,
  }) async =>
      _send(() => _dio.patch(path, data: body));

  Future<Map<String, dynamic>> delete(
    String path, {
    Object? body,
  }) async =>
      _send(() => _dio.delete(path, data: body));

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    final Response<dynamic> response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw ApiException(
        switch (e.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout =>
            'The server took too long to respond.',
          DioExceptionType.connectionError =>
            'Cannot reach the server. Check your connection.',
          _ => 'Network error. Please try again.',
        },
      );
    }

    final status = response.statusCode ?? 0;
    final data = response.data;

    if (status >= 200 && status < 300) {
      if (data is Map<String, dynamic>) return data;
      if (data == null || (data is String && data.isEmpty)) return const {};
      return {'data': data};
    }

    final body = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    throw ApiException(
      (body['message'] as String?) ?? 'Request failed ($status).',
      statusCode: status,
      errors: _parseErrors(body['errors']),
    );
  }

  Map<String, List<String>> _parseErrors(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((v) => v.toString()).toList()
            : <String>[value.toString()],
      ),
    );
  }
}
