library jintent;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

/// Abstract class representing the state of a component.
@immutable
abstract class JState {}

/// State notifier that handles states and emits updates.
abstract class JController<T extends JState> extends StateNotifier<T>
    with JCommonsMixin {
  /// Constructor to initialize the state.
  JController(T initialState) : super(initialState);

  /// Function to set a new state[JState]
  void setState(T newState) {
    if (mounted) {
      state = newState;
    } else {
      debugPrint('unmonted JController');
    }
  }

  /// Handles an [JIntent] and updates the state accordingly.
  ///
  /// This method is used to process intents and update the state based on the
  ///
  /// result of invoking the intent.
  void intent(JIntent<T> intent) async {
    // Invoke the intent and update the state
    await intent.invoke(state).then((newState) {
      setState(newState);
    });
  }
}

/// Abstract class representing an intent that can modify the state of the application.
@immutable
abstract class JIntent<T extends JState> with JCommonsMixin {
  /// Invokes the intent, potentially modifying the provided state.
  ///
  /// This method is used to execute the intent, perform logic, and potentially
  ///
  /// modify the provided state.
  Future<T> invoke(T state);
}

/// Mixin providing convenient access to common functionalities in Flutter.
mixin JCommonsMixin {
  /// Returns the current [BuildContext] using the [NavigationService].
  ///
  /// This allows easy access to the context for navigation and UI-related operations.
  BuildContext get context {
    final intentToGetContext =
        GetIt.I.get<JNavigatorService>().key.currentState?.context;

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
      GetIt.I.get<JProgressDialogManagerController>();

  /// Returns the [ProviderContainer] using the [GetIt] service locator.
  ///
  /// This provides access to the ProviderContainer for managing state and providers.
  ProviderContainer get ref => GetIt.I.get<ProviderContainer>();

  /// Global definition of common navigation routes
  JNavegatorRoutesController get goTo =>
      GetIt.I.get<JNavegatorRoutesController>();
}

abstract class JNavegatorRoutesController {}

abstract class JProgressDialogManagerController<T> {
  Future<T> show({String? msg});
  Future<T> hide();
}

class JNavigatorService {
  // Private constructor to prevent instantiation from outside
  JNavigatorService._privateConstructor();

  // Instance of the singleton
  static final JNavigatorService _instance =
      JNavigatorService._privateConstructor();

  // Getter to access the singleton instance
  static JNavigatorService get instance => _instance;

  // GlobalKey for the navigator state
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  BuildContext get context => key.currentState!.context;
}
