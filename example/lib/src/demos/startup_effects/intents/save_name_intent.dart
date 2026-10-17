import 'dart:async';

import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/utils.dart';

/// Validates with `JValidationUtils` and updates the state.
class SaveNameIntent extends JIntent<StartupState>
    with JIntentHelpers<StartupState> {
  SaveNameIntent(this.name);

  final String name;

  @override
  Future<void> onInvoke() async {
    final trimmed = name.trim();
    if (!JValidationUtils.isTextLengthInRange(trimmed, min: 3, max: 12)) {
      update((s) => s.copyWith(status: 'The name needs 3 to 12 characters'));
      return;
    }
    update((s) => s.copyWith(name: trimmed, status: 'Saved "$trimmed"'));
  }
}
