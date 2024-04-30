import 'package:flutter/material.dart';
import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';
import 'package:state_notifier/state_notifier.dart';

/// State notifier that handles states and emits updates.
abstract class JController<T extends JState> extends StateNotifier<T>
    with JCommonsMixin {
  /// Constructor to initialize the state.
  JController(T initialState)
      : super(
          initialState,
        );

  /// Returns the current state of type [T].
  ///
  /// This property provides the current state of the object or component.
  /// Use it to retrieve information or data that reflects the real-time state.
  ///
  /// You can use this property to check the current state or to trigger
  /// specific actions based on its value.
  T get currentState => state;

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
  Future<void> intent(JIntent<T> intent) =>
      // Invoke the intent and update the state
      intent.invoke(this);
}
