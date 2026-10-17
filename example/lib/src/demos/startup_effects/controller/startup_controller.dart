import 'dart:async';

import 'package:counter/src/demos/startup_effects/intents/ask_confirmation_intent.dart';
import 'package:counter/src/demos/startup_effects/intents/save_name_intent.dart';
import 'package:counter/src/demos/startup_effects/effects/show_welcome_effect.dart';
import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:counter/src/demos/startup_effects/intents/trigger_unhandled_intent.dart';
import 'package:jintent/jintent.dart';

class StartupController extends JController<StartupState> {
  /// With [buffered] the welcome effect emitted in [onInit] is retained until
  /// the UI attaches its listener. Without it the effect is dropped, because
  /// nobody is listening yet.
  StartupController({
    required bool buffered,
    this.confirmTimeout = const Duration(seconds: 10),
  }) : super(const StartupState(), effectBufferSize: buffered ? 8 : 0);

  final Duration confirmTimeout;

  @override
  void onInit() => emitSideEffect(ShowWelcomeEffect());

  Future<void> saveName(String name) => intent(SaveNameIntent(name));

  Future<void> askConfirmation() =>
      intent(AskConfirmationIntent(confirmTimeout));

  Future<void> triggerUnhandled() => intent(TriggerUnhandledIntent());
}
