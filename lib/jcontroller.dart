import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jintent/jeffect.dart';
import 'package:jintent/jstate.dart';
import 'package:state_notifier/state_notifier.dart';

/// Base controller for managing state and side effects in a reactive architecture.
///
/// `JController` extends `StateNotifier<T>` to provide controlled state management,
/// and introduces support for handling one-time UI effects through a side effect stream.
///
/// It is designed to work with [JState] and [JIntent], promoting a clean separation
/// of UI, state, and side-effect logic.
///
/// Example usage:
/// ```dart
/// class LoginController extends JController<LoginState> {
///   LoginController() : super(LoginState.initial());
///
///   Future<void> login(String user, String pass) async {
///     setState(state.copyWith(loading: true));
///     final success = await someLoginUseCase(user, pass);
///     if (!success) {
///       emitSideEffect(ShowLoginError(message: "Login failed"));
///     }
///     setState(state.copyWith(loading: false));
///   }
/// }
/// ```
abstract class JController<T extends JState> extends StateNotifier<T> {
  final _sideEffectController = StreamController<JEffect>.broadcast();

  /// Stream of side effects emitted by the controller.
  ///
  /// UI layers can subscribe to this stream to react to one-time effects,
  /// such as navigation, dialogs, snackbars, etc.
  Stream<JEffect> get sideEffects => _sideEffectController.stream;

  /// Returns the current state of type [T].
  T get currentState => state;

  /// Creates a new [JController] with the given initial state.
  ///
  /// Automatically calls [onInit] after construction.
  JController(T initialState) : super(initialState) {
    onInit();
  }

  /// Initialization lifecycle method.
  ///
  /// Override this method to set up initial subscriptions, data loading, etc.
  void onInit() {}

  /// Handles a given [JIntent] to update the state.
  ///
  /// Invokes the logic encapsulated in the intent and applies any state changes.
  Future<void> intent(JIntent<T> intent) => intent.invoke(this);

  /// Sets a new state of type [T] if different from the current state.
  ///
  /// If the new state is equal to the current state, no update is performed.
  void setState(T newState) {
    if (mounted) {
      if (currentState != newState) {
        state = newState;
        debugPrint('State updated.');
      } else {
        debugPrint('New state is equal to current state.');
      }
    } else {
      debugPrint('JController is no longer mounted.');
    }
  }

  /// Emits a one-time [JEffect] to the UI.
  ///
  /// This can be used for side effects like showing a dialog, toast, or navigation.
  void emitSideEffect(JEffect effect) {
    _sideEffectController.add(effect);
  }

  /// Emits a side effect and waits for the result.
  ///
  /// Used when a response from the UI is required, such as confirming an action.
  ///
  /// The UI must complete the effect using `effect.complete(value)`.
  Future<V> emitAndWaitSideEffect<V>(JEffect<V> effect) {
    emitSideEffect(effect);
    return effect.result;
  }

  @override
  void dispose() {
    _sideEffectController.close();
    super.dispose();
  }
}
