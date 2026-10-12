import 'package:flutter/material.dart';

import '../models/session_summary.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/tab_toggle.dart';
import '../data/api/api_exception.dart';
import 'session_detail_screen.dart';
import 'setup_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  int _tab = 0;
  List<Map<String, dynamic>> _sessions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Sessions come from the backend now, so each row carries its id.
  Future<void> _load() async {
    final appState = AppStateScope.read(context);
    try {
      final rows = await appState.matchApi.fetchSessions(_tab == 0 ? 'active' : 'past');
      if (!mounted) return;
      setState(() {
        _sessions = rows;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = [
      for (final row in _sessions)
        (
          id: '${row['id']}',
          summary: SessionSummary(
            icon: '${row['icon'] ?? '🎾'}',
            name: '${row['name'] ?? ''}',
            detail: [
              if ((row['match_type'] as Map?)?['label'] != null) '${(row['match_type'] as Map)['label']}',
              '${(row['participant_count'] as num?)?.toInt() ?? 0} players',
              if ((row['club'] as Map?)?['name'] != null) '${(row['club'] as Map)['name']}',
            ].join(' · '),
          ),
        ),
    ];
    final tabLabel = _tab == 0 ? 'active' : 'past';

    return AppScaffold(
      title: 'Sessions',
      subtitle: 'Active & past',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          TabToggle(
            labels: const ['Active', 'Past'],
            selectedIndex: _tab,
            onSelect: (i) {
              setState(() => _tab = i);
              _load();
            },
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '+ Create new session',
            compact: true,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen())),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))
          else if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No $tabLabel sessions yet', style: const TextStyle(color: AppColors.textFaint, fontSize: 13)),
              ),
            )
          else
            Column(
              children: [
                for (final session in sessions) ...[
                  _SessionRow(
                    session: session.summary,
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SessionDetailScreen(sessionId: session.id)));
                      _load();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onTap});

  final SessionSummary session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      onTap: onTap,
      child: Row(
        children: [
          Text(session.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(session.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 1),
                Text(session.detail, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Text('›', style: TextStyle(fontSize: 14, color: AppColors.textFaint)),
        ],
      ),
    );
  }
}
