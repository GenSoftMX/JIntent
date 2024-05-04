import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jintent/jprogress_dialog_manager_controller.dart';
import 'package:jintent/jnavigator_service.dart';

/// Commons module that contains shared utilities and functions.
///
/// This module provides a set of commonly used utilities, constants, and
/// helper functions that can be shared across different parts of the application.
///
/// Typical contents of this module might include:
/// - Utility functions for string manipulation.
/// - Constants used throughout the application.
/// - Common mixins or base classes for shared behavior.
///
/// By centralizing these common functionalities, the codebase can be
/// more maintainable and consistent.
mixin class JCommonsMixin {
  /// Returns the current instance of [GetIt] used for dependency injection.
  ///
  /// This property provides access to the global instance of `GetIt`, allowing you
  /// to retrieve registered dependencies throughout the application.
  GetIt get di => GetIt.I;

  /// Returns the current [BuildContext] using the [NavigationService].
  ///
  /// This allows easy access to the context for navigation and UI-related operations.
  ///
  BuildContext get context {
    final intentToGetContext =
        di<JNavigatorService>().key.currentState?.context;

    if (intentToGetContext == null) {
      throw Exception('context not found in [GetIt]');
    }

    return intentToGetContext;
  }

  /// Returns the [ProgressDialogManager] using the [JLocator] service locator.
  ///
  /// This allows easy access to show or hide progress dialogs.
  JProgressDialogManagerController get pd =>
      di<JProgressDialogManagerController>();
}
