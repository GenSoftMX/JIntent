import 'package:counter/src/demos/shared/effect_dialog.dart';
import 'package:counter/src/demos/startup_effects/effects/confirm_effect.dart';
import 'package:counter/src/demos/startup_effects/effects/show_welcome_effect.dart';
import 'package:counter/src/demos/startup_effects/state/startup_state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

class StartupEffectHandler extends JSideEffectHandler<StartupState> {
  StartupEffectHandler(super.controller) {
    register<ShowWelcomeEffect>(_welcome);
    register<ConfirmEffect>(_confirm);
    // UnregisteredEffect is intentionally not registered.
  }

  Future<void> _welcome(
    ShowWelcomeEffect effect,
    JController<StartupState> controller,
    BuildContext context,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Welcome! This effect was emitted in onInit.'),
      ),
    );
    effect.complete(null);
  }

  Future<void> _confirm(
    ConfirmEffect effect,
    JController<StartupState> controller,
    BuildContext context,
  ) async {
    final answer = await showEffectDialog<bool>(
      context: context,
      effect: effect,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(effect.question),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
    effect.complete(answer ?? false);
  }
}
