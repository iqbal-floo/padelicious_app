import 'package:flutter/material.dart';

import '../models/club.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/tab_toggle.dart';
import 'club_detail_screen.dart';
import 'create_club_screen.dart';

class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  final _search = TextEditingController();
  int _tab = 0;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final query = _search.text.trim().toLowerCase();
    var clubs = appState.clubs.where((c) => c.name.toLowerCase().contains(query)).toList();
    if (_tab == 1) clubs = clubs.where((c) => c.isMember).toList();

    return AppScaffold(
      title: 'Clubs',
      subtitle: 'Find & discover',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
            decoration: const InputDecoration(hintText: '🔍 Search clubs'),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: '+ Create a club',
            compact: true,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateClubScreen())),
          ),
          const SizedBox(height: 14),
          TabToggle(labels: const ['All clubs', 'My clubs'], selectedIndex: _tab, onSelect: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          if (clubs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No clubs match "${_search.text}"', style: const TextStyle(color: AppColors.textFaint, fontSize: 13))),
            )
          else
            for (final club in clubs)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: _ClubRow(club: club)),
        ],
      ),
    );
  }
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.read(context);
    return SimpleCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id))),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: club.bg, shape: BoxShape.circle),
            child: Text(club.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(club.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 1),
                Text('${club.members} members', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (club.isMember)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.tealSurface, borderRadius: BorderRadius.circular(8)),
              child: const Text('✓ Joined', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
            )
          else
            SizedBox(
              height: 26,
              child: ElevatedButton(
                onPressed: () => appState.joinClub(club.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Join', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
