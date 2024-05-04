import 'package:flutter/material.dart';
import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';
import 'package:state_notifier/state_notifier.dart';

/// Base controller class that manages application state and logic.
///
/// The `JController` class provides a foundation for state management
/// and controller logic in your application. It is responsible for maintaining
/// the state and providing methods to update the state in response to various
/// events and actions.
///
/// Key responsibilities of `JController` include:
/// - Managing the application state.
/// - Handling intents and updating state accordingly.
/// - Providing lifecycle methods like `onInit()` and `dispose()`.
///
/// Subclasses can override certain methods to implement specific logic
/// for different controllers, ensuring that each controller has a clear
/// responsibility and role within the application.
abstract class JController<T extends JState> extends StateNotifier<T>
    with JCommonsMixin {
  /// Constructor to initialize the state.
  JController(T initialState)
      : super(
          initialState,
        ) {
    onInit();
  }

  /// Returns the current state of type [T].
  ///
  /// This property provides the current state of the object or component.
  /// Use it to retrieve information or data that reflects the real-time state.
  ///
  /// You can use this property to check the current state or to trigger
  /// specific actions based on its value.
  T get currentState => state;

  /// Initialization method for the controller.
  ///
  /// This method is called once when the controller is created.
  /// It is used to set up the initial state of the controller,
  /// subscribe to events, configure services, or perform any
  /// necessary setup at the beginning of the controller's lifecycle.
  ///
  /// This method can be overridden by subclasses to implement
  /// their own initialization logic.
  ///
  /// Examples of usage for `onInit()`:
  /// - Subscribing to data providers or services.
  /// - Setting default values for the controller's state.
  /// - Registering listeners for events that affect the controller.
  ///
  /// Ensure that any resources used in `onInit()`
  /// are properly released when the controller is deactivated or removed.
  /// For this purpose, you can use a `dispose()` method or another
  /// mechanism to clean up resources when the controller's lifecycle ends.
  void onInit() {}

  /// Sets a new state of type [T].
  ///
  /// This function updates the state with the provided [newState].
  /// If the new state is different from the current state, it updates the state
  /// and logs that the state has been updated. If the new state is the same
  /// as the current state, it logs that there was no change.
  ///
  /// If the component is no longer mounted (already unmounted or disposed),
  /// it logs a message indicating that the controller has been unmounted.
  ///
  /// - [newState]: The new state to set. This should be of type [T].
  ///
  /// Logs information about the state update for debugging purposes.
  void setState(T newState) {
    if (mounted) {
      if (state != newState) {
        state = newState;
        debugPrint('state upsate');
      } else {
        debugPrint('new state is equal to new state');
      }
    } else {
      debugPrint('JController desmontado');
    }
  }

  /// Handles a [JIntent] and updates the state accordingly.
  ///
  /// This method processes a given [JIntent], a representation of an action or
  /// command, which may lead to a change in state. When this method is called,
  /// it triggers the [invoke] method on the [JIntent] and updates the component
  /// or object's state as a result.
  ///
  /// - [intent]: The intent to process. This should be a valid [JIntent] that
  ///   contains logic to update the state.
  ///
  /// This method is useful for implementing a command-based pattern, where
  /// changes in the state are driven by specific intents or actions.
  Future<void> intent(JIntent<T> intent) => intent.invoke(this);

  /// Cleans up resources and performs necessary teardown operations.
  ///
  /// This method is called when the controller is being disposed of, usually
  /// at the end of its lifecycle. It is crucial to override this method to
  /// ensure proper cleanup of resources, like unsubscribing from providers,
  /// removing listeners, or releasing references to large objects.
  ///
  /// When overriding this method, always call `super.dispose()` to ensure
  /// that the base class's disposal logic is also executed.
  ///
  /// Common cleanup tasks include:
  /// - Unsubscribing from event listeners or streams.
  /// - Releasing references to large objects or services.
  /// - Closing resources like file handles, database connections, or network sockets.
  ///
  /// **Important:** Failing to clean up resources can lead to memory leaks
  /// and other unpredictable behavior, so always ensure proper disposal.
  @override
  void dispose() {
    super.dispose();
  }
}
