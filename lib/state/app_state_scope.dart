import 'package:flutter/material.dart';

import 'app_state.dart';

/// Makes a single [AppState] instance available to the whole widget tree.
/// Screens read it with `AppStateScope.of(context)` (rebuilds on change) or
/// `AppStateScope.read(context)` (no rebuild — for one-off calls like inside
/// a button's onPressed).
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({Key? key, required AppState appState, required Widget child})
      : super(key: key, notifier: appState, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.notifier!;
  }
}
