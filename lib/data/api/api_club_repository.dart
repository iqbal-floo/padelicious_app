import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../models/player.dart';
import '../../theme/app_colors.dart';
import '../club_repository.dart';
import 'api_client.dart';

/// Backend-backed [ClubRepository].
///
/// Note: join/leave and createClub have no API endpoints yet, so they
/// throw rather than silently doing nothing. See docs/api.md.
class ApiClubRepository implements ClubRepository {
  ApiClubRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Club>> fetchClubs() async {
    final json = await _client.get('/clubs', query: {'per_page': 100});
    final rows = (json['data'] as List?) ?? const [];

    return rows.whereType<Map<String, dynamic>>().map((row) {
      return Club(
        id: '${row['id']}',
        name: '${row['name'] ?? ''}',
        emoji: '${row['emoji'] ?? '🎾'}',
        bg: _themeColor(row['theme_color'] as String?),
        members: (row['member_count'] as num?)?.toInt() ?? 0,
        isMember: row['is_member'] == true,
        description: '${row['description'] ?? ''}',
      );
    }).toList();
  }

  @override
  Future<List<ClubMember>> fetchMembers(String clubId, {String query = ''}) async {
    final json = await _client.get('/clubs/$clubId');
    final row = json['data'] as Map<String, dynamic>?;
    final members = (row?['members'] as List?) ?? const [];
    final ownerId = ((row?['owner'] as Map?)?['id'])?.toString();

    final q = query.trim().toLowerCase();

    return members.whereType<Map<String, dynamic>>().where((m) {
      if (q.isEmpty) return true;
      return '${m['display_name']}'.toLowerCase().contains(q);
    }).map((m) {
      final i = (m['avatar_color_index'] as num?)?.toInt() ?? 0;
      return ClubMember(
        name: '${m['display_name'] ?? ''}',
        initials: '${m['initials'] ?? ''}',
        bg: AppColors.chipPairsBg[i % AppColors.chipPairsBg.length],
        color: AppColors.chipPairsFg[i % AppColors.chipPairsFg.length],
        isOwner: ownerId != null && '${m['id']}' == ownerId,
      );
    }).toList();
  }

  @override
  Future<void> joinClub(String clubId) async =>
      throw UnimplementedError('Club join is not exposed by the API yet.');

  @override
  Future<void> leaveClub(String clubId) async =>
      throw UnimplementedError('Club leave is not exposed by the API yet.');

  @override
  Future<Club> createClub({required String name, required String description}) async =>
      throw UnimplementedError('Club creation is not exposed by the API yet.');

  Color _themeColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.surfaceAlt;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return AppColors.surfaceAlt;
    return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
  }
}
