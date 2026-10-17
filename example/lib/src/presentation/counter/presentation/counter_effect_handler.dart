import 'dart:async';

import 'package:counter/src/presentation/counter/effects/show_error_dialog_effect.dart';
import 'package:counter/src/presentation/counter/effects/show_info_effect.dart';
import 'package:counter/src/presentation/counter/effects/show_reject_operation.dart';
import 'package:counter/src/presentation/counter/effects/show_save_failure_effect.dart';
import 'package:counter/src/presentation/counter/effects/show_success_effect.dart';
import 'package:counter/src/presentation/counter/effects/show_warning_effect.dart';
import 'package:counter/src/presentation/counter/state/state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

/// Example effect handler demonstrating consistent error UX patterns
/// This handler shows different error severities with appropriate UI feedback
class CounterEffectHandler extends JSideEffectHandler<CounterState> {
  CounterEffectHandler(super.controller) {
    register<ShowRejectOperation>(_onShowError);
    register<ShowSaveFailureEffect>(_onSaveFailure);
    register<ShowSuccessEffect>(_onShowSuccess);
    register<ShowWarningEffect>(_onShowWarning);
    register<ShowInfoEffect>(_onShowInfo);
    register<ShowErrorDialogEffect>(_onShowErrorDialog);
  }

  /// Handles error snackbar with red background
  Future<void> _onShowError(
    ShowRejectOperation effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    _showErrorSnackBar(context, effect.message);
    effect.complete(true);
  }

  Future<void> _onSaveFailure(
    ShowSaveFailureEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    _showErrorSnackBar(context, effect.message);
    effect.complete(null);
  }

  /// Shows [snackBar] in place of whatever is on screen.
  ///
  /// `ScaffoldMessenger.showSnackBar` queues: each call waits for the previous
  /// SnackBar to leave, so repeated failures would pile up and replay one by
  /// one. Clearing first keeps only the latest message.
  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    _showSnackBar(
      context,
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        // No action: a SnackBar with an action persists on recent Flutter
        // versions and ignores this duration, but auto-dismisses on older ones.
        // Without it the 3 s duration applies everywhere.
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Handles success snackbar with green background
  Future<void> _onShowSuccess(
    ShowSuccessEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    _showSnackBar(
      context,
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                effect.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
    effect.complete(null);
  }

  /// Handles warning snackbar with orange background
  Future<void> _onShowWarning(
    ShowWarningEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    _showSnackBar(
      context,
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                effect.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
    effect.complete(null);
  }

  /// Handles info snackbar with blue background
  Future<void> _onShowInfo(
    ShowInfoEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    _showSnackBar(
      context,
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                effect.message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
    effect.complete(null);
  }

  /// Handles error dialog for critical errors
  Future<void> _onShowErrorDialog(
    ShowErrorDialogEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(effect.title)),
              ],
            ),
            content: Text(effect.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(effect.actionLabel ?? 'OK'),
              ),
            ],
          ),
    );
    effect.complete(result ?? false);
  }
}
