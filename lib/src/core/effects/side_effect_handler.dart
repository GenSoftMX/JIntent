import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

/// Base class for handling side effects in a [JController].
/// This class allows you to register handlers for specific effect types
/// and provides a method to handle effects when they are emitted.
abstract class JSideEffectHandler<T extends JState> {
  late final JController<T> controller;

  JSideEffectHandler(this.controller);

  final _handlers = <Type, EffectHandler<JEffect, T>>{};

  /// Registers a handler for a specific effect type.
  ///
  /// The handler receives the current [BuildContext].
  /// **Do not use [context] after an 'await' or async gap!**
  /// Use it only for immediate UI actions (dialogs, navigation, etc.).
  void register<E extends JEffect>(EffectHandler<E, T> handler) {
    _handlers[E] =
        (effect, controller, context) =>
            handler(effect as E, controller, context);
  }

  /// Handles the given effect by invoking its registered handler.
  Future<void> handle(
    JEffect effect,
    JController<T> controller,
    BuildContext context,
  ) async {
    final handler = _handlers[effect.runtimeType];
    if (handler != null) {
      await handler(effect, controller, context);

      // Check if effect expects result and was not completed
      if (kDebugMode && !effect.isCompleted) {
        debugPrint(
          '⚠️ [JEffect] WARNING: Effect "${effect.runtimeType}" was emitted but not completed.\n'
          '💡 Make sure to call `effect.complete(value)` inside its handler to avoid hanging the caller.\n'
          '🧩 Example:\n'
          '🧩 await dialog.then((result) => effect.complete(result));',
        );
      }
    } else {
      debugPrint(
        "⚠️ [JEffect] WARNING: No handler registered for ${effect.runtimeType}",
      );
    }
  }
}
