import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/section_label.dart';

const _membersPerPage = 24;

class ClubDetailScreen extends StatefulWidget {
  const ClubDetailScreen({super.key, required this.clubId});

  final String clubId;

  @override
  State<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends State<ClubDetailScreen> {
  final _search = TextEditingController();
  int _page = 0;
  List<ClubMember> _lastMembers = const [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final club = appState.clubById(widget.clubId);

    return AppScaffold(
      title: club.name,
      subtitle: 'Club details',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: club.bg, shape: BoxShape.circle),
                  child: Text(club.emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 10),
                Text(club.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text('${club.members} members', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                if (club.isMember)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.tealSurface, borderRadius: BorderRadius.circular(20)),
                        child: const Text('✓ Joined', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => appState.leaveClub(club.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: Color(0xFFF0C9C4), width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Leave club', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () => appState.joinClub(club.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('Join club', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('About'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Text(club.description, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
          ),
          const SizedBox(height: 24),
          SectionLabel('Members (${club.members})'),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() => _page = 0),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
            decoration: const InputDecoration(hintText: '🔍 Search members', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<ClubMember>>(
            future: appState.fetchClubMembers(club.id, query: _search.text),
            builder: (context, snapshot) {
              final members = snapshot.data ?? _lastMembers;
              if (snapshot.hasData) _lastMembers = snapshot.data!;
              final totalPages = members.isEmpty ? 1 : (members.length / _membersPerPage).ceil();
              final page = _page < 0 ? 0 : (_page > totalPages - 1 ? totalPages - 1 : _page);
              final pageMembers = members.skip(page * _membersPerPage).take(_membersPerPage).toList();

              return Column(
                children: [
                  if (members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('No members match "${_search.text}"', style: const TextStyle(fontSize: 12, color: AppColors.textFaint)),
                    )
                  else
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                      children: [for (final m in pageMembers) _MemberTile(member: m)],
                    ),
                  if (members.length > _membersPerPage)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PageButton(label: '‹ Prev', enabled: page > 0, onTap: () => setState(() => _page = page - 1)),
                          const SizedBox(width: 10),
                          Text('Page ${page + 1} of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                          const SizedBox(width: 10),
                          _PageButton(label: 'Next ›', enabled: page < totalPages - 1, onTap: () => setState(() => _page = page + 1)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionLabel('Upcoming sessions'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            alignment: Alignment.center,
            child: const Text('No sessions scheduled yet', style: TextStyle(fontSize: 13, color: AppColors.textFaint)),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final ClubMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: member.bg, shape: BoxShape.circle),
              child: Text(member.initials, style: TextStyle(color: member.color, fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            if (member.isOwner)
              Positioned(
                bottom: -3,
                right: -3,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                  child: const Text('👑', style: TextStyle(fontSize: 9)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy)),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
