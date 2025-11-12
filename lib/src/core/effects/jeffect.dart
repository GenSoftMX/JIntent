import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:jintent/jintent.dart';
import 'package:jintent/src/core/effects/jeffect_config.dart';

/// Handler for a specific effect [E] with state [S].
/// Returns a Future that completes when the UI has finished processing the effect.
/// Note: DO NOT retain BuildContext after a prolonged await.
typedef EffectHandler<E extends JEffect, S extends JState> =
    Future<void> Function(
      E effect,
      JController<S> controller,
      BuildContext context,
    );

/// Marker for effects that can expose a UI category (analytics/devtools).
mixin JCategorizableEffect {
  String get category;
}

/// Base class representing a one-time side effect with an optional result.
///
/// Extensions:
/// - Provides an ID and timestamp for tracing.
/// - Allows completion with a value OR error.
/// - Idempotent completion (subsequent calls ignored).
abstract class JEffect<T> {
  final String id;
  final DateTime createdAt;
  final Completer<T> _completer = Completer<T>();

  JEffect()
    : id = (JEffectsConfig().idGenerator?.call()) ?? _defaultId(),
      createdAt = DateTime.now();

  static String _defaultId() =>
      'eff_${DateTime.now().microsecondsSinceEpoch}_${_randSuffix()}';
  static String _randSuffix() =>
      (DateTime.now().millisecondsSinceEpoch % 997).toRadixString(16);

  /// Future that completes when the effect is handled (or failed).
  Future<T> get result => _completer.future;

  /// Completes the effect with a value (idempotent).
  void complete(T value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }

  /// Completes the effect with an error (idempotent).
  void completeError(Object error, [StackTrace? st]) {
    if (!_completer.isCompleted) _completer.completeError(error, st);
  }

  /// Whether the effect has already been completed.
  bool get isCompleted => _completer.isCompleted;

  /// Returns a category (if any).
  String? get resolvedCategory {
    if (this is JCategorizableEffect) {
      return (this as JCategorizableEffect).category;
    }
    return JEffectsConfig().categoryResolver?.call(this);
  }

  @override
  String toString() =>
      'JEffect(id=$id,type=$runtimeType,completed=$isCompleted)';
}

/// Effect that is semánticamente "fire and forget" (no valor útil).
abstract class JFireAndForgetEffect extends JEffect<void> {}

/// Effect diseñado para retornar un valor de tipo T.
abstract class JResultEffect<T> extends JEffect<T> {}

/// Alias semántico para diálogos (normalmente devuelven un valor, ej. bool).
abstract class JDialogEffect<T> extends JResultEffect<T> {}
