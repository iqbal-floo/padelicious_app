import '../models/player.dart';
import 'mock_data.dart';

/// Data-access boundary for players. Swap [MockPlayerRepository] for a
/// networked implementation later without touching call sites — they only
/// depend on this abstract interface.
abstract class PlayerRepository {
  Future<List<Player>> fetchAllPlayers();
  Future<PlayerProfile?> fetchPlayerProfile(String name);
}

class MockPlayerRepository implements PlayerRepository {
  @override
  Future<List<Player>> fetchAllPlayers() async => MockData.allPlayers;

  @override
  Future<PlayerProfile?> fetchPlayerProfile(String name) async {
    final idx = MockData.allPlayers.indexWhere((p) => p.name == name);
    if (idx < 0) return null;
    final player = MockData.allPlayers[idx];
    final levelIdx = idx % MockData.reclubLevelValues.length;
    final level = '${MockData.reclubLevelValues[levelIdx]} · ${MockData.reclubLevelLabels[levelIdx]}';
    return PlayerProfile(player: player, sessions: 12 + idx * 3, level: level);
  }
}
