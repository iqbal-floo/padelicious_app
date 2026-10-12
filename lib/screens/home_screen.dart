import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_divider.dart';
import '../widgets/padel_header.dart';
import '../widgets/section_label.dart';
import 'clubs_screen.dart';
import 'players_screen.dart';
import 'profile_screen.dart';
import 'sessions_screen.dart';
import 'setup_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            PadelHeader(
              title: '🎾 Padelicious',
              subtitle: 'Hi ${appState.currentPlayerName} 👋',
              showBack: false,
              trailing: const PillBadge('Member'),
            ),
            const GradientDivider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [AppColors.navy, AppColors.navyLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 6))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: appState.currentPlayerAvatarBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                              ),
                              child: Text(
                                appState.currentPlayerInitials,
                                style: TextStyle(color: appState.currentPlayerAvatarFg, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appState.currentPlayerName,
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  const PillBadge('Member'),
                                ],
                              ),
                            ),
                            Text('›', style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.6))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('Quick actions'),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                      children: [
                        _QuickActionTile(
                          emoji: '👑',
                          title: 'Session',
                          subtitle: 'Active & past sessions',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SessionsScreen())),
                        ),
                        _QuickActionTile(
                          emoji: '🧑‍🤝‍🧑',
                          title: 'Players',
                          subtitle: 'All registered players',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PlayersScreen())),
                        ),
                        _QuickActionTile(
                          emoji: '🏸',
                          title: 'Clubs',
                          subtitle: 'Find & join clubs',
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubsScreen())),
                        ),
                        _QuickActionTile(
                          emoji: '📅',
                          title: 'Events',
                          subtitle: 'Upcoming tournaments',
                          onTap: () => appState.showToast('Events — coming soon'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('Recent activity'),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
                        ),
                        child: Row(
                          children: [
                            const Text('🥇', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sunday King of the Court', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                                  SizedBox(height: 1),
                                  Text('You placed #1 · 42 pts', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            const Text('›', style: TextStyle(fontSize: 14, color: AppColors.textFaint)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.emoji, required this.title, required this.subtitle, required this.onTap});

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
