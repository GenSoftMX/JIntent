import 'package:flutter/foundation.dart';
import 'package:jintent/src/core/core.dart';

/// Represents an action or event that can modify application state.
///
/// The `JIntent` class is an abstraction that encapsulates a specific
/// action or event that may result in a change to the application's state.
/// This concept helps to structure the application by clearly defining
/// the different actions and how they affect the state.
///
/// When implemented, an `JIntent` typically contains:
/// - A method to invoke the action (`run()`).
/// - Any parameters or dependencies required to perform the action.
///
/// Intents are used in conjunction with controllers to manage
/// the logic and state changes within the application.
abstract class JIntent<T extends JState> {
  late JController<T> _controller;

  /// DO NOT override this method.
  /// It is used internally
  /// Public method to execute the intent.
  Future<void> run(JController<T> controller) => invoke(controller);

  /// DO NOT override this method.
  /// It is used internally to wire the controller before executing the logic.
  /// Override [onInvoke] instead.  @protected
  Future<void> invoke(JController<T> controller) async {
    _controller = controller;
    await onInvoke();
  }

  /// Contains the core logic of the intent.
  ///
  /// Override this method to implement the behavior that should be executed
  /// when the intent is dispatched. This is where you define how the intent
  /// interacts with the controller, updates the state, or emits side effects.
  ///
  /// This method is called internally by the framework and should not be
  /// invoked manually. Use [update], [emitSideEffect], or [emitAndWaitSideEffect]
  /// inside this method to interact with the syste  @protected
  @visibleForOverriding
  Future<void> onInvoke();

  /// Provides easy access to the current state managed by the controller.
  T get state => _controller.currentState;

  /// Access the current controller instance.
  JController<T> get controller => _controller;
}
