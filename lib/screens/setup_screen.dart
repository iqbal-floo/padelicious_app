import 'package:flutter/material.dart';

import '../models/match_config.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/roster_grid.dart';
import '../widgets/buttons.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/form_row.dart';
import '../widgets/padel_header.dart';
import '../widgets/section_label.dart';
import '../data/api/api_exception.dart';
import '../data/api/player_api.dart';
import 'add_player_screen.dart';
import 'session_detail_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController _matchName;
  late final TextEditingController _matchCode;

  @override
  void initState() {
    super.initState();
    final appState = AppStateScope.read(context);
    _matchName = TextEditingController(text: appState.matchName);
    _matchCode = TextEditingController(text: appState.matchCode);
  }

  @override
  void dispose() {
    _matchName.dispose();
    _matchCode.dispose();
    super.dispose();
  }

  bool _starting = false;

  /// The roster as it will be created: the creator first (host), then
  /// players picked by hand, then Reclub imports.
  List<RosterPerson> _roster(AppState appState) {
    final auth = appState.auth;
    return [
      RosterPerson(
        id: 'me',
        name: auth.displayName ?? 'You',
        initials: auth.initials ?? '··',
        colorIndex: auth.avatarColorIndex,
        username: auth.username,
        tags: const ['host'],
        isCreator: true,
      ),
      for (final p in appState.setupPicked)
        RosterPerson(
          id: p.id,
          name: p.displayName,
          initials: p.initials,
          colorIndex: p.avatarColorIndex % 8,
          username: p.username,
        ),
      for (final r in appState.reclubImported)
        // Whoever created the session is already on it as host.
        if (r.player.username != auth.username)
          RosterPerson(
            id: r.player.id,
            name: r.player.displayName,
            initials: r.player.initials,
            colorIndex: r.player.avatarColorIndex % 8,
            username: r.player.username,
            status: r.status,
            source: 'reclub',
          ),
    ];
  }

  Future<void> _removeFromSetup(AppState appState, RosterPerson person) async {
    if (person.isCreator) {
      appState.showToast('You are the host of this session');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${person.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) appState.removeSetupPlayer(person.id);
  }

  /// Creates the session on the backend from the form — with the players
  /// picked here and any Reclub import — then opens it.
  Future<void> _start(AppState appState) async {
    setState(() => _starting = true);
    try {
      final tennis = appState.scoringType == 'tennis';
      final id = await appState.matchApi.createSession(
        name: appState.matchName.trim().isEmpty ? 'Padel session' : appState.matchName.trim(),
        matchTypeCode: appState.matchType,
        scheduledDate: appState.matchDate,
        courtCount: appState.courts,
        scoringType: appState.scoringType,
        pointsTarget: !tennis && appState.normalTarget != 'undefined' ? int.tryParse(appState.normalTarget) : null,
        tennisMode: tennis && appState.tennisMode != 'undefined' ? appState.tennisMode : null,
        goldenPoint: appState.golden,
        leaderboardSort: appState.sortBy,
        playerIds: [for (final p in appState.setupPicked) p.id],
        reclubPlayers: {
          for (final r in appState.reclubImported)
            if (r.player.username != appState.auth.username) r.player.id: r.status,
        },
      );
      appState.resetSetupRoster();
      appState.activeSessionId = id;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: id)));
    } on ApiException catch (e) {
      appState.showToast(e.firstError ?? e.message);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AppScaffold(
      title: '🎾 Padelicious',
      trailing: const PillBadge('New session'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SectionLabel('Match details'),
          SectionCard(children: [
            SectionCardRow(
              child: FormFieldRow(
                icon: '🏷️',
                label: 'Match name',
                child: TextField(
                  controller: _matchName,
                  onChanged: (v) => appState.updateSetup(matchName: v),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                  decoration: const InputDecoration(
                    hintText: 'Sunday Padel Session',
                    fillColor: AppColors.surfaceAlt,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
            ),
            SectionCardRow(
              child: FormFieldRow(
                icon: '📅',
                label: 'Match date',
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: appState.matchDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) appState.updateSetup(matchDate: picked);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                    child: Text(
                      _formatDate(appState.matchDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                    ),
                  ),
                ),
              ),
            ),
            SectionCardRow(
              showDivider: false,
              child: FormFieldRow(
                icon: '🎾',
                label: 'Match type',
                child: GroupedDropdown(
                  value: appState.matchType,
                  groups: matchTypeGroups,
                  onChanged: (v) => appState.updateSetup(matchType: v),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('Court settings'),
          SectionCard(children: [
            SectionCardRow(
              child: FormFieldRow(
                icon: '🏟️',
                label: 'Number of courts',
                child: Row(
                  children: [
                    _StepperButton(symbol: '−', onTap: () => appState.updateSetup(courts: appState.courts - 1)),
                    SizedBox(
                      width: 32,
                      child: Text('${appState.courts}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.greenText)),
                    ),
                    _StepperButton(symbol: '+', onTap: () => appState.updateSetup(courts: appState.courts + 1)),
                  ],
                ),
              ),
            ),
            SectionCardRow(
              child: FormFieldRow(
                icon: '🎮',
                label: 'Scoring type',
                child: SimpleDropdown(
                  value: appState.scoringType,
                  options: const [MatchTypeOption('normal', 'Point scoring'), MatchTypeOption('tennis', 'Tennis scoring')],
                  onChanged: (v) => appState.updateSetup(scoringType: v),
                ),
              ),
            ),
            if (appState.scoringType == 'normal')
              SectionCardRow(
                child: FormFieldRow(
                  label: 'Total points',
                  child: SimpleDropdown(
                    value: appState.normalTarget,
                    options: normalTargetOptions,
                    onChanged: (v) => appState.updateSetup(normalTarget: v),
                  ),
                ),
              )
            else
              SectionCardRow(
                child: FormFieldRow(
                  label: 'Tennis format',
                  child: SimpleDropdown(
                    value: appState.tennisMode,
                    options: tennisModeOptions,
                    onChanged: (v) => appState.updateSetup(tennisMode: v),
                  ),
                ),
              ),
            SectionCardRow(
              showDivider: false,
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 19)),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Golden point', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy))),
                  Switch(
                    value: appState.golden,
                    onChanged: (v) => appState.updateSetup(golden: v),
                    activeColor: AppColors.navy,
                    activeTrackColor: AppColors.green,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('Configuration'),
          SectionCard(children: [
            SectionCardRow(
              showDivider: false,
              child: FormFieldRow(
                icon: '📶',
                label: 'Sort leaderboard by',
                child: SimpleDropdown(
                  value: appState.sortBy,
                  options: const [MatchTypeOption('points', 'Points'), MatchTypeOption('wins', 'Wins')],
                  onChanged: (v) => appState.updateSetup(sortBy: v),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('Import players'),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔗', style: TextStyle(fontSize: 19)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Import from Reclub', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.navy)),
                          SizedBox(height: 1),
                          Text('Paste your match code to pull in players & photos', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _matchCode,
                        onChanged: (v) => appState.updateSetup(matchCode: v),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                        decoration: const InputDecoration(
                          hintText: 'e.g. RC-8421',
                          fillColor: AppColors.surface,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: appState.importStatus == ImportStatus.loading ? null : () => appState.fetchReclubImport(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        appState.importStatus == ImportStatus.loading ? 'Fetching…' : 'Fetch',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                if (appState.importError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(appState.importError!, style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
                  ),
                if (appState.importStatus == ImportStatus.success)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '✓ ${appState.reclubImported.length} players from ${appState.reclubTitle ?? 'Reclub'}',
                      style: const TextStyle(fontSize: 12, color: AppColors.greenText, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Builder(builder: (context) {
            final roster = _roster(appState);
            final reclub = appState.reclubImported.length;
            final waitlisted = roster.where((p) => p.status == 'waitlisted').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(
                  'Players',
                  trailing: '${roster.length - waitlisted} confirmed'
                      '${waitlisted > 0 ? ' · $waitlisted waitlisted' : ''}'
                      '${reclub > 0 ? ' · $reclub via Reclub' : ''}',
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: RosterGrid(
                    people: roster,
                    onTap: (person) => _removeFromSetup(appState, person),
                    onAdd: () async {
                      final picked = await Navigator.of(context).push<PlayerRow>(MaterialPageRoute(
                        builder: (_) => AddPlayerScreen(
                          alreadyOnRoster: {for (final p in appState.setupPicked) p.id},
                        ),
                      ));
                      if (picked != null) appState.addSetupPlayer(picked);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 2),
                  child: Text(
                    'You join as host. Added players start confirmed; Reclub players keep their Reclub list. Tap one to remove.',
                    style: TextStyle(fontSize: 11, color: AppColors.textFaint),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _starting ? 'Creating session…' : 'Start session →',
            onPressed: _starting ? null : () => _start(appState),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'A shareable link will be created automatically',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textFaint),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.symbol, required this.onTap});

  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
        child: Text(symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
