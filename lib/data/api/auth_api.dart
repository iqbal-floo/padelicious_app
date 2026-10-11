import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Logs in and stores the bearer token for subsequent requests.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String deviceName = 'flutter',
  }) async {
    final json = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
      'device_name': deviceName,
    });

    final token = json['token'] as String?;
    if (token != null) await _client.saveToken(token);

    return (json['user'] as Map<String, dynamic>?) ?? const {};
  }

  Future<Map<String, dynamic>> me() async => _client.get('/auth/me');

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } finally {
      // Drop the local token even if the server call fails.
      await _client.clearToken();
    }
  }
}
