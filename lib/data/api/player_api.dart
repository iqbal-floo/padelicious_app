import 'api_client.dart';

/// A player as the backend lists it: the unique `@username` is what tells
/// two players with the same name apart.
class PlayerRow {
  const PlayerRow({
    required this.id,
    required this.displayName,
    required this.username,
    required this.initials,
    required this.avatarColorIndex,
    this.gender,
    this.isGuest = false,
  });

  final String id;
  final String displayName;
  final String username;
  final String initials;
  final int avatarColorIndex;
  final String? gender;
  final bool isGuest;

  String get handle => '@$username';

  factory PlayerRow.fromJson(Map<String, dynamic> json) => PlayerRow(
        id: json['id'] as String,
        displayName: '${json['display_name'] ?? ''}',
        username: '${json['username'] ?? ''}',
        initials: '${json['initials'] ?? ''}',
        avatarColorIndex: (json['avatar_color_index'] as num?)?.toInt() ?? 0,
        gender: json['gender'] as String?,
        isGuest: json['is_guest'] == true,
      );
}

/// Finding players and adding guest players by hand.
class PlayerApi {
  PlayerApi(this._client);

  final ApiClient _client;

  /// Matches display names and usernames ("@handle" works too).
  Future<List<PlayerRow>> search(String query, {int perPage = 25}) async {
    final json = await _client.get('/players', query: {
      if (query.trim().isNotEmpty) 'search': query.trim(),
      'per_page': perPage,
    });
    return ((json['data'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PlayerRow.fromJson)
        .toList();
  }

  /// Adds a guest player (no account). The username must be unique;
  /// the backend reports a clash as a `username` field error.
  Future<PlayerRow> createGuest({
    required String displayName,
    required String username,
    String? gender,
    double? skillLevel,
  }) async {
    final json = await _client.post('/players', body: {
      'display_name': displayName.trim(),
      'username': username.trim().toLowerCase(),
      if (gender != null) 'gender': gender,
      if (skillLevel != null) 'skill_level': skillLevel,
    });
    return PlayerRow.fromJson(json['data'] as Map<String, dynamic>);
  }
}

/// One person from a Reclub meet, as a player here plus the list they were
/// on at Reclub (`confirmed` or `waitlisted`).
class ReclubPlayer {
  const ReclubPlayer({required this.player, required this.status});

  final PlayerRow player;
  final String status;
}

class ReclubImportResult {
  const ReclubImportResult({required this.code, required this.title, required this.players});

  final String code;
  final String? title;
  final List<ReclubPlayer> players;
}

extension ReclubImport on PlayerApi {
  /// Reads the roster of reclub.co/m/{code}. The backend creates or reuses
  /// a player for each person; nothing is added to a session yet.
  Future<ReclubImportResult> importReclub(String code) async {
    final json = await _clientOf(this).post('/reclub/import', body: {'code': code.trim()});
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return ReclubImportResult(
      code: '${data['code'] ?? code}',
      title: data['title'] as String?,
      players: ((data['players'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((r) => ReclubPlayer(
                player: PlayerRow.fromJson(r['player'] as Map<String, dynamic>),
                status: '${r['status'] ?? 'confirmed'}',
              ))
          .toList(),
    );
  }
}

ApiClient _clientOf(PlayerApi api) => api._client;

/// Suggests a username from a display name: "Rina Hartono" -> rina.hartono.
String suggestUsername(String displayName) {
  final slug = displayName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._]+'), '.')
      .replaceAll(RegExp(r'^\.+|\.+$'), '');
  return slug.length > 30 ? slug.substring(0, 30) : slug;
}

final RegExp usernamePattern = RegExp(r'^[a-z0-9][a-z0-9._]{1,29}$');

String? validateUsername(String value) {
  final v = value.trim().toLowerCase();
  if (v.isEmpty) return 'Username is required';
  if (!usernamePattern.hasMatch(v)) {
    return 'Lowercase letters, digits, dots and underscores (2–30)';
  }
  return null;
}
