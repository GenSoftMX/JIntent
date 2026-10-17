import 'dart:async';

import 'package:counter/src/demos/startup_effects/effects/confirm_effect.dart';
import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:jintent/jintent.dart';

/// Waits for the UI to answer a dialog, with a timeout.
class AskConfirmationIntent extends JIntent<StartupState>
    with JIntentHelpers<StartupState> {
  AskConfirmationIntent(this.timeout);

  final Duration timeout;

  @override
  Future<void> onInvoke() async {
    try {
      final confirmed = await controller.emitAndWaitSideEffect<bool>(
        ConfirmEffect('Reset the saved name?'),
        timeout: timeout,
      );
      if (!controller.mounted) return;
      if (confirmed) {
        update((_) => const StartupState(status: 'Name reset'));
      } else {
        update((s) => s.copyWith(status: 'Kept the saved name'));
      }
    } on TimeoutException {
      if (!controller.mounted) return;
      update((s) => s.copyWith(status: 'No answer in time'));
    }
  }
}
