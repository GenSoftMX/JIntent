import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';

/// State notifier that handles states and emits updates.
abstract class JController<T extends JState> extends StateNotifier<T>
    with JCommonsMixin {
  /// Constructor to initialize the state.
  JController(T initialState) : super(initialState);

  T get currentState => state;

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
  /// This method is used to process intents
  void intent(JIntent<T> intent) =>
      // Invoke the intent and update the state
      intent.invoke(this);
}
