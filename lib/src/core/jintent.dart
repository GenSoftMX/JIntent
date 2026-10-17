import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jintent/src/core/core.dart';
import 'package:jintent/src/devtools/jobserver.dart';

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
  static const _currentIntentKey = #jintent.currentIntent;

  /// The intent whose [onInvoke] is executing in the current zone, or `null`.
  ///
  /// [invoke] runs [onInvoke] in a zone carrying the intent, and zones follow
  /// `await`s, timers and stream callbacks created inside it. A
  /// [JController.update] without an explicit `origin` uses this value (when it
  /// belongs to that controller), so state updates are attributed to their
  /// intent and respect [isCancelled] without extra arguments.
  static JIntent? get current => Zone.current[_currentIntentKey] as JIntent?;

  JController<T>? _controller;
  bool _isRunning = false;
  bool _isCancelled = false;

  /// Executes the intent. Not overridable; override [onInvoke] instead.
  @nonVirtual
  Future<void> run(JController<T> controller) => invoke(controller);

  /// Wires the controller before executing the logic. Not overridable;
  /// override [onInvoke] instead. An instance can be reused after completion,
  /// but overlapping invocations fail with [StateError] before rebinding it.
  /// Invoking against a disposed controller also fails with [StateError].
  @nonVirtual
  Future<void> invoke(JController<T> controller) async {
    if (_isRunning) {
      throw StateError('$runtimeType is already running.');
    }
    if (!controller.mounted) {
      throw StateError('Cannot invoke $runtimeType on a disposed controller.');
    }
    _isRunning = true;
    _isCancelled = false;
    _controller = controller;
    try {
      JObserver.notifyIntentStarted(this);
      await runZoned(onInvoke, zoneValues: {_currentIntentKey: this});
    } catch (error, stackTrace) {
      JObserver.notifyIntentFailed(this, error, stackTrace);
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  /// Contains the core logic of the intent.
  ///
  /// Override this method to implement the behavior that should be executed
  /// when the intent is dispatched. This is where you define how the intent
  /// interacts with the controller, updates the state, or emits side effects.
  ///
  /// This method is called internally by the framework and should not be
  /// invoked manually. Use [update], [emitSideEffect], or [emitAndWaitSideEffect]
  /// inside this method to interact with the system.
  ///
  /// Disposal does not interrupt an awaited service call. Use that service's
  /// cancellation API when available, and check `controller.mounted` after
  /// asynchronous gaps before starting further work or using disposed state.
  @visibleForOverriding
  Future<void> onInvoke();

  /// Whether cancellation was requested for the current execution.
  ///
  /// Cancellation is cooperative: [onInvoke] is never interrupted. Check this
  /// flag after asynchronous gaps and stop early. While it is `true`,
  /// [JController.update] ignores state updates made by this intent, either
  /// with an explicit `origin` or from code running inside [onInvoke] (see
  /// [current]), so a superseded execution cannot overwrite newer state. Work
  /// scheduled outside that zone is not attributed to the intent. Effects are
  /// not filtered. The flag resets when the intent is invoked again.
  bool get isCancelled => _isCancelled;

  /// Requests cooperative cancellation of the execution in progress.
  ///
  /// Has no effect when the intent is not running. See [isCancelled].
  void cancel() {
    if (_isRunning) _isCancelled = true;
  }

  /// Provides easy access to the current state managed by the controller.
  T get state => controller.currentState;

  /// The controller bound by the most recent invocation.
  ///
  /// Throws [StateError] before the first invocation. Await work started in
  /// [onInvoke] before returning so it cannot outlive this execution's binding.
  JController<T> get controller =>
      _controller ??
      (throw StateError(
        '$runtimeType has not been invoked with a controller.',
      ));
}

/// Whether [intent] is executing [JIntent.onInvoke] right now, through any
/// dispatcher or direct call.
///
/// Internal to the package: it is hidden from the public barrels so `JIntent`
/// gains no extra member that subclasses could collide with. Dispatchers use it
/// to reject an overlapping invocation before touching other intents.
bool isIntentRunning(JIntent intent) => intent._isRunning;
