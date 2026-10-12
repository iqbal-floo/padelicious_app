import 'package:flutter/material.dart';

import '../data/api/api_exception.dart';
import '../models/live_score.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/padel_header.dart';

/// Scores one real match point by point against the backend. Every tap is
/// one `match_points` event; undo voids the last one. The server decides
/// when the match ends (set, race or total format, golden-point decider),
/// so this screen only shows what it is told.
///
/// Pops `true` if anything was scored, so the caller can refresh.
class MatchScoreScreen extends StatefulWidget {
  const MatchScoreScreen({
    super.key,
    required this.matchId,
    required this.courtNumber,
    this.tennisMode,
  });

  final String matchId;
  final int courtNumber;

  /// The rule this match plays to (its own, else the session's), e.g. "total4".
  final String? tennisMode;

  @override
  State<MatchScoreScreen> createState() => _MatchScoreScreenState();
}

class _MatchScoreScreenState extends State<MatchScoreScreen> {
  LiveScore? _score;
  String? _error;
  bool _sending = false;
  bool _changed = false;
  String? _flash;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final appState = AppStateScope.read(context);
    try {
      final score = await appState.matchApi.fetchLiveScore(widget.matchId);
      if (mounted) setState(() => _score = score);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _send(Future<LiveScore> Function() call, {String? flashSide}) async {
    if (_sending) return;
    final appState = AppStateScope.read(context);
    setState(() {
      _sending = true;
      _flash = flashSide;
    });
    try {
      final next = await call();
      if (!mounted) return;
      setState(() {
        // The point endpoints return the match without session/court
        // context, so keep the team names we already have.
        _score = LiveScore(
          matchId: next.matchId,
          status: next.status,
          gamesA: next.gamesA,
          gamesB: next.gamesB,
          pointsA: next.pointsA,
          pointsB: next.pointsB,
          servingTeam: next.servingTeam,
          winnerTeam: next.winnerTeam,
          sessionName: _score?.sessionName,
          courtLabel: _score?.courtLabel,
          roundNumber: _score?.roundNumber,
          teams: next.teams.isNotEmpty ? next.teams : (_score?.teams ?? const []),
        );
        _changed = true;
      });
      if (next.isFinished) appState.showToast('Match finished 🎉');
    } on ApiException catch (e) {
      appState.showToast(e.message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) setState(() => _flash = null);
        });
      }
    }
  }

  Future<void> _confirmReset(AppState appState) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset this match?'),
        content: const Text('Every point is cleared and the match goes back to 0–0, ready to be scored again.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) await _send(() => appState.matchApi.resetMatch(widget.matchId));
  }

  String _teamName(String side) {
    final team = _score?.teams.where((t) => t.side == side).firstOrNull;
    return team == null || team.playerNames.isEmpty ? 'Team ${side.toUpperCase()}' : team.playerNames.join(' & ');
  }

  /// "Total 4 games · 2-2 → golden point" etc., from the tennis mode.
  String get _ruleLabel {
    final mode = widget.tennisMode;
    if (mode == null) return 'Set to 6 games';
    final n = int.tryParse(mode.substring(mode.length - 1)) ?? 0;
    if (mode.startsWith('race')) return 'First to $n games';
    return n.isEven ? 'Total $n games · ${n ~/ 2}-${n ~/ 2} → golden point' : 'Total $n games';
  }

  /// All games played and level: the next point decides the match.
  bool get _deciderDue {
    final s = _score;
    final mode = widget.tennisMode;
    if (s == null || mode == null || !mode.startsWith('total') || s.isFinished) return false;
    final n = int.tryParse(mode.substring(mode.length - 1)) ?? 0;
    return n.isEven && s.gamesA + s.gamesB == n && s.gamesA == s.gamesB;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final s = _score;
    final finished = s?.isFinished ?? false;
    final status = s == null ? '…' : (finished ? 'Finished' : (s.isLive ? 'Live' : 'Not started'));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: AppScaffold(
        title: 'Court ${widget.courtNumber}',
        subtitle: s?.roundNumber == null ? _ruleLabel.toUpperCase() : 'ROUND ${s!.roundNumber} · ${_ruleLabel.toUpperCase()}',
        onBack: () => Navigator.of(context).pop(_changed),
        trailing: PillBadge(
          status,
          background: finished ? AppColors.green : AppColors.teal,
          foreground: finished ? AppColors.navy : Colors.white,
        ),
        body: _error != null
            ? Padding(padding: const EdgeInsets.only(top: 24), child: Text(_error!, style: const TextStyle(color: AppColors.error)))
            : s == null
                ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(child: SizedBox()),
                                SizedBox(width: 44, child: Text('PTS', textAlign: TextAlign.center, style: _headStyle)),
                                SizedBox(width: 44, child: Text('GAMES', textAlign: TextAlign.right, style: _headStyle)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            for (final side in ['a', 'b'])
                              _ScoreRow(
                                name: _teamName(side),
                                points: finished ? '' : (side == 'a' ? s.pointsA : s.pointsB),
                                games: side == 'a' ? s.gamesA : s.gamesB,
                                serving: !finished && s.servingTeam == side,
                                winner: s.winnerTeam == side,
                                flash: _flash == side,
                              ),
                          ],
                        ),
                      ),
                      if (_deciderDue) ...[
                        const SizedBox(height: 10),
                        const _Banner(
                          text: '⚡ Level on games — the next point wins the match',
                          bg: Color(0xFFFFF4DC),
                          fg: Color(0xFF8A6000),
                        ),
                      ],
                      if (finished) ...[
                        const SizedBox(height: 10),
                        _Banner(
                          text: '🏆 ${_teamName(s.winnerTeam ?? 'a')} win ${s.gamesA}–${s.gamesB}'
                              '${s.gamesA == s.gamesB ? ' (golden point)' : ''}',
                          bg: AppColors.green.withValues(alpha: 0.18),
                          fg: AppColors.greenText,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final side in ['a', 'b']) ...[
                            if (side == 'b') const SizedBox(width: 10),
                            Expanded(
                              child: _PointButton(
                                teamLabel: _teamName(side),
                                enabled: !finished && !_sending,
                                onTap: () => _send(() => appState.matchApi.scorePoint(widget.matchId, side), flashSide: side),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _sending || (s.gamesA + s.gamesB == 0 && s.pointsA == '0' && s.pointsB == '0' && !finished)
                            ? null
                            : () => _send(() => appState.matchApi.undoPoint(widget.matchId)),
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        label: const Text('Undo last point', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (s.isLive || finished) ...[
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _sending ? null : () => _confirmReset(appState),
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('Reset score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                        ),
                      ],
                      if (finished) ...[
                        const SizedBox(height: 6),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Back to session', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  static final _headStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white.withValues(alpha: 0.45));
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.name,
    required this.points,
    required this.games,
    required this.serving,
    required this.winner,
    required this.flash,
  });

  final String name;
  final String points;
  final int games;
  final bool serving;
  final bool winner;
  final bool flash;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: flash ? AppColors.green.withValues(alpha: 0.28) : (winner ? AppColors.green.withValues(alpha: 0.12) : Colors.transparent),
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
              boxShadow: serving ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.6), blurRadius: 6)] : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(points, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.8))),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$games',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, color: winner ? AppColors.green : Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointButton extends StatelessWidget {
  const _PointButton({required this.teamLabel, required this.onTap, required this.enabled});

  final String teamLabel;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            child: Column(
              children: [
                const Text('Point for', style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
                const SizedBox(height: 4),
                Text(teamLabel, maxLines: 2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const Text('+1', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.greenText, height: 1.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
