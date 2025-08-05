import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jintent/src/core/effects/jeffect.dart';
import 'package:jintent/src/core/jintent.dart';
import 'package:jintent/src/devtools/jobserver.dart';
import 'package:jintent/src/core/jstate.dart';
import 'package:jintent/src/extensions/logging_dispatcher.dart';
import 'package:state_notifier/state_notifier.dart';

/// Base controller for managing state and side effects in a reactive architecture.
///
/// Extends [StateNotifier<T>] to provide controlled state updates and exposes
/// a [sideEffects] stream for one-time UI events.
///
/// Use [intent] to dispatch intents which encapsulate business logic,
/// [update] to safely mutate the state using reducers,
/// and [emitSideEffect] or [emitAndWaitSideEffect] for UI events like dialogs or navigation.
///
/// Implements lifecycle hook [onInit] for initialization logic.
///
/// Tracks state changes and side effects via [JObserver] for debugging and tooling.
abstract class JController<T extends JState> extends StateNotifier<T> {
  /// Dispatcher responsible for handling the execution of [JIntent]s.
  ///
  /// This field holds an instance of [JIntentDispatcher], which abstracts
  /// how intents are dispatched and executed. By default, it uses
  /// [JDefaultIntentDispatcher], but can be replaced with a custom
  /// implementation (e.g., for logging or analytics).
  ///
  /// It allows decoupling the dispatching mechanism from the controller logic.
  final JIntentDispatcher _dispatcher;

  /// Stream of side effects emitted by the controller.
  ///
  /// UI layers can subscribe to this stream to react to one-time effects,
  /// such as navigation, dialogs, snackbars, etc.
  final _sideEffectController = StreamController<JEffect>.broadcast();

  /// A broadcast stream of side effects emitted by the controller.
  Stream<JEffect> get sideEffects => _sideEffectController.stream;

  /// Returns the current state of type [T].
  T get currentState => state;

  /// Creates a new [JController] with the given initial state.
  ///
  /// Automatically calls [onInit] after construction.
  JController(T initialState, {JIntentDispatcher? dispatcher})
    : _dispatcher = dispatcher ?? JDefaultIntentDispatcher(),
      super(initialState) {
    onInit();
  }

  /// Initialization lifecycle method.
  ///
  /// Override this method to set up initial subscriptions, data loading, etc.
  void onInit();

  /// Handles a given [JIntent] to update the state.
  ///
  /// Invokes the logic encapsulated in the intent and applies any state changes.
  Future<void> intent(JIntent<T> intent) {
    return _dispatcher.dispatch(intent, this);
  }

  /// Sets a new state of type [T] if different from the current state.
  ///
  /// If the new state is equal to the current state, no update is performed.
  ///
  @Deprecated(
    'setState is deprecated. Use update((state) => newState) instead for a safer, reactive state update.',
  )
  void setState(T newState, {JIntent? origin}) {
    if (!mounted) {
      debugPrint('JController is no longer mounted.');
      return;
    }

      final prev = currentState;

      state = newState;

      JObserver.notifyStateChanged(prev, newState);

      debugPrint('State updated.');
  }

  /// Updates the current state by applying the given [reducer] function.
  ///
  /// The [reducer] receives the current state and returns a new modified state.
  /// After computing the new state, it calls SetState to update the state,
  /// optionally associating the update with an originating [JIntent].
  ///
  /// - [reducer]: A function that takes the current state and returns a new state.
  /// - [origin]: (Optional) The intent that triggered this state update.
  void update(T Function(T state) reducer, {JIntent? origin}) {
    if (!mounted) {
      debugPrint('JController is no longer mounted.');
      return;
    }
    final newState = reducer(currentState);

      final prev = currentState;

      state = newState;

      JObserver.notifyStateChanged(prev, newState, origin);
      debugPrint('State updated.');
  }

  /// Emits a one-time [JEffect] to the UI.
  ///
  /// This can be used for side effects like showing a dialog, toast, or navigation.
  void emitSideEffect(JEffect effect) {
    _sideEffectController.add(effect);
    JObserver.notifyEffectEmitted(effect);
  }

  /// Emits a side effect and waits for the result.
  ///
  /// Used when a response from the UI is required, such as confirming an action.
  ///
  /// The UI must complete the effect using `effect.complete(value)`.
  Future<V> emitAndWaitSideEffect<V>(JEffect<V> effect) {
    emitSideEffect(effect);
    JObserver.notifyEffectEmitted(effect);
    return effect.result;
  }

  @override
  void dispose() {
    _sideEffectController.close();
    super.dispose();
  }
}
