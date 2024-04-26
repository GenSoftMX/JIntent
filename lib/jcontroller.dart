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

  T get currentState => state;

  /// Function to set a new state[JState]
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

  /// Handles an [JIntent] and updates the state accordingly.
  ///
  /// This method is used to process intents
  void intent(JIntent<T> intent) =>
      // Invoke the intent and update the state
      intent.invoke(this);
}
