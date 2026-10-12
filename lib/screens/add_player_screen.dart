import 'package:flutter/material.dart';

import '../data/api/api_exception.dart';
import '../data/api/player_api.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/avatar_badge.dart';
import '../widgets/buttons.dart';
import '../widgets/gender_selector.dart';
import '../widgets/labeled_field.dart';
import '../widgets/section_label.dart';

/// Put a player on a session's roster: find an existing one by name or
/// @username, or create a guest player by hand.
///
/// With a [sessionId] the player is added (confirmed) and the screen pops
/// `true`. Without one — while a session is still being set up — nothing is
/// saved to a roster: the chosen [PlayerRow] is popped back to the caller.
class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key, this.sessionId, this.alreadyOnRoster = const {}});

  final String? sessionId;

  /// Player ids already on the roster, so they are not offered twice.
  final Set<String> alreadyOnRoster;

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  bool _usernameEdited = false;
  String? _gender;
  String? _nameError;
  String? _usernameError;
  bool _busy = false;
  List<PlayerRow> _results = const [];

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _find(String query) async {
    final appState = AppStateScope.read(context);
    try {
      final rows = await appState.playerApi.search(query);
      if (!mounted) return;
      setState(() => _results = rows.where((p) => !widget.alreadyOnRoster.contains(p.id)).toList());
    } on ApiException catch (e) {
      appState.showToast(e.message);
    }
  }

  Future<void> _add(PlayerRow player) async {
    final label = '${player.displayName} ${player.handle}';
    final sessionId = widget.sessionId;
    if (sessionId == null) {
      Navigator.of(context).pop(player);
      return;
    }

    final appState = AppStateScope.read(context);
    setState(() => _busy = true);
    try {
      await appState.matchApi.addParticipant(sessionId, player.id);
      if (!mounted) return;
      appState.showToast('$label added to the roster');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      appState.showToast(e.message);
    }
  }

  Future<void> _create() async {
    final nameError = _name.text.trim().isEmpty ? 'Name is required' : null;
    final usernameError = validateUsername(_username.text);
    setState(() {
      _nameError = nameError;
      _usernameError = usernameError;
    });
    if (nameError != null || usernameError != null) return;

    final appState = AppStateScope.read(context);
    setState(() => _busy = true);
    try {
      final player = await appState.playerApi.createGuest(
        displayName: _name.text,
        username: _username.text,
        gender: _gender,
      );
      await _add(player);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _usernameError = e.errors['username']?.first;
        _nameError = e.errors['display_name']?.first;
      });
      if (_usernameError == null && _nameError == null) appState.showToast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Add player',
      subtitle: 'Find one, or create a guest',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const SectionLabel('Find an existing player'),
          LabeledField(
            label: 'Name or @username',
            controller: _search,
            hint: 'iqbal',
            topSpacing: 4,
            onChanged: _find,
          ),
          const SizedBox(height: 8),
          for (final p in _results.take(8))
            SimpleCard(
              onTap: _busy ? null : () => _add(p),
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  InitialsAvatar(
                    initials: p.initials,
                    background: AppColors.chipPairsBg[p.avatarColorIndex % 8],
                    foreground: AppColors.chipPairsFg[p.avatarColorIndex % 8],
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                        Text('${p.handle}${p.isGuest ? ' · guest' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ],
              ),
            ),
          if (_search.text.trim().isNotEmpty && _results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No player found — create one below.', style: TextStyle(fontSize: 12, color: AppColors.textFaint)),
            ),
          const SizedBox(height: 24),
          const SectionLabel('Or create a guest player'),
          LabeledField(
            label: 'Display name',
            controller: _name,
            hint: 'Hardian',
            topSpacing: 4,
            errorText: _nameError,
            onChanged: (v) {
              if (!_usernameEdited) setState(() => _username.text = suggestUsername(v));
            },
          ),
          LabeledField(
            label: 'Username (unique)',
            controller: _username,
            hint: 'hardian',
            errorText: _usernameError,
            onChanged: (_) => _usernameEdited = true,
          ),
          const SizedBox(height: 14),
          GenderSelector(
            value: _gender,
            onChanged: (v) => setState(() => _gender = v),
            helperText: 'Needed for mixed formats.',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: _busy ? 'Adding…' : (widget.sessionId == null ? 'Create & add →' : 'Create & add to roster →'),
            onPressed: _busy ? null : _create,
          ),
        ],
      ),
    );
  }
}
