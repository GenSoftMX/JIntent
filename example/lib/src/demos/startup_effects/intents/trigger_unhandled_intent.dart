import 'dart:async';

import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:counter/src/demos/startup_effects/effects/unregistered_effect.dart';
import 'package:jintent/jintent.dart';

/// Emits an awaitable effect nobody handles: the default strategy fails it.
class TriggerUnhandledIntent extends JIntent<StartupState>
    with JIntentHelpers<StartupState> {
  @override
  Future<void> onInvoke() async {
    try {
      await controller.emitAndWaitSideEffect<bool>(UnregisteredEffect());
    } on StateError catch (error) {
      if (!controller.mounted) return;
      update((s) => s.copyWith(status: 'Failed: ${error.message}'));
    }
  }
}
