import 'api_client.dart';
import 'api_exception.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Creates an account and stores the returned token, so the user is
  /// signed in immediately. Returns the `user` payload.
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? gender,
    String deviceName = 'flutter',
  }) async {
    final json = await _client.post('/auth/register', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (gender != null) 'gender': gender,
      'device_name': deviceName,
      'accepted_terms': true,
    });

    final token = json['token'] as String?;
    if (token != null) await _client.saveToken(token);

    return (json['user'] as Map<String, dynamic>?) ?? const {};
  }

  /// Exchanges a Google access token for an API token.
  ///
  /// Returns null when the server has no Google credentials configured
  /// (503), so the UI can explain rather than show a hard failure.
  Future<Map<String, dynamic>?> signInWithGoogle({
    required String accessToken,
    String deviceName = 'flutter-google',
  }) async {
    try {
      final json = await _client.post('/auth/google', body: {
        'access_token': accessToken,
        'device_name': deviceName,
      });

      final token = json['token'] as String?;
      if (token != null) await _client.saveToken(token);

      return (json['user'] as Map<String, dynamic>?) ?? const {};
    } on ApiException catch (e) {
      if (e.statusCode == 503) return null;
      rethrow;
    }
  }

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

  /// Updates the signed-in user and their player profile. This is how an
  /// existing account sets its gender, which mixed formats require.
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? displayName,
    String? gender,
    double? skillLevel,
    int? avatarColorIndex,
  }) async =>
      _client.patch('/profile', body: {
        if (fullName != null) 'full_name': fullName,
        if (displayName != null) 'display_name': displayName,
        if (gender != null) 'gender': gender,
        if (skillLevel != null) 'skill_level': skillLevel,
        if (avatarColorIndex != null) 'avatar_color_index': avatarColorIndex,
      });

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } finally {
      // Drop the local token even if the server call fails.
      await _client.clearToken();
    }
  }
}
