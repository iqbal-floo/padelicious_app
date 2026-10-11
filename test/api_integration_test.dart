// End-to-end test of the Dart API client against a RUNNING backend.
// Not a unit test: start the Laravel server first, then
//   flutter test test/api_integration_test.dart --dart-define=API=http://127.0.0.1:8150
import 'package:flutter_test/flutter_test.dart';
import 'package:padelicious/data/api/api_client.dart';
import 'package:padelicious/data/api/api_exception.dart';
import 'package:padelicious/data/api/auth_api.dart';
import 'package:padelicious/data/api/match_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('API client works end to end against the backend', () async {
    SharedPreferences.setMockInitialValues({});

  const base = String.fromEnvironment('API', defaultValue: 'http://127.0.0.1:8150');
  final client = ApiClient(baseUrl: '$base/api/v1');
  final auth = AuthApi(client);
  final matches = MatchApi(client);
  var failures = 0;

  Future<void> step(String label, Future<void> Function() body) async {
    try {
      await body();
      print('  PASS  $label');
    } catch (e) {
      failures++;
      print('  FAIL  $label -> $e');
    }
  }

  print('Backend: $base');

  await step('unauthenticated request is rejected', () async {
    await client.clearToken();
    try {
      await client.get('/players');
      throw Exception('expected rejection');
    } on ApiException {
      // expected
    }
  });

  await step('login stores a token', () async {
    final user = await auth.login(
      email: 'iqbalpermana09@gmail.com',
      password: 'password',
      deviceName: 'dart-smoke',
    );
    if (user['full_name'] == null) throw Exception('no user returned');
    if (!await client.hasToken) throw Exception('token not stored');
  });

  await step('bad credentials raise a validation error', () async {
    final fresh = ApiClient(baseUrl: '$base/api/v1');
    await fresh.clearToken();
    try {
      await AuthApi(fresh).login(email: 'iqbalpermana09@gmail.com', password: 'wrong');
      throw Exception('expected failure');
    } on ApiException catch (e) {
      if (!e.isValidation) throw Exception('expected 422, got ${e.statusCode}');
    }
    // Restore the good token for later steps.
    await AuthApi(client).login(
      email: 'iqbalpermana09@gmail.com', password: 'password');
  });

  String? sessionId;
  await step('create a session (save match)', () async {
    final players = await client.get('/players', query: {'per_page': 8});
    final ids = ((players['data'] as List?) ?? const [])
        .map((p) => (p as Map)['id'] as String)
        .take(4)
        .toList();

    sessionId = await matches.createSession(
      name: 'Dart Smoke Session',
      matchTypeCode: 'americano',
      scheduledDate: DateTime.now(),
      courtCount: 1,
      pointsTarget: 24,
      playerIds: ids,
    );
    if (sessionId == null) throw Exception('no session id');
  });

  String? matchId;
  await step('generate a round', () async {
    final ids = await matches.generateRound(sessionId!);
    if (ids.isEmpty) throw Exception('no matches created');
    matchId = ids.first;
  });

  await step('score a point and read the new score', () async {
    final score = await matches.scorePoint(matchId!, 'a');
    if (score.pointsA != '15') throw Exception('expected 15, got ${score.pointsA}');
  });

  await step('score three more to win a game', () async {
    for (var i = 0; i < 3; i++) {
      await matches.scorePoint(matchId!, 'a');
    }
    final score = await matches.fetchLiveScore(matchId!);
    if (score.gamesA != 1) throw Exception('expected 1 game, got ${score.gamesA}');
    if (score.pointsA != '0') throw Exception('points should reset');
  });

  await step('undo restores the previous score', () async {
    final before = await matches.fetchLiveScore(matchId!);
    await matches.undoPoint(matchId!);
    final after = await matches.fetchLiveScore(matchId!);
    if (after.gamesA != before.gamesA - 1) {
      throw Exception('undo should give the game back');
    }
    if (after.pointsA != '40') throw Exception('expected 40, got ${after.pointsA}');
  });

  await step('public live score needs no token', () async {
    final anon = ApiClient(baseUrl: '$base/api/v1');
    await anon.clearToken();
    final score = await MatchApi(anon).fetchLiveScore(matchId!);
    if (score.matchId != matchId) throw Exception('wrong match');
    if (score.teams.length != 2) throw Exception('expected 2 teams');
    if (score.teams.first.playerNames.length != 2) {
      throw Exception('expected 2 players per team');
    }
  });

  await step('leaderboard reflects the finished game', () async {
    final rows = await matches.fetchLeaderboard(sessionId!);
    if (rows.isEmpty) throw Exception('empty leaderboard');
  });

  await step('conflict surfaces as isConflict', () async {
    // Undo everything, then one more should 409.
    while (true) {
      try {
        await matches.undoPoint(matchId!);
      } on ApiException catch (e) {
        if (e.isConflict) return;
        throw Exception('expected 409, got ${e.statusCode}');
      }
    }
  });

  await step('logout clears the token', () async {
    await auth.logout();
    if (await client.hasToken) throw Exception('token still present');
  });

  
  
    expect(failures, 0, reason: '$failures step(s) failed');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
