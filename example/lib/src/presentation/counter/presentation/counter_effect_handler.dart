import 'dart:async';

import 'package:counter/src/presentation/counter/states/state.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

/// Example effect handler demonstrating consistent error UX patterns
/// This handler shows different error severities with appropriate UI feedback
class CounterEffectHandler extends JSideEffectHandler<CounterState> {
  CounterEffectHandler(super.controller) {
    register<ShowRejectOperation>(_onShowError);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
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
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    effect.complete(true);
  }

  /// Handles success snackbar with green background
  Future<void> _onShowSuccess(
    ShowSuccessEffect effect,
    JController<CounterState> controller,
    BuildContext context,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
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
    ScaffoldMessenger.of(context).showSnackBar(
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
    ScaffoldMessenger.of(context).showSnackBar(
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
      builder: (context) => AlertDialog(
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

/// Error severity levels for consistent UX
enum ErrorSeverity {
  info,      // Informational messages (blue)
  warning,   // Warning messages (orange)
  error,     // Error messages (red)
  critical,  // Critical errors requiring dialog
}

// ============================================================================
// Effect Definitions
// ============================================================================

/// Base error effect - shows error snackbar (backward compatible)
class ShowRejectOperation extends JEffect<bool> with JCategorizableEffect {
  final String message;

  ShowRejectOperation({required this.message});

  @override
  String get category => 'error';
}

/// Success feedback effect - shows green snackbar
class ShowSuccessEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;

  ShowSuccessEffect({required this.message});

  @override
  String get category => 'success';
}

/// Warning feedback effect - shows orange snackbar
class ShowWarningEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;

  ShowWarningEffect({required this.message});

  @override
  String get category => 'warning';
}

/// Info feedback effect - shows blue snackbar
class ShowInfoEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;

  ShowInfoEffect({required this.message});

  @override
  String get category => 'info';
}

/// Critical error dialog effect - shows dialog for important errors
class ShowErrorDialogEffect extends JDialogEffect<bool> with JCategorizableEffect {
  final String title;
  final String message;
  final String? actionLabel;

  ShowErrorDialogEffect({
    required this.title,
    required this.message,
    this.actionLabel,
  });

  @override
  String get category => 'error_dialog';
}
