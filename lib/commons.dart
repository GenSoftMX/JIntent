import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jintent/jprogress_dialog_manager_controller.dart';
import 'package:jintent/jnavigator_service.dart';

/// Mixin providing convenient access to common functionalities in Flutter.
mixin class JCommonsMixin {
  /// Returns the current [BuildContext] using the [NavigationService].
  ///
  /// This allows easy access to the context for navigation and UI-related operations.
  ///
  BuildContext get context {
    final intentToGetContext =
       getIt<JNavigatorService>().key.currentState?.context;

    throwIf(
      intentToGetContext == null,
      Exception('context not found in [JCommonsMixin]'),
    );

    return intentToGetContext!;
  }

  /// Returns the [ProgressDialogManager] using the [GetIt] service locator.
  ///
  /// This allows easy access to show or hide progress dialogs.
  JProgressDialogManagerController get pd =>
      getIt<JProgressDialogManagerController>();

  GetIt get getIt => GetIt.I;
}
