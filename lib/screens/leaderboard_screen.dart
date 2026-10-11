import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/padel_header.dart';

class _LeaderboardEntry {
  final String name;
  final String initials;
  final Color bg;
  final Color fg;
  final int points;
  final String record;
  final bool isYou;

  const _LeaderboardEntry({
    required this.name,
    required this.initials,
    required this.bg,
    required this.fg,
    required this.points,
    required this.record,
    this.isYou = false,
  });
}

// Static session results, matching the design's demo leaderboard (this
// session's scoreboard doesn't yet feed a real standings computation).
const _standings = [
  _LeaderboardEntry(name: 'Iqbal', initials: 'IQ', bg: AppColors.avatarBg, fg: AppColors.avatarFg, points: 42, record: '8W · 2L · 83% WR', isYou: true),
  _LeaderboardEntry(name: 'Rafi', initials: 'RF', bg: Color(0xFFD4F5E4), fg: Color(0xFF1A7A44), points: 38, record: '7W · 3L · 70% WR'),
  _LeaderboardEntry(name: 'Budi', initials: 'BD', bg: Color(0xFFFFF0DC), fg: Color(0xFF8A5500), points: 34, record: '6W · 4L · 60% WR'),
  _LeaderboardEntry(name: 'Hendra', initials: 'HN', bg: Color(0xFFEDE0FF), fg: Color(0xFF5A2AAA), points: 30, record: '5W · 5L · 50% WR'),
];

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AppScaffold(
      title: '🏆 Leaderboard',
      subtitle: 'PADELICIOUS · Session results',
      trailing: const PillBadge('Final'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const _Podium(),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.border, height: 1)),
          for (var i = 0; i < _standings.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RankRow(rank: i + 1, entry: _standings[i]),
            ),
          const SizedBox(height: 20),
          PrimaryButton(label: '⬇ Export results', onPressed: () => appState.showToast('Results exported ⬇')),
          const SizedBox(height: 8),
          SecondaryButton(label: '🔗 Share results', onPressed: () => appState.showToast('Results shared! 🔗')),
        ],
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumSpot(initials: 'RF', name: 'Rafi', points: '38 pts', medal: '🥈', barHeight: 52, avatarSize: 46, border: const Color(0xFF90A0B8), bg: const Color(0xFFE8F0F8), fg: const Color(0xFF4A6080), barColors: const [Color(0xFFC0D0E0), Color(0xFFE8F0F8)], nameColor: AppColors.navy)),
        const SizedBox(width: 6),
        Expanded(child: _PodiumSpot(initials: 'IQ', name: 'Iqbal', points: '42 pts', medal: '🥇', barHeight: 80, avatarSize: 56, border: AppColors.gold, bg: const Color(0xFFFFF8DC), fg: const Color(0xFF8A6000), barColors: const [Color(0xFFEEF7E0), Color(0x0D8DC63F)], nameColor: AppColors.greenText, highlight: true)),
        const SizedBox(width: 6),
        Expanded(child: _PodiumSpot(initials: 'BD', name: 'Budi', points: '34 pts', medal: '🥉', barHeight: 38, avatarSize: 44, border: const Color(0xFFC08040), bg: const Color(0xFFFFF0E0), fg: const Color(0xFF8A5000), barColors: const [Color(0xFFE0C8A0), Color(0xFFFFF0E0)], nameColor: AppColors.navy)),
      ],
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const _PodiumSpot({
    required this.initials,
    required this.name,
    required this.points,
    required this.medal,
    required this.barHeight,
    required this.avatarSize,
    required this.border,
    required this.bg,
    required this.fg,
    required this.barColors,
    required this.nameColor,
    this.highlight = false,
  });

  final String initials;
  final String name;
  final String points;
  final String medal;
  final double barHeight;
  final double avatarSize;
  final Color border;
  final Color bg;
  final Color fg;
  final List<Color> barColors;
  final Color nameColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            border: Border.all(color: border, width: 2.5),
            boxShadow: highlight ? [BoxShadow(color: AppColors.gold.withOpacity(0.15), blurRadius: 0, spreadRadius: 4)] : null,
          ),
          child: Text(initials, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: highlight ? 19 : 14)),
        ),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(fontSize: 12, fontWeight: highlight ? FontWeight.w900 : FontWeight.w800, color: nameColor)),
        Text(points, style: TextStyle(fontSize: 11, color: highlight ? AppColors.greenText : AppColors.textMuted, fontWeight: highlight ? FontWeight.w700 : FontWeight.normal)),
        Text(medal, style: const TextStyle(fontSize: 18)),
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: double.infinity,
          height: barHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: LinearGradient(colors: barColors, begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.entry});

  final int rank;
  final _LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isFirst ? AppColors.selectedTile : Colors.white,
        border: Border.all(color: isFirst ? AppColors.green : AppColors.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: isFirst
            ? [BoxShadow(color: AppColors.green.withOpacity(0.12), blurRadius: 0, spreadRadius: 3)]
            : [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text('$rank', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isFirst ? AppColors.gold : AppColors.textFaint)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: entry.bg, shape: BoxShape.circle),
            child: Text(entry.initials, style: TextStyle(color: entry.fg, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
                    if (entry.isYou) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                        child: const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.navy)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(entry.record, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${entry.points}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1, color: isFirst ? AppColors.greenText : AppColors.navy)),
              const Text('pts', style: TextStyle(fontSize: 10, color: AppColors.textFaint, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
