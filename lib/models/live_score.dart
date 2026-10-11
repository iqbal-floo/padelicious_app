/// Score state of one match, as returned by the backend.
class LiveScore {
  final String matchId;
  final String status;
  final int gamesA;
  final int gamesB;
  final String pointsA;
  final String pointsB;
  final String? servingTeam;
  final String? winnerTeam;
  final String? sessionName;
  final String? courtLabel;
  final int? roundNumber;
  final List<LiveTeam> teams;

  const LiveScore({
    required this.matchId,
    required this.status,
    required this.gamesA,
    required this.gamesB,
    required this.pointsA,
    required this.pointsB,
    this.servingTeam,
    this.winnerTeam,
    this.sessionName,
    this.courtLabel,
    this.roundNumber,
    this.teams = const [],
  });

  bool get isLive => status == 'live';

  bool get isFinished => status == 'finished';

  factory LiveScore.fromJson(Map<String, dynamic> json) {
    final games = (json['games'] as Map?) ?? const {};
    final points = (json['points'] as Map?) ?? const {};
    final session = (json['session'] as Map?) ?? const {};
    final court = (json['court'] as Map?) ?? const {};

    return LiveScore(
      matchId: json['match_id'] as String,
      status: (json['status'] as String?) ?? 'scheduled',
      gamesA: (games['a'] as num?)?.toInt() ?? 0,
      gamesB: (games['b'] as num?)?.toInt() ?? 0,
      pointsA: '${points['a'] ?? '0'}',
      pointsB: '${points['b'] ?? '0'}',
      servingTeam: json['serving_team'] as String?,
      winnerTeam: json['winner_team'] as String?,
      sessionName: session['name'] as String?,
      courtLabel: court['label'] as String?,
      roundNumber: (json['round_number'] as num?)?.toInt(),
      teams: ((json['teams'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LiveTeam.fromJson)
          .toList(),
    );
  }
}

class LiveTeam {
  final String side;
  final List<String> playerNames;

  const LiveTeam({required this.side, required this.playerNames});

  String get label => playerNames.join(' / ');

  factory LiveTeam.fromJson(Map<String, dynamic> json) => LiveTeam(
        side: (json['side'] as String?) ?? 'a',
        playerNames: ((json['players'] as List?) ?? const [])
            .whereType<Map>()
            .map((p) => '${p['display_name'] ?? ''}')
            .where((n) => n.isNotEmpty)
            .toList(),
      );
}
