import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/src/core/effects/jeffect_config.dart';

/// Type alias for internal handler function signature.
/// This is used to map effects to their handlers.
/// It takes an effect, a controller, and a BuildContext, and returns a Future.
typedef _InternalHandler =
    Future<void> Function(
      JEffect effect,
      JController controller,
      BuildContext context,
    );

/// Base class for handling side effects in a [JController].
/// Enhanced to support:
/// - Hierarchical handler resolution (superclass fallback).
/// - Unhandled strategies (warn, auto-complete, throw).
abstract class JSideEffectHandler<T extends JState> {
  late final JController<T> controller;

  JSideEffectHandler(this.controller);

  final _handlers = <Type, _InternalHandler>{};

  void register<E extends JEffect>(EffectHandler<E, T> handler) {
    _handlers[E] =
        (effect, controller, context) =>
            handler(effect as E, controller as JController<T>, context);
  }

  Future<void> handle(
    JEffect effect,
    JController<T> controller,
    BuildContext context,
  ) async {
    final handler = _resolveHandler(effect);
    if (handler != null) {
      await handler(effect, controller, context);

      if (kDebugMode &&
          !effect.isCompleted &&
          effect is! JFireAndForgetEffect) {
        debugPrint(
          '⚠️ [JEffect] Effect "${effect.runtimeType}" completed handler path WITHOUT completing result.\n'
          'If this effect is awaited, caller will hang. Call effect.complete(value) or effect.completeError().',
        );
      }
    } else {
      _handleUnhandled(effect);
    }
  }

  _InternalHandler? _resolveHandler(JEffect effect) {
    // Exact type first
    final exact = _handlers[effect.runtimeType];
    if (exact != null) return exact;

    // Walk superclass chain
    Type? current = effect.runtimeType;
    final visited = <Type>{};

    while (current != null) {
      if (visited.contains(current)) break;
      visited.add(current);

      final superType = _findSuperclass(current);
      if (superType != null) {
        final candidate = _handlers[superType];
        if (candidate != null) return candidate;
        current = superType;
      } else {
        break;
      }
    }
    return null;
  }

  // NOTE: Reflection is limited in Dart (no mirrors in Flutter). This is a placeholder
  // for a manual mapping mechanism if you want to register explicit hierarchies.
  // Alternative: Require additional manual registration: registerForHierarchy<Base, Derived>.
  Type? _findSuperclass(Type t) {
    // No generic runtime support: can be implemented with a manual map if desired.
    return null;
  }

  void _handleUnhandled(JEffect effect) {
    final strategy = JEffectsConfig().unhandledStrategy;
    final isAwaitable = effect is! JFireAndForgetEffect;

    if (strategy == UnhandledEffectStrategy.throwError && isAwaitable) {
      effect.completeError(
        StateError('No handler registered for ${effect.runtimeType}'),
      );
      throw StateError(
        '[JEffect] No handler registered for ${effect.runtimeType}',
      );
    }

    if (strategy == UnhandledEffectStrategy.warnAndAutoComplete &&
        isAwaitable) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ [JEffect] Unhandled awaitable effect ${effect.runtimeType} → auto-completing with null.',
        );
      }
      // ignore: null_check_on_nullable_type_parameter
      effect.complete(null as dynamic);
      return;
    }

    if (strategy == UnhandledEffectStrategy.warnOnly) {
      if (kDebugMode) {
        debugPrint('⚠️ [JEffect] Unhandled effect ${effect.runtimeType}');
      }
    }
  }
}
