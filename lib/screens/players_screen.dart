import 'package:flutter/material.dart';

import '../models/club.dart';
import '../models/player.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/avatar_badge.dart';
import 'player_detail_screen.dart';

const _clubFilterLimit = 30;

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _search = TextEditingController();
  final _clubQuery = TextEditingController();
  bool _clubFilterOpen = false;
  String? _selectedClubName;

  @override
  void dispose() {
    _search.dispose();
    _clubQuery.dispose();
    super.dispose();
  }

  List<Club> _matchingClubs(List<Club> allClubs, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return allClubs;
    return allClubs.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allPlayers = appState.players;
    final allClubs = appState.clubs;

    final searchQuery = _search.text.trim().toLowerCase();
    var filtered = allPlayers.where((p) => p.name.toLowerCase().contains(searchQuery)).toList();
    if (_selectedClubName != null) {
      filtered = filtered.where((p) => appState.clubsForPlayer(p.name).any((c) => c.name == _selectedClubName)).toList();
    }
    filtered.sort((a, b) => a.name.compareTo(b.name));

    final groups = <String, List<Player>>{};
    for (final p in filtered) {
      groups.putIfAbsent(p.name[0].toUpperCase(), () => []).add(p);
    }
    final letters = groups.keys.toList()..sort();

    final clubMatches = _matchingClubs(allClubs, _clubQuery.text);
    final clubMatchesLimited = clubMatches.take(_clubFilterLimit).toList();
    final clubHasMore = clubMatches.length > _clubFilterLimit;

    return AppScaffold(
      title: 'Players',
      subtitle: '${allPlayers.length} registered players',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
            decoration: const InputDecoration(hintText: '🔍 Search players'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _clubQuery,
            onTap: () {
              if (!_clubFilterOpen) setState(() => _clubFilterOpen = true);
            },
            onChanged: (_) => setState(() => _clubFilterOpen = true),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
            decoration: InputDecoration(
              hintText: 'Filter by club — type to search',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedClubName != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: AppColors.textFaint),
                      onPressed: () => setState(() {
                        _selectedClubName = null;
                        _clubFilterOpen = false;
                        _clubQuery.clear();
                      }),
                    ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
                    onPressed: () => setState(() {
                      _clubFilterOpen = !_clubFilterOpen;
                      _clubQuery.text = _clubFilterOpen ? '' : (_selectedClubName ?? '');
                    }),
                  ),
                ],
              ),
            ),
          ),
          if (_clubFilterOpen)
            Container(
              margin: const EdgeInsets.only(top: 4),
              constraints: const BoxConstraints(maxHeight: 230),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(10)),
              child: ListView(
                shrinkWrap: true,
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      _selectedClubName = null;
                      _clubFilterOpen = false;
                      _clubQuery.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceAlt))),
                      child: const Text('All clubs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                    ),
                  ),
                  for (final club in clubMatchesLimited)
                    InkWell(
                      onTap: () => setState(() {
                        _selectedClubName = club.name;
                        _clubFilterOpen = false;
                        _clubQuery.text = club.name;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surfaceAlt))),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: club.bg, shape: BoxShape.circle),
                              child: Text(club.emoji, style: const TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 9),
                            Expanded(child: Text(club.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis)),
                            Text('${club.members}', style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
                          ],
                        ),
                      ),
                    ),
                  if (clubMatches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Center(child: Text('No clubs found', style: TextStyle(fontSize: 12, color: AppColors.textFaint))),
                    ),
                  if (clubHasMore)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      color: const Color(0xFFF8FCFA),
                      alignment: Alignment.center,
                      child: Text('${clubMatches.length - _clubFilterLimit} more — keep typing to narrow', style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (letters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No players match "${_search.text}"', style: const TextStyle(color: AppColors.textFaint, fontSize: 13))),
            )
          else
            for (final letter in letters) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(letter, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textFaint)),
              ),
              for (final p in groups[letter]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _PlayerRow(player: p, clubsText: _clubsText(appState.clubsForPlayer(p.name))),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  String _clubsText(List<Club> clubs) => clubs.isEmpty ? 'No clubs' : clubs.map((c) => c.name).join(' · ');
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.clubsText});

  final Player player;
  final String clubsText;

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerDetailScreen(playerName: player.name))),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          InitialsAvatar(initials: player.initials, background: player.bg, foreground: player.color, fontSize: 12),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy)),
                const SizedBox(height: 1),
                Text(clubsText, style: const TextStyle(fontSize: 11, color: AppColors.textFaint)),
              ],
            ),
          ),
          if (player.badge != null) ...[SmallBadge(player.badge!), const SizedBox(width: 6)],
          const Text('›', style: TextStyle(fontSize: 14, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
