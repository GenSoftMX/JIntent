import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jintent/src/core/jcontroller.dart';
import 'package:jintent/src/core/jstate.dart';

// EffectHandler type definition
/// A function type that handles a specific effect type [E] with a given state [S].
/// It receives the effect, the controller for the state, and the current [BuildContext].
typedef EffectHandler<E extends JEffect, S extends JState> =
    Future<void> Function(
      E effect,
      JController<S> controller,
      BuildContext context,
    );

/// Base class representing a one-time side effect with an optional result.
abstract class JEffect<T> {
  final Completer<T> _completer = Completer<T>();

  /// Future that completes when the effect is handled.
  Future<T> get result => _completer.future;

  /// Completes the effect with a value.
  void complete(T value) => _completer.complete(value);

  /// Whether the effect has already been completed.
  bool get isCompleted => _completer.isCompleted;
}