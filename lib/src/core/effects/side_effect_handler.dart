import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

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
/// - Exact-type handler registration.
/// - Unhandled strategies (warn, complete with error, throw).
///
/// Register each concrete effect type explicitly. Inheritance-based fallback
/// is not supported. A handler failure completes any pending result with the
/// original error and fails [handle] with that same error and stack trace.
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
    final handler = _handlers[effect.runtimeType];
    if (handler != null) {
      try {
        await handler(effect, controller, context);
      } catch (error, stackTrace) {
        _completeFailure(effect, error, stackTrace);
        rethrow;
      }

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

  void _completeFailure(JEffect effect, Object error, StackTrace stackTrace) {
    // The handler future (or warning for an absent handler) surfaces the failure.
    // Observing result prevents a second unhandled error for callers that only
    // await handle(), without changing the result seen by other awaiters.
    effect.result.ignore();
    if (!effect.isCompleted) effect.completeError(error, stackTrace);
  }

  void _handleUnhandled(JEffect effect) {
    final strategy = JEffectsConfig().unhandledStrategy;
    final isAwaitable = effect is! JFireAndForgetEffect;
    if (!isAwaitable) return;
    final error = StateError(
      'No handler registered for ${effect.runtimeType} (id=${effect.id}). '
      'Register a handler for this concrete effect type.',
    );

    if (strategy == UnhandledEffectStrategy.throwError) {
      _completeFailure(effect, error, StackTrace.current);
      throw error;
    }

    if (strategy != UnhandledEffectStrategy.warnOnly) {
      _completeFailure(effect, error, StackTrace.current);
      if (kDebugMode) debugPrint('⚠️ [JEffect] $error');
      return;
    }

    if (kDebugMode) {
      debugPrint('⚠️ [JEffect] Unhandled effect ${effect.runtimeType}');
    }
  }
}
