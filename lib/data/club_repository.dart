import '../models/club.dart';
import '../models/player.dart';
import '../theme/app_colors.dart';
import 'mock_data.dart';

abstract class ClubRepository {
  Future<List<Club>> fetchClubs();
  Future<void> joinClub(String clubId);
  Future<void> leaveClub(String clubId);
  Future<Club> createClub({required String name, required String description});
  Future<List<ClubMember>> fetchMembers(String clubId, {String query = ''});
}

class MockClubRepository implements ClubRepository {
  final List<Club> _clubs = MockData.seedClubs();
  int _createdCount = 0;

  @override
  Future<List<Club>> fetchClubs() async => List.unmodifiable(_clubs);

  @override
  Future<void> joinClub(String clubId) async {
    final club = _clubs.firstWhere((c) => c.id == clubId);
    club.isMember = true;
  }

  @override
  Future<void> leaveClub(String clubId) async {
    final club = _clubs.firstWhere((c) => c.id == clubId);
    club.isMember = false;
  }

  @override
  Future<Club> createClub({required String name, required String description}) async {
    _createdCount++;
    final club = Club(
      id: 'custom-$_createdCount',
      name: name,
      emoji: '🎾',
      bg: AppColors.surfaceAlt,
      members: 1,
      isMember: true,
      description: description.isEmpty ? 'No description yet.' : description,
    );
    _clubs.insert(0, club);
    return club;
  }

  @override
  Future<List<ClubMember>> fetchMembers(String clubId, {String query = ''}) async {
    final club = _clubs.firstWhere((c) => c.id == clubId);
    final q = query.trim().toLowerCase();
    final pool = MockData.memberFirstNames;
    final colorsBg = AppColors.chipPairsBg;
    final colorsFg = AppColors.chipPairsFg;
    final members = <ClubMember>[];
    for (var i = 0; i < club.members; i++) {
      final first = pool[i % pool.length];
      final suffix = i ~/ pool.length;
      final name = suffix > 0 ? '$first ${suffix + 1}' : first;
      members.add(ClubMember(
        name: name,
        initials: first.substring(0, 2).toUpperCase(),
        bg: colorsBg[i % colorsBg.length],
        color: colorsFg[i % colorsFg.length],
        isOwner: i == 0,
      ));
    }
    if (q.isEmpty) return members;
    return members.where((m) => m.name.toLowerCase().contains(q)).toList();
  }
}
