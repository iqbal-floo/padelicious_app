import 'package:flutter/material.dart';

import '../data/club_repository.dart';
import '../data/player_repository.dart';
import '../data/reclub_import_service.dart';
import '../data/session_repository.dart';
import '../models/club.dart';
import '../models/player.dart';
import '../models/session_summary.dart';
import 'auth_controller.dart';

enum Team { a, b }

enum ImportStatus { idle, loading, success }

class _ScoreSnapshot {
  final int gamesA;
  final int gamesB;
  final String pointsA;
  final String pointsB;
  final Team serving;

  const _ScoreSnapshot({
    required this.gamesA,
    required this.gamesB,
    required this.pointsA,
    required this.pointsB,
    required this.serving,
  });
}

/// Single source of truth for data that needs to survive across screens:
/// the club/player/session catalogs (backed by [ClubRepository] etc.), the
/// in-progress Setup form, and the live scoreboard. Purely per-screen UI
/// state (search text, open tabs, pagination) lives in each screen's own
/// State instead of here.
class AppState extends ChangeNotifier {
  AppState({
    PlayerRepository? playerRepository,
    ClubRepository? clubRepository,
    SessionRepository? sessionRepository,
    ReclubImportService? reclubImportService,
    GlobalKey<ScaffoldMessengerState>? messengerKey,
    AuthController? authController,
  })  : auth = authController ?? AuthController(),
        playerRepository = playerRepository ?? MockPlayerRepository(),
        clubRepository = clubRepository ?? MockClubRepository(),
        sessionRepository = sessionRepository ?? MockSessionRepository(),
        reclubImportService = reclubImportService ?? MockReclubImportService(),
        _messengerKey = messengerKey;

  /// Sign-in, registration and sign-out against the backend.
  final AuthController auth;

  final PlayerRepository playerRepository;
  final ClubRepository clubRepository;
  final SessionRepository sessionRepository;
  final ReclubImportService reclubImportService;
  final GlobalKey<ScaffoldMessengerState>? _messengerKey;

  static const String currentPlayerName = 'Iqbal';

  bool _loaded = false;
  bool get isLoaded => _loaded;

  List<Player> _players = [];
  List<Player> get players => _players;

  List<Club> _clubs = [];
  List<Club> get clubs => _clubs;

  List<SessionSummary> activeSessions = [];
  List<SessionSummary> pastSessions = [];

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await Future.wait([_refreshPlayers(), _refreshClubs(), _refreshSessions()]);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _refreshPlayers() async {
    _players = await playerRepository.fetchAllPlayers();
  }

  Future<void> _refreshClubs() async {
    _clubs = await clubRepository.fetchClubs();
  }

  Future<void> _refreshSessions() async {
    activeSessions = await sessionRepository.fetchActiveSessions();
    pastSessions = await sessionRepository.fetchPastSessions();
  }

  void showToast(String message) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  // ---- Clubs -------------------------------------------------------------

  Club clubById(String id) => _clubs.firstWhere((c) => c.id == id);

  Future<void> joinClub(String clubId) async {
    await clubRepository.joinClub(clubId);
    await _refreshClubs();
    notifyListeners();
    showToast('Joined ${clubById(clubId).name}! 🎉');
  }

  Future<void> leaveClub(String clubId) async {
    final name = clubById(clubId).name;
    await clubRepository.leaveClub(clubId);
    await _refreshClubs();
    notifyListeners();
    showToast('Left $name');
  }

  Future<Club> createClub({required String name, required String description}) async {
    final club = await clubRepository.createClub(name: name, description: description);
    await _refreshClubs();
    notifyListeners();
    showToast('Club created! 🎉');
    return club;
  }

  Future<List<ClubMember>> fetchClubMembers(String clubId, {String query = ''}) {
    return clubRepository.fetchMembers(clubId, query: query);
  }

  /// Clubs a player belongs to. The original prototype has no real
  /// membership graph for individual players — it derives a stable-looking
  /// association from each player's index, which we mirror here.
  List<Club> clubsForPlayer(String name) {
    final idx = _players.indexWhere((p) => p.name == name);
    if (idx < 0 || _clubs.isEmpty) return const [];
    return [
      for (var ci = 0; ci < _clubs.length; ci++)
        if ((idx + ci) % 3 == 0) _clubs[ci],
    ];
  }

  Future<PlayerProfile?> playerProfile(String name) => playerRepository.fetchPlayerProfile(name);

  // ---- Setup / new session form -------------------------------------------

  int courts = 2;
  String scoringType = 'normal';
  String normalTarget = '21';
  String tennisMode = 'race5';
  String matchName = '';
  DateTime matchDate = DateTime.now();
  String matchType = 'americano';
  String sortBy = 'points';
  bool golden = true;
  String matchCode = '';
  ImportStatus importStatus = ImportStatus.idle;
  String? importError;
  List<Player> setupPlayers = const [];

  void updateSetup({
    int? courts,
    String? scoringType,
    String? normalTarget,
    String? tennisMode,
    String? matchName,
    DateTime? matchDate,
    String? matchType,
    String? sortBy,
    bool? golden,
    String? matchCode,
  }) {
    if (courts != null) this.courts = courts < 1 ? 1 : (courts > 4 ? 4 : courts);
    if (scoringType != null) this.scoringType = scoringType;
    if (normalTarget != null) this.normalTarget = normalTarget;
    if (tennisMode != null) this.tennisMode = tennisMode;
    if (matchName != null) this.matchName = matchName;
    if (matchDate != null) this.matchDate = matchDate;
    if (matchType != null) this.matchType = matchType;
    if (sortBy != null) this.sortBy = sortBy;
    if (golden != null) this.golden = golden;
    if (matchCode != null) {
      this.matchCode = matchCode;
      importError = null;
    }
    notifyListeners();
  }

  Future<void> fetchReclubImport() async {
    if (matchCode.trim().isEmpty) {
      importError = 'Enter a match code';
      notifyListeners();
      return;
    }
    importStatus = ImportStatus.loading;
    importError = null;
    notifyListeners();
    final imported = await reclubImportService.importByMatchCode(matchCode);
    setupPlayers = imported;
    importStatus = ImportStatus.success;
    notifyListeners();
    showToast('${imported.length} players imported from Reclub 🎾');
  }

  // Setup screen starts with the default 4-player roster.
  void resetSetupPlayersIfEmpty(List<Player> defaults) {
    if (setupPlayers.isEmpty) setupPlayers = defaults;
  }

  // ---- Live scoreboard -----------------------------------------------------

  static const List<String> _pointSeq = ['0', '15', '30', '40'];

  int gamesA = 5;
  int gamesB = 3;
  String pointsA = '40';
  String pointsB = '30';
  Team serving = Team.a;
  Team? flashTeam;
  final List<_ScoreSnapshot> _history = [];

  bool get aLeads => gamesA >= gamesB;

  void scorePoint(Team team) {
    _history.add(_ScoreSnapshot(gamesA: gamesA, gamesB: gamesB, pointsA: pointsA, pointsB: pointsB, serving: serving));
    final myPts = team == Team.a ? pointsA : pointsB;
    final oppPts = team == Team.a ? pointsB : pointsA;

    void winGame() {
      if (team == Team.a) {
        gamesA++;
      } else {
        gamesB++;
      }
      pointsA = '0';
      pointsB = '0';
      serving = serving == Team.a ? Team.b : Team.a;
      if (gamesA >= 6 || gamesB >= 6) {
        showToast(team == Team.a ? 'Iqbal / Rafi win the set! 🎉' : 'Budi / Hendra win the set! 🎉');
      }
    }

    if (myPts == '40' && oppPts == '40') {
      if (golden) {
        winGame();
      } else {
        if (team == Team.a) {
          pointsA = 'GP';
        } else {
          pointsB = 'GP';
        }
      }
    } else if (myPts == 'GP' || myPts == '40') {
      winGame();
    } else {
      final idx = _pointSeq.indexOf(myPts) + 1;
      if (team == Team.a) {
        pointsA = _pointSeq[idx];
      } else {
        pointsB = _pointSeq[idx];
      }
    }

    flashTeam = team;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 500), () {
      flashTeam = null;
      notifyListeners();
    });
  }

  void undoPoint() {
    if (_history.isEmpty) {
      showToast('Nothing to undo');
      return;
    }
    final prev = _history.removeLast();
    gamesA = prev.gamesA;
    gamesB = prev.gamesB;
    pointsA = prev.pointsA;
    pointsB = prev.pointsB;
    serving = prev.serving;
    notifyListeners();
    showToast('Point removed ↩');
  }

  void finishGame() {
    showToast('Game over — rotating teams 🔄');
  }
}
