import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/padel_header.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final aLeads = appState.aLeads;

    return AppScaffold(
      title: 'Court 1',
      subtitle: 'GAME 5 · SET 2',
      trailing: const PillBadge('Live', background: AppColors.teal, foreground: Colors.white),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.tealSurface,
              border: Border.all(color: AppColors.teal.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                _PulseDot(),
                SizedBox(width: 8),
                Text('⌚ Watch connected — tap wrist to score', style: TextStyle(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('COURT 1 · SET 2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.teal, letterSpacing: 0.8)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(20)),
                          child: const Text('S1: 6–3', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.navy)),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text('S2: live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.6))),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 10), color: Colors.white.withOpacity(0.1)),
                _ScoreRow(
                  name: 'Iqbal / Rafi',
                  gamesText: '${appState.gamesA} games won',
                  points: appState.pointsA,
                  games: appState.gamesA,
                  serving: appState.serving == Team.a,
                  leading: aLeads,
                  flash: appState.flashTeam == Team.a,
                ),
                _ScoreRow(
                  name: 'Budi / Hendra',
                  gamesText: '${appState.gamesB} games won',
                  points: appState.pointsB,
                  games: appState.gamesB,
                  serving: appState.serving == Team.b,
                  leading: !aLeads,
                  flash: appState.flashTeam == Team.b,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(child: _PointButton(teamLabel: 'Iqbal / Rafi', onTap: () => appState.scorePoint(Team.a))),
              const SizedBox(width: 10),
              Expanded(child: _PointButton(teamLabel: 'Budi / Hendra', onTap: () => appState.scorePoint(Team.b))),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: appState.undoPoint,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('↩ Undo last point', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.border, height: 1)),
          SecondaryButton(label: '← Back to queue', onPressed: () => Navigator.of(context).pop()),
          const SizedBox(height: 10),
          _EndGameButton(),
        ],
      ),
    );
  }
}

class _EndGameButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.read(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          appState.finishGame();
          Future.delayed(const Duration(milliseconds: 900), () {
            if (context.mounted) Navigator.of(context).pop();
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text('End game → rotate', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.name,
    required this.gamesText,
    required this.points,
    required this.games,
    required this.serving,
    required this.leading,
    required this.flash,
  });

  final String name;
  final String gamesText;
  final String points;
  final int games;
  final bool serving;
  final bool leading;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: flash ? AppColors.green.withOpacity(0.25) : (leading ? AppColors.green.withOpacity(0.10) : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: serving ? AppColors.green : Colors.transparent,
              boxShadow: serving ? [BoxShadow(color: AppColors.green.withOpacity(0.6), blurRadius: 6)] : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 1),
                Text(gamesText, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
              ],
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(points, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.75))),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '$games',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1, color: leading ? AppColors.green : Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointButton extends StatelessWidget {
  const _PointButton({required this.teamLabel, required this.onTap});

  final String teamLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            const Text('Point for', style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
            const SizedBox(height: 4),
            Text(teamLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
            const Text('+1', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.greenText, height: 1.1)),
          ],
        ),
      ),
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) {
    return Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle));
  }
}
