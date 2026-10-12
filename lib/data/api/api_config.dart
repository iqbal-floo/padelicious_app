/// Where the backend lives.
///
/// Override at build time:
///   flutter run --dart-define=API_BASE_URL=https://api.example.com
///
/// The default targets a local Laravel server. Note that `localhost` from
/// an Android emulator is the emulator itself — use 10.0.2.2 instead.
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get apiRoot => '$baseUrl/api/v1';

  /// Public spectator scoreboard for a match.
  static String liveMatchUrl(String matchId) => '$baseUrl/live/$matchId';

  /// Server-Sent Events stream of one match's score.
  static String liveStreamUrl(String matchId) =>
      '$apiRoot/live/matches/$matchId/stream';

  /// Printable order of play for a session. `pdf: true` downloads the
  /// file; [startTime] ("08:15") adds a time column, one [slotMinutes]
  /// per round.
  static String orderOfPlayUrl(
    String sessionId, {
    bool pdf = false,
    String? startTime,
    int slotMinutes = 15,
  }) {
    final params = <String, String>{
      if (pdf) 'format': 'pdf',
      if (startTime != null) 'start': startTime,
      if (startTime != null) 'slot': '$slotMinutes',
    };
    final query =
        params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return '$baseUrl/sessions/$sessionId/order-of-play$query';
  }
}
