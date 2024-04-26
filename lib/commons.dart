import 'package:flutter/material.dart';
import 'package:jintent/jprogress_dialog_manager_controller.dart';
import 'package:jintent/jnavigator_service.dart';

/// Mixin providing convenient access to common functionalities in Flutter.
mixin class JCommonsMixin {
  bool _loaded = false;
  late JLocator di;

  /// Set current [JLocator] using to find dependences;
  ///
  /// This allows easy access to dependences from some injector package like provider or GetIt
  ///
  setLocator({required JLocator locator}) {
    if (!_loaded) {
      di = locator;
      _loaded = true;
    }
  }

  /// Returns the current [BuildContext] using the [NavigationService].
  ///
  /// This allows easy access to the context for navigation and UI-related operations.
  ///
  BuildContext get context {
    final intentToGetContext =
        di<JNavigatorService>().key.currentState?.context;

    if (intentToGetContext == null) {
      throw Exception('context not found in [JCommonsMixin]');
    }

    return intentToGetContext;
  }

  /// Returns the [ProgressDialogManager] using the [JLocator] service locator.
  ///
  /// This allows easy access to show or hide progress dialogs.
  JProgressDialogManagerController get pd =>
      di<JProgressDialogManagerController>();
}

typedef JLocator = T Function<T>();
