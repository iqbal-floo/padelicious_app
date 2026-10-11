import '../models/player.dart';
import 'mock_data.dart';

/// Stand-in for the real Reclub integration: given a match code, returns the
/// roster (with photos/badges) that should populate the Setup screen.
abstract class ReclubImportService {
  Future<List<Player>> importByMatchCode(String matchCode);
}

class MockReclubImportService implements ReclubImportService {
  @override
  Future<List<Player>> importByMatchCode(String matchCode) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return MockData.reclubImportPlayers;
  }
}
