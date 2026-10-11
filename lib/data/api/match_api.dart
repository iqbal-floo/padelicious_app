import '../../models/live_score.dart';
import 'api_client.dart';

/// Saving a session/match and recording scores against the backend.
class MatchApi {
  MatchApi(this._client);

  final ApiClient _client;

  // ---- session ("save match") ---------------------------------------------

  /// Creates a session with its courts and roster. Returns the session id.
  Future<String> createSession({
    required String name,
    required String matchTypeCode,
    required DateTime scheduledDate,
    required int courtCount,
    String scoringType = 'normal',
    int? pointsTarget,
    String? tennisMode,
    bool goldenPoint = true,
    String? clubId,
    List<String> playerIds = const [],
    String icon = '🎾',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'icon': icon,
      'match_type_code': matchTypeCode,
      'scheduled_date': _date(scheduledDate),
      'court_count': courtCount,
      'scoring_type': scoringType,
      'golden_point': goldenPoint,
      if (pointsTarget != null) 'points_target': pointsTarget,
      if (tennisMode != null) 'tennis_mode': tennisMode,
      if (clubId != null) 'club_id': clubId,
      if (playerIds.isNotEmpty)
        'participants': playerIds.map((id) => {'player_id': id}).toList(),
    };

    final json = await _client.post('/sessions', body: body);
    return (json['data'] as Map<String, dynamic>)['id'] as String;
  }

  /// Generates the next round; returns the created match ids.
  Future<List<String>> generateRound(String sessionId) async {
    final json = await _client.post('/sessions/$sessionId/rounds');
    final data = json['data'] as Map<String, dynamic>;
    return ((data['matches'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((m) => m['id'] as String)
        .toList();
  }

  Future<void> completeSession(String sessionId) =>
      _client.post('/sessions/$sessionId/complete');

  Future<void> completeRound(String roundId) =>
      _client.post('/rounds/$roundId/complete');

  // ---- scoring -------------------------------------------------------------

  /// Records one point for [team] ('a' or 'b') and returns the new score.
  Future<LiveScore> scorePoint(String matchId, String team) async {
    final json = await _client.post(
      '/matches/$matchId/points',
      body: {'team': team},
    );
    return _score(matchId, json);
  }

  /// Undoes the last point and returns the restored score.
  Future<LiveScore> undoPoint(String matchId) async {
    final json = await _client.delete('/matches/$matchId/points');
    return _score(matchId, json);
  }

  /// One-shot current score. Public endpoint — no token required.
  Future<LiveScore> fetchLiveScore(String matchId) async {
    final json = await _client.get('/live/matches/$matchId');
    return LiveScore.fromJson(json['data'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchRounds(String sessionId) async {
    final json = await _client.get('/sessions/$sessionId/rounds');
    return ((json['data'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard(String sessionId) async {
    final json = await _client.get('/sessions/$sessionId/leaderboard');
    return ((json['data'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// The score endpoints return a match resource, not the live snapshot
  /// shape, so normalise it into [LiveScore].
  LiveScore _score(String matchId, Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return LiveScore(
      matchId: matchId,
      status: (d['status'] as String?) ?? 'live',
      gamesA: (d['games_a'] as num?)?.toInt() ?? 0,
      gamesB: (d['games_b'] as num?)?.toInt() ?? 0,
      pointsA: '${d['points_a'] ?? '0'}',
      pointsB: '${d['points_b'] ?? '0'}',
      servingTeam: d['serving_team'] as String?,
      winnerTeam: d['winner_team'] as String?,
      teams: ((d['teams'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((t) => LiveTeam(
                side: (t['side'] as String?) ?? 'a',
                playerNames: ((t['players'] as List?) ?? const [])
                    .whereType<Map>()
                    .map((p) => '${p['display_name'] ?? ''}')
                    .where((n) => n.isNotEmpty)
                    .toList(),
              ))
          .toList(),
    );
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
