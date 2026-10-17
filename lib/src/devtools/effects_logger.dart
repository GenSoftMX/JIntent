import 'package:flutter/foundation.dart';
import 'package:jintent/jintent.dart';

/// Logger for JEffects, providing debug output for emitted and completed effects.
/// This is useful for development and debugging purposes, especially when
/// tracking the flow of effects in the application.
/// To enable logging, call [JEffectsLogger.attach] during app initialization.
class JEffectsLogger {
  static void logEmitted(JEffect effect) {
    if (!kDebugMode) return;
    debugPrint(
      '[Effect][emit] id=${effect.id} type=${effect.runtimeType} category=${effect.resolvedCategory}',
    );
  }

  static void logCompleted(JEffect effect) {
    if (!kDebugMode) return;
    debugPrint('[Effect][done] id=${effect.id} type=${effect.runtimeType}');
  }

  static final _observer = _EffectsLoggerObserver();

  /// Logs every emitted effect. Registers an observer that coexists with
  /// others; calling it again has no additional effect. The returned function
  /// unregisters it.
  static void Function() attach() => JObserver.addObserver(_observer);
}

class _EffectsLoggerObserver extends JObserverDelegate {
  @override
  void onEffectEmitted(JEffect effect) => JEffectsLogger.logEmitted(effect);
}
