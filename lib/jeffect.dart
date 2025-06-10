import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jintent/jstate.dart';

/// Base class representing a one-time UI side effect.
///
/// A `JEffect` encapsulates transient operations that the UI should handle,
/// such as showing a dialog, navigating to another screen, displaying a
/// snackbar/toast, or triggering animations.
///
/// These actions do not alter the main application state and are meant to be
/// handled only once by the UI layer.
///
/// [V] represents the type of value that may be returned from the UI
/// when the side effect completes (e.g., user confirmed/canceled a dialog).
///
/// Example:
/// ```dart
/// class ShowDialogEffect extends JEffect<bool> {
///   final String title;
///
///   ShowDialogEffect(this.title);
/// }
/// ```
abstract class JEffect<V> {
  final Completer<V> _completer = Completer<V>();

  /// A future that completes when the UI has handled the side effect.
  ///
  /// Use this to await results from side effects, such as a confirmation dialog.
  Future<V> get result => _completer.future;

  /// Completes the side effect with a value.
  ///
  /// Should be called by the UI once the effect is handled.
  void complete(V value) => _completer.complete(value);
}

/// Handles side effects emitted by a [JController].
///
/// [JSideEffectHandler] provides a mechanism to map side effect types to their
/// corresponding handling logic. It connects the controller and the current UI
/// [BuildContext] to process effects in a centralized, maintainable way.
///
/// Typically used within a widget to listen to the controller’s sideEffects stream.
///
/// Example usage:
/// ```dart
/// final handler = MyEffectHandler(controller, context);
/// handler.register<ShowDialogEffect>((effect, controller) async {
///   final confirmed = await showDialog(...);
///   effect.complete(confirmed);
/// });
/// ```
abstract class JSideEffectHandler<T extends JState> {
  /// Reference to the controller emitting the side effects.
  late final JController<T> controller;

  /// Reference to the UI context for handling effects.
  late final BuildContext context;

  JSideEffectHandler(this.controller, this.context);

  final _handlers = <Type, Future<void> Function(JEffect, JController<T>)>{};

  /// Registers a handler for a specific type of [JEffect].
  ///
  /// The handler function receives both the effect instance and the controller.
  /// Use this to define how each specific effect should be handled in the UI.
  void register<E extends JEffect>(
    Future<void> Function(E effect, JController<T> controller) handler,
  ) {
    _handlers[E] = (effect, controller) => handler(effect as E, controller);
  }

  /// Handles a given effect by invoking its corresponding registered handler.
  ///
  /// If no handler is registered for the effect's type, a warning is logged.
  Future<void> handle(JEffect effect, JController<T> controller) async {
    final handler = _handlers[effect.runtimeType];
    if (handler != null) {
      await handler(effect, controller);
    } else {
      debugPrint("No handler registered for ${effect.runtimeType}");
    }
  }
}
