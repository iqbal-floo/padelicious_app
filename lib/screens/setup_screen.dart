import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/match_config.dart';
import '../state/app_state.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/buttons.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/form_row.dart';
import '../widgets/padel_header.dart';
import '../widgets/section_label.dart';
import 'kotc_screen.dart';

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
    appState.resetSetupPlayersIfEmpty(MockData.defaultSetupPlayers);
    _matchName = TextEditingController(text: appState.matchName);
    _matchCode = TextEditingController(text: appState.matchCode);
  }

  @override
  void dispose() {
    _matchName.dispose();
    _matchCode.dispose();
    super.dispose();
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
                      '✓ Imported ${appState.setupPlayers.length} players (with photos) from Reclub',
                      style: const TextStyle(fontSize: 12, color: AppColors.greenText, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SectionLabel(
            'Players',
            trailing: '${appState.setupPlayers.length} added${appState.importStatus == ImportStatus.success ? ' via Reclub' : ''}',
          ),
          Column(
            children: [
              for (final p in appState.setupPlayers)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.07), blurRadius: 4, offset: const Offset(0, 1))],
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(initials: p.initials, background: p.bg, foreground: p.color, size: 36, fontSize: 12),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy))),
                      if (p.badge != null) ...[SmallBadge(p.badge!), const SizedBox(width: 6)],
                      if (p.fromReclub) const SmallBadge('via Reclub', background: AppColors.surfaceAlt, foreground: AppColors.greenText),
                    ],
                  ),
                ),
            ],
          ),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => appState.showToast('Add player — coming in v1.0'),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderStrong, width: 1.5, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('+ Add player manually', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textFaint)),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Start session →',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KotcScreen())),
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
