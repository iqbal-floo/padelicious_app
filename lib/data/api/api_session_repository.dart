import '../../models/session_summary.dart';
import '../session_repository.dart';
import 'api_client.dart';

/// Backend-backed [SessionRepository].
class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this._client);

  final ApiClient _client;

  /// Session ids in the order last returned, so a tapped row can be opened.
  final List<String> lastIds = [];

  @override
  Future<List<SessionSummary>> fetchActiveSessions() => _fetch('active');

  @override
  Future<List<SessionSummary>> fetchPastSessions() => _fetch('past');

  Future<List<SessionSummary>> _fetch(String status) async {
    final json = await _client.get('/sessions', query: {'status': status});
    final rows = (json['data'] as List?) ?? const [];

    lastIds
      ..clear()
      ..addAll(rows
          .whereType<Map<String, dynamic>>()
          .map((r) => '${r['id']}'));

    return rows.whereType<Map<String, dynamic>>().map((row) {
      final matchType = (row['match_type'] as Map?) ?? const {};
      final club = (row['club'] as Map?) ?? const {};
      final count = (row['participant_count'] as num?)?.toInt() ?? 0;

      // "Americano · 8 players · Padelicious Jakarta"
      final detail = [
        if (matchType['label'] != null) '${matchType['label']}',
        '$count players',
        if (club['name'] != null) '${club['name']}',
      ].join(' · ');

      return SessionSummary(
        icon: '${row['icon'] ?? '🎾'}',
        name: '${row['name'] ?? ''}',
        detail: detail,
      );
    }).toList();
  }
}
