import 'dart:async';
import 'package:flutter/material.dart';

/// A utility class for throttling actions to limit their execution frequency.
///
/// The `Throttler` class ensures that a given action is executed no more than
/// once within the specified [interval]. This is particularly useful for
/// scenarios like button presses or scroll events where frequent calls could
/// cause performance issues.
///
/// ### Example Usage
/// ```dart
/// final throttler = Throttler(Duration(seconds: 2));
///
/// void handleAction() {
///   print('Action executed');
/// }
///
/// // Example: Throttle button presses
/// ElevatedButton(
///   onPressed: () => throttler.call(handleAction),
///   child: Text('Throttle Action'),
/// );
/// ```
class JThrottler {
  /// Constructs a `Throttler` with the specified time [interval].
  ///
  /// The [interval] determines the minimum time that must elapse between
  /// successive executions of the throttled action.
  JThrottler(this.interval);

  /// The duration between successive allowed executions of the action.
  final Duration interval;

  /// Holds the reference to the most recent action to be executed.
  VoidCallback? _action;

  /// The timer managing the throttling interval.
  Timer? _timer;

  /// Executes the provided [action], adhering to the throttling interval.
  ///
  /// If no action is currently in progress, the [action] will execute immediately
  /// if [immediateCall] is `true` (default). Otherwise, the action will be executed
  /// after the throttling [interval].
  ///
  /// ### Parameters
  /// - `action`: The action to be throttled and executed.
  /// - `immediateCall`: If `true`, executes the action immediately if no timer is active.
  void call(VoidCallback action, {bool immediateCall = true}) {
    _action = action;

    if (_timer == null) {
      if (immediateCall) {
        _callAction();
      }

      _timer = Timer(interval, _callAction);
    }
  }

  /// Internal method to execute the stored action and reset the timer.
  void _callAction() {
    _action?.call();
    _action = null;
    _timer = null;
  }

  /// Resets the throttler, canceling any pending action and timer.
  ///
  /// Use this method to clear the current state of the throttler,
  /// ensuring no pending actions are executed.
  void reset() {
    _action = null;
    _timer = null;
  }
}
