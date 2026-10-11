import 'package:flutter/material.dart';

import '../models/player.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/section_label.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.playerName});

  final String playerName;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AppScaffold(
      title: playerName,
      subtitle: 'Player profile',
      body: FutureBuilder<PlayerProfile?>(
        future: appState.playerProfile(playerName),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()));
          }
          final profile = snapshot.data!;
          final clubs = appState.clubsForPlayer(playerName);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    InitialsAvatar(initials: profile.player.initials, background: profile.player.bg, foreground: profile.player.color, size: 72, fontSize: 22),
                    const SizedBox(height: 10),
                    Text(profile.player.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.navy)),
                    if (profile.player.badge != null) ...[
                      const SizedBox(height: 6),
                      SmallBadge(profile.player.badge!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatBox(value: '${profile.sessions}', label: 'SESSIONS'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _StatBox(value: profile.level, label: 'SELF-ASSESSED LEVEL', valueColor: AppColors.greenText),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Clubs'),
              if (clubs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No clubs yet', style: TextStyle(fontSize: 13, color: AppColors.textFaint)),
                )
              else
                for (final c in clubs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: SimpleCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                            child: Text(c.emoji, style: const TextStyle(fontSize: 15)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy))),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
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
