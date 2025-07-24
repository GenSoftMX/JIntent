import 'package:jintent/jintent.dart';

/// Provides convenience methods for working with [JController] inside [JIntent]s.
///
/// This mixin simplifies interaction with the controller by automatically
/// using `this` intent as the origin for actions such as state updates
/// or side effect emissions.
///
/// Only classes that extend [JIntent] can use this mixin.
///
/// Example usage:
/// ```dart
/// class IncrementIntent extends JIntent<CounterState>
///     with JIntentMeta, JIntentHelpers<CounterState> {
///
///   @override
///   String get type => 'counter';
///
///   @override
///   Future<void> invoke(JController<CounterState> controller) async {
///     update(controller, (state) => state.copyWith(value: state.value + 1));
///   }
/// }
/// ```
mixin JIntentHelpers<T extends JState> on JIntent<T> {
  /// Updates the controller's state using the provided [reducer] function.
  ///
  /// Automatically sets `this` intent as the `origin` to enable intent tracking.
  void update(T Function(T state) reducer) {
    controller.update(reducer, origin: this);
  }

  /// Emits a one-time UI side effect from this intent.
  ///
  /// Use this for effects such as navigation, toasts, or dialogs.
  void emitSideEffect(JEffect effect) {
    controller.emitSideEffect(effect);
  }

  /// Emits a UI side effect and waits for a result.
  ///
  /// This is useful for confirming actions or waiting for user input.
  /// The [JEffect] should be completed by the UI using `complete(result)`.
  Future<V> emitAndWaitSideEffect<V>(JEffect<V> effect) {
    return controller.emitAndWaitSideEffect(effect);
  }
}