import '../data/api/api_client.dart';
import '../data/api/api_exception.dart';
import '../data/api/auth_api.dart';

/// Result of an auth attempt, in a form the screens can branch on.
class AuthResult {
  final bool ok;
  final String? message;

  /// Field-level errors from the backend, keyed by form field.
  final Map<String, List<String>> fieldErrors;

  const AuthResult.success()
      : ok = true,
        message = null,
        fieldErrors = const {};

  const AuthResult.failure(this.message, {this.fieldErrors = const {}})
      : ok = false;

  /// Backend field name -> first message, for inline form errors.
  String? errorFor(String field) {
    final list = fieldErrors[field];
    return (list == null || list.isEmpty) ? null : list.first;
  }
}

/// Owns sign-in, registration and sign-out against the backend.
class AuthController {
  AuthController({ApiClient? client})
      : _client = client ?? ApiClient(),
        _api = AuthApi(client ?? ApiClient());

  final ApiClient _client;
  final AuthApi _api;

  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  Map<String, dynamic>? get _player =>
      (_user?['player'] as Map?)?.cast<String, dynamic>();

  String? get displayName =>
      _player?['display_name'] as String? ?? _user?['full_name'] as String?;

  /// The name as given at sign-up, e.g. "Rina Hartono".
  String? get fullName => _user?['full_name'] as String?;

  String? get email => _user?['email'] as String?;

  /// The unique handle shown as @username.
  String? get username => _player?['username'] as String?;

  /// Two-letter avatar initials. Falls back to deriving them from the
  /// display name so the avatar is never blank while the profile loads.
  String? get initials {
    final stored = _player?['initials'] as String?;
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim().toUpperCase();
    }

    final name = displayName?.trim();
    if (name == null || name.isEmpty) return null;

    final words = name.split(RegExp(r'\s+'));
    final letters = words.length >= 2
        ? words[0][0] + words[1][0]
        : name.substring(0, name.length >= 2 ? 2 : 1);

    return letters.toUpperCase();
  }

  /// Index into the shared 8-colour avatar palette.
  int get avatarColorIndex =>
      ((_player?['avatar_color_index'] as num?)?.toInt() ?? 0) % 8;

  /// When the account was created, for the "Member since" line.
  DateTime? get memberSince {
    final raw = _user?['created_at'] as String?;
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  Future<bool> get isSignedIn => _client.hasToken;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) =>
      _attempt(() async {
        _user = await _api.login(email: email.trim(), password: password);
      });

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? username,
    String? gender,
  }) =>
      _attempt(() async {
        _user = await _api.register(
          fullName: fullName.trim(),
          username: username?.trim().toLowerCase(),
          email: email.trim(),
          password: password,
          passwordConfirmation: passwordConfirmation,
          gender: gender,
        );
      });

  /// The player's gender, as stored on their profile.
  String? get gender => _player?['gender'] as String?;

  /// Mixed formats (Mix Americano, Mixicano) need this set.
  bool get hasGender {
    final g = gender;
    return g != null && g != 'undisclosed';
  }

  /// Updates the profile; used to set gender after sign-up.
  Future<AuthResult> updateProfile({
    String? fullName,
    String? displayName,
    String? gender,
  }) =>
      _attempt(() async {
        _user = await _api.updateProfile(
          fullName: fullName,
          displayName: displayName,
          gender: gender,
        );
      });

  /// Signs in with a Google access token obtained natively by the client.
  ///
  /// Returns a failure explaining the situation when the server has no
  /// Google credentials configured.
  Future<AuthResult> signInWithGoogle(String accessToken) => _attempt(() async {
        final user = await _api.signInWithGoogle(accessToken: accessToken);
        if (user == null) {
          throw ApiException(
            'Google sign-in is not set up yet.',
            statusCode: 503,
          );
        }
        _user = user;
      });

  /// Restores the session on launch if a token is already stored.
  Future<bool> restore() async {
    if (!await _client.hasToken) return false;
    try {
      _user = await _api.me();
      return true;
    } on ApiException {
      await _client.clearToken();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
  }

  Future<AuthResult> _attempt(Future<void> Function() body) async {
    try {
      await body();
      return const AuthResult.success();
    } on ApiException catch (e) {
      return AuthResult.failure(
        e.firstError ?? e.message,
        fieldErrors: e.errors,
      );
    } catch (_) {
      return const AuthResult.failure('Something went wrong. Please try again.');
    }
  }
}
