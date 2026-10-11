import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../theme/app_colors.dart';
import '../player_repository.dart';
import 'api_client.dart';

/// Backend-backed [PlayerRepository]. Drop-in replacement for
/// MockPlayerRepository — call sites depend only on the interface.
class ApiPlayerRepository implements PlayerRepository {
  ApiPlayerRepository(this._client);

  final ApiClient _client;

  /// Player ids by display name, so callers that still key off names
  /// (as the current screens do) can resolve a uuid.
  final Map<String, String> _idsByName = {};

  String? idFor(String displayName) => _idsByName[displayName];

  @override
  Future<List<Player>> fetchAllPlayers() async {
    final json = await _client.get('/players', query: {'per_page': 100});
    final rows = (json['data'] as List?) ?? const [];

    return rows.whereType<Map<String, dynamic>>().map((row) {
      final name = '${row['display_name'] ?? ''}';
      final id = row['id'] as String?;
      if (id != null && name.isNotEmpty) _idsByName[name] = id;
      return _player(row);
    }).toList();
  }

  @override
  Future<PlayerProfile?> fetchPlayerProfile(String name) async {
    final id = _idsByName[name];
    if (id == null) {
      // Not cached yet — populate the index, then retry once.
      await fetchAllPlayers();
      final retry = _idsByName[name];
      if (retry == null) return null;
      return _profile(retry);
    }
    return _profile(id);
  }

  Future<PlayerProfile?> _profile(String id) async {
    final json = await _client.get('/players/$id');
    final row = json['data'] as Map<String, dynamic>?;
    if (row == null) return null;

    final stats = (row['stats'] as Map?) ?? const {};
    final level = row['skill_level'];
    final label = row['skill_level_label'];

    return PlayerProfile(
      player: _player(row),
      sessions: (stats['sessions_played'] as num?)?.toInt() ?? 0,
      level: [
        if (level != null) '$level',
        if (label != null && '$label'.isNotEmpty) '$label',
      ].join(' · '),
    );
  }

  Player _player(Map<String, dynamic> row) {
    final index = (row['avatar_color_index'] as num?)?.toInt() ?? 0;
    return Player(
      name: '${row['display_name'] ?? ''}',
      initials: '${row['initials'] ?? ''}',
      bg: _bg(index),
      color: _fg(index),
      fromReclub: false,
    );
  }

  // avatar_color_index (0-7) maps onto the existing chip palette.
  Color _bg(int i) => AppColors.chipPairsBg[i % AppColors.chipPairsBg.length];

  Color _fg(int i) => AppColors.chipPairsFg[i % AppColors.chipPairsFg.length];
}
