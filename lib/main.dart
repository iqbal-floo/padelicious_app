import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PadeliciousApp());
}

class PadeliciousApp extends StatefulWidget {
  const PadeliciousApp({super.key});

  @override
  State<PadeliciousApp> createState() => _PadeliciousAppState();
}

class _PadeliciousAppState extends State<PadeliciousApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState(messengerKey: _messengerKey);
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      appState: _appState,
      child: MaterialApp(
        title: 'Padelicious',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: _messengerKey,
        theme: AppTheme.light,
        home: const _AppLoader(),
      ),
    );
  }
}

/// Loads the mock catalogs (players/clubs/sessions) once before showing the
/// rest of the app — a real backend-backed AppState would do the same thing
/// while its network calls are in flight.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  @override
  void initState() {
    super.initState();
    AppStateScope.read(context).ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    if (!appState.isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }
    return const LoginScreen();
  }
}
