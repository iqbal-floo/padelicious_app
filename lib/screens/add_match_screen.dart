import 'package:flutter/material.dart';

import '../data/api/api_exception.dart';
import '../models/match_config.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/dropdown_field.dart';
import '../widgets/form_row.dart';
import '../widgets/labeled_field.dart';
import '../widgets/section_label.dart';

/// A roster entry the host can put into a match.
class RosterEntry {
  const RosterEntry({required this.participantId, required this.label});

  final String participantId;

  /// "Dikdoyo @dikdoyo" — the handle tells two Iqbals apart.
  final String label;
}

/// One match being composed: a court, two players a side, optional rule.
class _MatchDraft {
  _MatchDraft(this.court);

  int court;
  final List<String> players = ['', '', '', ''];
  String tennisMode = '';
}

/// Enter a round by hand: one or more matches, each with its court and
/// four players. Sends them as a single round; the backend validates
/// courts, duplicates and fixed partnerships and names the offending
/// match in its message.
class AddMatchScreen extends StatefulWidget {
  const AddMatchScreen({
    super.key,
    required this.sessionId,
    required this.roster,
    required this.courtCount,
    this.nextRoundNumber,
  });

  final String sessionId;
  final List<RosterEntry> roster;
  final int courtCount;
  final int? nextRoundNumber;

  @override
  State<AddMatchScreen> createState() => _AddMatchScreenState();
}

class _AddMatchScreenState extends State<AddMatchScreen> {
  late final List<_MatchDraft> _drafts = [_MatchDraft(1)];
  late final TextEditingController _roundNumber =
      TextEditingController(text: widget.nextRoundNumber?.toString() ?? '');
  bool _busy = false;

  @override
  void dispose() {
    _roundNumber.dispose();
    super.dispose();
  }

  /// Players still free for this slot: everyone not picked elsewhere.
  List<MatchTypeOption> _optionsFor(_MatchDraft draft, int slot) {
    final taken = <String>{
      for (final d in _drafts)
        for (var i = 0; i < 4; i++)
          if (!(identical(d, draft) && i == slot) && d.players[i].isNotEmpty) d.players[i],
    };
    return [
      const MatchTypeOption('', '— pick a player —'),
      for (final r in widget.roster)
        if (!taken.contains(r.participantId)) MatchTypeOption(r.participantId, r.label),
    ];
  }

  Future<void> _save() async {
    for (var i = 0; i < _drafts.length; i++) {
      if (_drafts[i].players.any((p) => p.isEmpty)) {
        AppStateScope.read(context).showToast('Match ${i + 1}: pick all four players');
        return;
      }
    }

    final appState = AppStateScope.read(context);
    setState(() => _busy = true);
    try {
      await appState.matchApi.createRound(
        widget.sessionId,
        [
          for (final d in _drafts)
            {
              'court': d.court,
              'team_a': [d.players[0], d.players[1]],
              'team_b': [d.players[2], d.players[3]],
              if (d.tennisMode.isNotEmpty) 'tennis_mode': d.tennisMode,
            },
        ],
        roundNumber: int.tryParse(_roundNumber.text.trim()),
      );
      if (!mounted) return;
      appState.showToast('Round saved — ${_drafts.length} match(es)');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      // 422 messages name the match: "Match 2: Ana is listed twice…".
      appState.showToast(e.firstError ?? e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final courtOptions = [
      for (var c = 1; c <= widget.courtCount; c++) MatchTypeOption('$c', 'Court $c'),
    ];
    final formatOptions = [
      const MatchTypeOption('', 'Session rule'),
      ...tennisModeOptions.where((o) => o.value != 'undefined'),
    ];

    return AppScaffold(
      title: 'Add match',
      subtitle: 'Enter a round by hand',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          LabeledField(
            label: 'Round number (optional)',
            controller: _roundNumber,
            hint: 'next free',
            keyboardType: TextInputType.number,
            topSpacing: 0,
          ),
          for (var i = 0; i < _drafts.length; i++) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SectionLabel('Match ${i + 1}'),
                if (_drafts.length > 1)
                  TextButton(
                    onPressed: () => setState(() => _drafts.removeAt(i)),
                    child: const Text('Remove', style: TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
              ],
            ),
            SectionCard(children: [
              SectionCardRow(
                child: FormFieldRow(
                  icon: '🏟️',
                  label: 'Court',
                  child: SimpleDropdown(
                    value: '${_drafts[i].court}',
                    options: courtOptions,
                    onChanged: (v) => setState(() => _drafts[i].court = int.parse(v)),
                  ),
                ),
              ),
              for (final slot in [0, 1, 2, 3])
                SectionCardRow(
                  child: FormFieldRow(
                    icon: slot < 2 ? '🅰️' : '🅱️',
                    label: 'Team ${slot < 2 ? 'A' : 'B'} · player ${slot % 2 + 1}',
                    child: SimpleDropdown(
                      value: _drafts[i].players[slot],
                      options: _optionsFor(_drafts[i], slot),
                      onChanged: (v) => setState(() => _drafts[i].players[slot] = v),
                    ),
                  ),
                ),
              SectionCardRow(
                showDivider: false,
                child: FormFieldRow(
                  icon: '🎮',
                  label: 'Format for this match',
                  child: SimpleDropdown(
                    value: _drafts[i].tennisMode,
                    options: formatOptions,
                    onChanged: (v) => setState(() => _drafts[i].tennisMode = v),
                  ),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 12),
          if (_drafts.length < widget.courtCount)
            SecondaryButton(
              label: '+ Another court in this round',
              onPressed: () => setState(() {
                final used = _drafts.map((d) => d.court).toSet();
                var next = 1;
                while (used.contains(next) && next < widget.courtCount) {
                  next++;
                }
                _drafts.add(_MatchDraft(next));
              }),
            ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: _busy ? 'Saving…' : 'Save round →',
            onPressed: _busy ? null : _save,
          ),
        ],
      ),
    );
  }
}
