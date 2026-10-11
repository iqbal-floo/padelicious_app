import 'package:flutter/material.dart';

import '../models/session_summary.dart';
import '../state/app_state_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/buttons.dart';
import '../widgets/tab_toggle.dart';
import 'kotc_screen.dart';
import 'setup_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final sessions = _tab == 0 ? appState.activeSessions : appState.pastSessions;
    final tabLabel = _tab == 0 ? 'active' : 'past';

    return AppScaffold(
      title: 'Sessions',
      subtitle: 'Active & past',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          TabToggle(labels: const ['Active', 'Past'], selectedIndex: _tab, onSelect: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          PrimaryButton(
            label: '+ Create new session',
            compact: true,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen())),
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
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
                  _SessionRow(session: session),
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
  const _SessionRow({required this.session});

  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const KotcScreen())),
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
