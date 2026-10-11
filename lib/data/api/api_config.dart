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
}
