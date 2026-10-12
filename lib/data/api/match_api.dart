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
    String? leaderboardSort,
    String? clubId,
    List<String> playerIds = const [],
    /// Reclub imports: player id -> the list they were on at Reclub
    /// (`confirmed` / `waitlisted`). Added with source "reclub".
    Map<String, String> reclubPlayers = const {},
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
      if (leaderboardSort != null) 'leaderboard_sort': leaderboardSort,
      if (pointsTarget != null) 'points_target': pointsTarget,
      if (tennisMode != null) 'tennis_mode': tennisMode,
      if (clubId != null) 'club_id': clubId,
      if (playerIds.isNotEmpty || reclubPlayers.isNotEmpty)
        'participants': [
          for (final id in playerIds) {'player_id': id},
          for (final e in reclubPlayers.entries) {'player_id': e.key, 'source': 'reclub', 'status': e.value},
        ],
    };

    final json = await _client.post('/sessions', body: body);
    return (json['data'] as Map<String, dynamic>)['id'] as String;
  }

  /// Sessions for the Active/Past tabs, with their ids.
  Future<List<Map<String, dynamic>>> fetchSessions(String status) async {
    final json = await _client.get('/sessions', query: {'status': status});
    return ((json['data'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// One session with its roster: participant ids, names, usernames.
  Future<Map<String, dynamic>> fetchSession(String sessionId) async {
    final json = await _client.get('/sessions/$sessionId');
    return (json['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// Puts an existing player on the roster; returns the participant id.
  Future<String> addParticipant(String sessionId, String playerId) async {
    final json = await _client.post(
      '/sessions/$sessionId/participants',
      body: {'player_id': playerId},
    );
    return (json['data'] as Map<String, dynamic>)['id'] as String;
  }

  /// Host-only: set a player's status (`confirmed` / `waitlisted`) and/or
  /// replace their tags (`host`, `no_show`).
  Future<void> updateParticipant(
    String sessionId,
    String participantId, {
    String? status,
    List<String>? tags,
  }) =>
      _client.patch('/sessions/$sessionId/participants/$participantId', body: {
        if (status != null) 'status': status,
        if (tags != null) 'tags': tags,
      });

  /// Withdraws a player from the roster (their match history stays).
  Future<void> removeParticipant(String sessionId, String participantId) =>
      _client.delete('/sessions/$sessionId/participants/$participantId');

  /// The signed-in player asks to join; a host then confirms or waitlists.
  Future<void> requestToJoin(String sessionId) =>
      _client.post('/sessions/$sessionId/join');

  /// Generates the next round; returns the created match ids.
  Future<List<String>> generateRound(String sessionId) async {
    final json = await _client.post('/sessions/$sessionId/rounds');
    final data = json['data'] as Map<String, dynamic>;
    return ((data['matches'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((m) => m['id'] as String)
        .toList();
  }

  /// Enters a round by hand instead of generating it: each entry is
  /// `{court, team_a: [participantId, participantId], team_b: [...],
  /// tennis_mode?}`. Returns the created match ids.
  Future<List<String>> createRound(
    String sessionId,
    List<Map<String, dynamic>> matches, {
    int? roundNumber,
  }) async {
    final json = await _client.post('/sessions/$sessionId/rounds', body: {
      if (roundNumber != null) 'round_number': roundNumber,
      'matches': matches,
    });
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

  /// Takes a completed round back to in progress so scores can be fixed.
  Future<void> reopenRound(String roundId) =>
      _client.post('/rounds/$roundId/reopen');

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

  /// Voids every point of the match and returns it to not-started.
  Future<LiveScore> resetMatch(String matchId) async {
    final json = await _client.post('/matches/$matchId/reset');
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

  /// The order of play: one row per match in round/court order, plus the
  /// `html_url`/`pdf_url` of the printable sheet.
  Future<Map<String, dynamic>> fetchOrderOfPlay(
    String sessionId, {
    String? startTime,
    int slotMinutes = 15,
  }) async {
    final json = await _client.get(
      '/sessions/$sessionId/order-of-play',
      query: {
        if (startTime != null) 'start': startTime,
        if (startTime != null) 'slot': slotMinutes,
      },
    );
    return (json['data'] as Map<String, dynamic>?) ?? const {};
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
