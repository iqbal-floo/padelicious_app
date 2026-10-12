import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/section_label.dart';
import 'clubs_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AppScaffold(
      title: 'Profile',
      subtitle: 'Your account',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: appState.currentPlayerAvatarBg, shape: BoxShape.circle),
                  child: Text(
                    appState.currentPlayerInitials,
                    style: TextStyle(color: appState.currentPlayerAvatarFg, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.auth.fullName ?? appState.currentPlayerName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        appState.memberSinceLabel,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Expanded(child: _StatBox(value: '24', label: 'SESSIONS')),
              SizedBox(width: 10),
              Expanded(child: _StatBox(value: '68%', label: 'WIN RATE', valueColor: AppColors.greenText)),
              SizedBox(width: 10),
              Expanded(child: _StatBox(value: '#3', label: 'CLUB RANK')),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel('Account'),
          SectionCard(children: [
            SectionCardRow(child: _MenuRow(icon: '✏️', label: 'Edit profile', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())))),
            SectionCardRow(
              child: _MenuRow(icon: '🏸', label: 'My clubs', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClubsScreen()))),
            ),
            SectionCardRow(showDivider: false, child: _MenuRow(icon: '📅', label: 'My events', onTap: () => appState.showToast('Events — coming soon'))),
          ]),
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
              child: const Text('Log out', style: TextStyle(fontSize: 13, color: AppColors.textFaint, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label, this.valueColor = AppColors.navy});

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: valueColor)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textFaint, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap});

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy))),
          const Text('›', style: TextStyle(fontSize: 14, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
