import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/match_config.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/order_of_play_button.dart';
import '../widgets/padel_header.dart';
import 'leaderboard_screen.dart';
import 'score_screen.dart';

class KotcScreen extends StatelessWidget {
  const KotcScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final matchTypeLabel = matchTypeLabels[appState.matchType] ?? 'King of the Court';
    final finished = appState.gamesA >= 6 || appState.gamesB >= 6;

    return AppScaffold(
      title: '🎾 Live session',
      subtitle: 'PADELICIOUS · $matchTypeLabel',
      trailing: PillBadge('👑 $matchTypeLabel'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _CourtCard(
            onTapCard: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreScreen())),
            badgeText: finished ? 'COURT 1 · FINISH' : 'COURT 1 · FINISHED',
            badgeBg: finished ? const Color(0xFFDCEEFF) : AppColors.tealSurface,
            badgeFg: finished ? const Color(0xFF1A5AAA) : AppColors.tealDark,
            topGradient: const [AppColors.teal, AppColors.green],
            leftNames: const ['Iqbal', 'Rafi'],
            rightNames: const ['Budi', 'Hendra'],
            score: '${appState.gamesA}–${appState.gamesB}',
            onScore: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreScreen())),
            onWatch: () => appState.showToast('Watch scoring active ⌚'),
            onShare: () => appState.showToast('Link copied!'),
          ),
          const SizedBox(height: 10),
          _CourtCard(
            badgeText: 'COURT 2 · LIVE',
            badgeBg: const Color(0x268DC63F),
            badgeFg: const Color(0xFF5A8A1A),
            topGradient: const [AppColors.greenText, AppColors.green],
            leftNames: const ['Andi', 'Dito'],
            rightNames: const ['Yoga', 'Febri'],
            score: '2–6',
            onScore: () => appState.showToast('Court 2 scoring'),
            onWatch: () => appState.showToast('No watch on Court 2'),
            onShare: () => appState.showToast('Court 2 link copied!'),
          ),
          if (appState.activeSessionId != null) ...[
            const SizedBox(height: 12),
            OrderOfPlayButton(sessionId: appState.activeSessionId!),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('WAITING QUEUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: AppColors.textFaint)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.tealSurface, borderRadius: BorderRadius.circular(20)),
                child: Text('${MockData.queueNames.length} waiting', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < MockData.queueNames.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: i == 0 ? AppColors.selectedTile : Colors.white,
                border: Border.all(color: i == 0 ? AppColors.green : AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: i == 0 ? AppColors.green : AppColors.surfaceAlt, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: i == 0 ? AppColors.navy : AppColors.textMuted)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(MockData.queueNames[i], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy))),
                ],
              ),
            ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.border, height: 1)),
          PrimaryButton(label: '🔀 Generate next session', onPressed: () => appState.showToast('New matchups generated 🔀')),
          const SizedBox(height: 8),
          SecondaryButton(
            label: '🏆 View leaderboard',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
          const SizedBox(height: 8),
          SecondaryButton(label: '🔗 Share session', onPressed: () => appState.showToast('Session link copied!')),
        ],
      ),
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({
    required this.badgeText,
    required this.badgeBg,
    required this.badgeFg,
    required this.topGradient,
    required this.leftNames,
    required this.rightNames,
    required this.score,
    required this.onScore,
    required this.onWatch,
    required this.onShare,
    this.onTapCard,
  });

  final String badgeText;
  final Color badgeBg;
  final Color badgeFg;
  final List<Color> topGradient;
  final List<String> leftNames;
  final List<String> rightNames;
  final String score;
  final VoidCallback onScore;
  final VoidCallback onWatch;
  final VoidCallback onShare;
  final VoidCallback? onTapCard;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: topGradient))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: badgeFg, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(badgeText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: badgeFg)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final n in leftNames) _PlayerChip(name: n)],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          Text(score, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1, color: AppColors.navy)),
                          const Text('games', style: TextStyle(fontSize: 10, color: AppColors.textFaint, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [for (final n in rightNames) _PlayerChip(name: n, alignEnd: true)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MiniAction(label: '📊 Score', onTap: onScore)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniAction(label: '⌚ Watch', onTap: onWatch)),
                    const SizedBox(width: 8),
                    Expanded(child: _MiniAction(label: '🔗 Share', onTap: onShare)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTapCard == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(14), onTap: onTapCard, child: card);
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.name, this.alignEnd = false});

  final String name;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => showSwitchPlayerSheet(context, name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: AppColors.surfaceAlt, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
              const SizedBox(width: 6),
              const Text('⇄', style: TextStyle(fontSize: 12, color: AppColors.teal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
      ),
    );
  }
}

void showSwitchPlayerSheet(BuildContext context, String playerName) {
  final appState = AppStateScope.read(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const Text('Switch player', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 2),
            Text('Replace $playerName with someone from the queue', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final candidate in MockData.queueNames)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          appState.showToast('$candidate swapped in for $playerName 🔄');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Expanded(child: Text(candidate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy))),
                              const Text('Select', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: () => Navigator.of(sheetContext).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textFaint)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
