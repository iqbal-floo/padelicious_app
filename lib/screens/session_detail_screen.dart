import 'package:flutter/material.dart';

import '../data/api/api_exception.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/order_of_play_button.dart';
import '../widgets/padel_header.dart';
import '../widgets/roster_grid.dart';
import '../widgets/section_label.dart';
import 'add_match_screen.dart';
import 'add_player_screen.dart';
import 'match_score_screen.dart';

/// A backend session: its roster and rounds, with the host's actions —
/// add players, enter matches by hand, generate a round, export the sheet.
class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _rounds = const [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AppStateScope.read(context).activeSessionId = widget.sessionId;
    _load();
  }

  Future<void> _load() async {
    final appState = AppStateScope.read(context);
    try {
      final session = await appState.matchApi.fetchSession(widget.sessionId);
      final rounds = await appState.matchApi.fetchRounds(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _rounds = rounds
          ..sort((a, b) =>
              (a['round_number'] as int).compareTo(b['round_number'] as int));
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    final appState = AppStateScope.read(context);
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) appState.showToast(done);
      await _load();
    } on ApiException catch (e) {
      appState.showToast(e.firstError ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> get _participants =>
      ((_session?['participants'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

  /// Everyone still on the roster (withdrawn players are hidden).
  List<RosterPerson> get _people => [
        for (final p in _participants)
          if (p['status'] != 'withdrawn') RosterPerson.fromParticipant(p),
      ];

  /// The signed-in user is the creator or tagged host.
  bool get _canManage => _session?['can_manage'] == true;

  Map<String, dynamic>? get _me =>
      _session?['my_participant'] as Map<String, dynamic>?;

  Future<void> _manage(RosterPerson person) async {
    final appState = AppStateScope.read(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _ManageSheet(
        person: person,
        onStatus: (status) => _run(
          () => appState.matchApi
              .updateParticipant(widget.sessionId, person.id, status: status),
          done: '${person.name} → ${rosterStatusLabels[status]}',
        ),
        onTags: (tags) => _run(
          () => appState.matchApi
              .updateParticipant(widget.sessionId, person.id, tags: tags),
          done: '${person.name} updated',
        ),
        onRemove: () => _run(
          () =>
              appState.matchApi.removeParticipant(widget.sessionId, person.id),
          done: '${person.name} removed from the session',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final session = _session;
    final matchType = (session?['match_type'] as Map?)?['label'] ?? '';
    final courtCount = (session?['court_count'] as num?)?.toInt() ?? 1;
    final openRound =
        _rounds.where((r) => r['status'] == 'in_progress').firstOrNull;
    final nextRound =
        _rounds.isEmpty ? 1 : (_rounds.last['round_number'] as int) + 1;

    return AppScaffold(
      title: '${session?['icon'] ?? '🎾'} ${session?['name'] ?? 'Session'}',
      subtitle: session == null
          ? 'Loading…'
          : '$matchType · $courtCount court · ${session['status']}',
      trailing: session == null
          ? null
          : PillBadge(
              '${_rounds.length} round${_rounds.length == 1 ? '' : 's'}'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13))
          else if (session == null)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))
          else ...[
            if (!_canManage)
              _JoinBanner(
                  me: _me,
                  busy: _busy,
                  onJoin: () => _run(
                        () => appState.matchApi.requestToJoin(widget.sessionId),
                        done: 'Request sent — a host will confirm you',
                      )),
            _RosterCard(
              people: _people,
              onTapPerson: _canManage && !_busy ? _manage : null,
              onAdd: !_canManage || _busy
                  ? null
                  : () async {
                      final added = await Navigator.of(context)
                          .push<bool>(MaterialPageRoute(
                        builder: (_) => AddPlayerScreen(
                          sessionId: widget.sessionId,
                          alreadyOnRoster: {
                            for (final p in _participants)
                              if (p['status'] != 'withdrawn')
                                '${p['player_id']}',
                          },
                        ),
                      ));
                      if (added == true) _load();
                    },
            ),
            const SizedBox(height: 24),
            const SectionLabel('Rounds'),
            if (_rounds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    'No rounds yet — add matches by hand or generate a round.',
                    style: TextStyle(fontSize: 12, color: AppColors.textFaint)),
              ),
            for (final round in _rounds)
              _RoundCard(
                round: round,
                busy: _busy,
                canManage: _canManage,
                onComplete: () => _run(
                  () => appState.matchApi.completeRound(round['id'] as String),
                  done: 'Round ${round['round_number']} completed',
                ),
                onReopen: () => _run(
                  () => appState.matchApi.reopenRound(round['id'] as String),
                  done:
                      'Round ${round['round_number']} reopened — tap a match to fix its score',
                ),
                onOpenMatch: (match) async {
                  final changed =
                      await Navigator.of(context).push<bool>(MaterialPageRoute(
                    builder: (_) => MatchScoreScreen(
                      matchId: match['id'] as String,
                      courtNumber:
                          ((match['court'] as Map?)?['court_number'] as num?)
                                  ?.toInt() ??
                              0,
                      // The match's own rule, else the session's (tennis only).
                      tennisMode: match['tennis_mode'] as String? ??
                          (session['scoring_type'] == 'tennis'
                              ? session['tennis_mode'] as String?
                              : null),
                    ),
                  ));
                  if (changed == true) _load();
                },
              ),
            if (_canManage) ...[
              const SizedBox(height: 12),
              PrimaryButton(
                label: '+ Add match (by hand)',
                compact: true,
                onPressed: _busy
                    ? null
                    : () async {
                        final saved = await Navigator.of(context)
                            .push<bool>(MaterialPageRoute(
                          builder: (_) => AddMatchScreen(
                            sessionId: widget.sessionId,
                            courtCount: courtCount,
                            nextRoundNumber: nextRound,
                            // Only confirmed players who are here can play.
                            roster: [
                              for (final p in _people)
                                if (p.canPlay)
                                  RosterEntry(
                                      participantId: p.id,
                                      label: '${p.name} ${p.handle}'),
                            ],
                          ),
                        ));
                        if (saved == true) _load();
                      },
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: openRound == null
                    ? 'Generate next round'
                    : 'Generate next round (finish round ${openRound['round_number']} first)',
                onPressed: _busy || openRound != null
                    ? null
                    : () => _run(
                        () => appState.matchApi.generateRound(widget.sessionId),
                        done: 'Round generated'),
              ),
            ],
            const SizedBox(height: 8),
            OrderOfPlayButton(sessionId: widget.sessionId),
          ],
        ],
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({
    required this.round,
    required this.busy,
    required this.onComplete,
    required this.onReopen,
    required this.onOpenMatch,
    required this.canManage,
  });

  final Map<String, dynamic> round;
  final bool busy;
  final bool canManage;
  final VoidCallback onComplete;
  final VoidCallback onReopen;
  final ValueChanged<Map<String, dynamic>> onOpenMatch;

  @override
  Widget build(BuildContext context) {
    final matches = ((round['matches'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList()
      ..sort((a, b) => ((a['court'] as Map?)?['court_number'] as int? ?? 0)
          .compareTo((b['court'] as Map?)?['court_number'] as int? ?? 0));
    final status = '${round['status']}';

    return SimpleCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Round ${round['round_number']}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy)),
              const SizedBox(width: 8),
              PillBadge(status.replaceAll('_', ' ')),
              const Spacer(),
              if (status == 'in_progress' && canManage)
                TextButton(
                  onPressed: busy ? null : onComplete,
                  child: const Text('Complete',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal)),
                ),
              // Closed rounds are locked; reopening is how a result gets fixed.
              if (status == 'completed' && canManage)
                TextButton.icon(
                  onPressed: busy ? null : onReopen,
                  icon: const Icon(Icons.lock_open_rounded, size: 15),
                  label: const Text('Reopen',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted),
                ),
            ],
          ),
          // Only the round being played takes scores; a pending round has
          // not started and a completed one is closed.
          for (final m in matches)
            _MatchLine(
                match: m,
                onTap: canManage && status == 'in_progress' && !busy
                    ? () => onOpenMatch(m)
                    : null),
          if (status == 'in_progress' && canManage)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Tap a match to enter its score',
                  style: TextStyle(fontSize: 11, color: AppColors.textFaint)),
            ),
        ],
      ),
    );
  }
}

class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.match, this.onTap});

  final Map<String, dynamic> match;

  /// Opens the score screen; null when the round is not being played.
  final VoidCallback? onTap;

  String _names(String side) {
    final teams = ((match['teams'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>();
    final team = teams.where((t) => t['side'] == side).firstOrNull;
    return ((team?['players'] as List?) ?? const [])
        .map((p) => '${(p as Map)['display_name']}')
        .join(' & ');
  }

  @override
  Widget build(BuildContext context) {
    final court = (match['court'] as Map?)?['court_number'];
    final status = match['status'];
    final finished = status == 'finished';
    final live = status == 'live';
    final score =
        finished || live ? '${match['games_a']}–${match['games_b']}' : 'vs';

    final row = Row(
      children: [
        SizedBox(
            width: 28,
            child: Text('C$court',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted))),
        Expanded(
            child: Text(_names('a'),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy))),
        SizedBox(
          width: 52,
          child: Text(
            score,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: finished
                  ? AppColors.greenText
                  : (live ? AppColors.teal : AppColors.textFaint),
            ),
          ),
        ),
        Expanded(
            child: Text(_names('b'),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy))),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: AppColors.textFaint),
        ],
      ],
    );

    if (onTap == null) {
      return Padding(padding: const EdgeInsets.only(top: 6), child: row);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Material(
        color: live ? AppColors.tealSurface : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 9, 2, 9), child: row),
        ),
      ),
    );
  }
}

/// The roster as a collapsible card. Collapsed: confirmed count, waitlist
/// and request counts, and overlapping avatars. Expanded: the grid, grouped
/// by status. Hosts tap a player to manage them.
class _RosterCard extends StatefulWidget {
  const _RosterCard(
      {required this.people, required this.onTapPerson, required this.onAdd});

  final List<RosterPerson> people;
  final ValueChanged<RosterPerson>? onTapPerson;
  final VoidCallback? onAdd;

  @override
  State<_RosterCard> createState() => _RosterCardState();
}

class _RosterCardState extends State<_RosterCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final confirmed =
        widget.people.where((p) => p.status == 'confirmed').toList();
    final waitlisted =
        widget.people.where((p) => p.status == 'waitlisted').toList();
    final requested =
        widget.people.where((p) => p.status == 'requested').toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Row(
                children: [
                  const Text('ROSTER',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.textFaint)),
                  const SizedBox(width: 8),
                  _CountPill('${confirmed.length}',
                      bg: AppColors.tealSurface, fg: AppColors.tealDark),
                  if (waitlisted.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _CountPill('${waitlisted.length} wait',
                        bg: const Color(0xFFFFF4DC),
                        fg: const Color(0xFFB07800)),
                  ],
                  if (requested.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    _CountPill('${requested.length} req',
                        bg: AppColors.teal, fg: Colors.white),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _expanded ? 0 : 1,
                      child: AvatarStack(people: confirmed, max: 5),
                    ),
                  ),
                  if (widget.onAdd != null)
                    IconButton(
                      onPressed: widget.onAdd,
                      tooltip: 'Add player',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.person_add_alt_1_rounded,
                          color: AppColors.teal, size: 20),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Requests first: they are waiting on a host.
                        if (requested.isNotEmpty) ...[
                          _GroupLabel('Requested · ${requested.length}',
                              hint: widget.onTapPerson == null
                                  ? null
                                  : 'tap to approve'),
                          RosterGrid(
                              people: requested, onTap: widget.onTapPerson),
                          const SizedBox(height: 10),
                        ],
                        _GroupLabel('Confirmed · ${confirmed.length}'),
                        RosterGrid(
                            people: confirmed,
                            onTap: widget.onTapPerson,
                            onAdd: widget.onAdd),
                        if (waitlisted.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _GroupLabel('Waitlisted · ${waitlisted.length}'),
                          RosterGrid(
                              people: waitlisted, onTap: widget.onTapPerson),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill(this.text, {required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
      );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Row(
          children: [
            Text(text.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textMuted)),
            if (hint != null) ...[
              const SizedBox(width: 6),
              Text(hint!,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      );
}

/// For someone who is not a host: ask to join, or see where the request stands.
class _JoinBanner extends StatelessWidget {
  const _JoinBanner(
      {required this.me, required this.busy, required this.onJoin});

  final Map<String, dynamic>? me;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final status = me?['status'] as String?;
    final (text, action) = switch (status) {
      null || 'withdrawn' => ('You are not on this session yet.', true),
      'requested' => (
          'Request sent — waiting for a host to confirm you.',
          false
        ),
      'waitlisted' => ('You are on the waitlist.', false),
      _ => ('You are confirmed for this session. ✓', false),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
          color: AppColors.tealSurface,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealDark))),
          if (action)
            FilledButton(
              onPressed: busy ? null : onJoin,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  visualDensity: VisualDensity.compact),
              child: const Text('Request to join'),
            ),
        ],
      ),
    );
  }
}

/// Host controls for one player: status, tags, removal. Each change is
/// saved at once and the sheet closes.
class _ManageSheet extends StatelessWidget {
  const _ManageSheet(
      {required this.person,
      required this.onStatus,
      required this.onTags,
      required this.onRemove});

  final RosterPerson person;
  final ValueChanged<String> onStatus;
  final ValueChanged<List<String>> onTags;
  final VoidCallback onRemove;

  void _toggle(BuildContext context, String tag, bool on) {
    final tags = {...person.tags};
    on ? tags.add(tag) : tags.remove(tag);
    Navigator.of(context).pop();
    onTags(tags.toList());
  }

  @override
  Widget build(BuildContext context) {
    final p = person;
    final i = p.colorIndex;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.chipPairsBg[i],
                  child: Text(p.initials,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.chipPairsFg[i])),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy)),
                      Text(
                        [
                          if (p.username != null) p.handle,
                          if (p.isCreator) 'session creator',
                          if (p.source == 'reclub') 'via Reclub'
                        ].join(' · '),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('STATUS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textFaint)),
            const SizedBox(height: 6),
            if (p.status == 'requested')
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('Asked to join — confirm or waitlist them.',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.tealDark,
                        fontWeight: FontWeight.w700)),
              ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'confirmed',
                    label: Text('Confirmed'),
                    icon: Icon(Icons.check_circle_rounded, size: 18)),
                ButtonSegment(
                    value: 'waitlisted',
                    label: Text('Waitlisted'),
                    icon: Icon(Icons.hourglass_top_rounded, size: 18)),
              ],
              // A request is neither yet.
              selected: {
                if (p.status == 'confirmed' || p.status == 'waitlisted')
                  p.status
              },
              emptySelectionAllowed: true,
              onSelectionChanged: (sel) {
                if (sel.isEmpty || sel.first == p.status) return;
                Navigator.of(context).pop();
                onStatus(sel.first);
              },
            ),
            const SizedBox(height: 16),
            const Text('TAGS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.textFaint)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary:
                  const Icon(Icons.star_rounded, color: Color(0xFFF2B705)),
              title: const Text('Host',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(p.isCreator
                  ? 'The creator is always a host'
                  : 'Can manage players, rounds and scores'),
              value: p.isHost,
              onChanged:
                  p.isCreator ? null : (on) => _toggle(context, 'host', on),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary:
                  const Icon(Icons.person_off_rounded, color: AppColors.error),
              title: const Text('No-show',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle:
                  const Text('Left out of generated rounds and new matches'),
              value: p.isNoShow,
              onChanged: (on) => _toggle(context, 'no_show', on),
            ),
            if (!p.isCreator) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRemove();
                },
                icon: const Icon(Icons.person_remove_rounded, size: 18),
                label: const Text('Remove from session'),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
