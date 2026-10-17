import 'package:jintent/jintent.dart';

/// Global configuration for JEffect behavior.
class JEffectsConfig {
  static final JEffectsConfig _instance = JEffectsConfig._internal();
  factory JEffectsConfig() => _instance;
  JEffectsConfig._internal();

  /// Default timeout applied when using emitAndWaitSideEffect if none supplied.
  Duration? defaultTimeout;

  /// Strategy when an awaitable effect has no handler.
  UnhandledEffectStrategy unhandledStrategy =
      UnhandledEffectStrategy.warnAndCompleteError;

  /// Generates effect IDs; override for custom formats.
  String Function()? idGenerator;

  /// Resolves a category for an effect if the effect does not implement [JCategorizableEffect].
  String Function(JEffect effect)? categoryResolver;

  /// Restores every setting to its default value.
  ///
  /// The configuration is process-wide; call this in tests that change it so
  /// the changes cannot leak into other tests.
  void reset() {
    defaultTimeout = null;
    unhandledStrategy = UnhandledEffectStrategy.warnAndCompleteError;
    idGenerator = null;
    categoryResolver = null;
  }
}

/// Strategy for handling unhandled effects.
/// - `warnOnly`: Log a warning but do not complete the effect.
/// - `warnAndCompleteError`: Warn and complete the result with [StateError].
/// - `throwError`: Complete the result with [StateError] and fail the handler future.
enum UnhandledEffectStrategy {
  warnOnly,
  @Deprecated(
    'Use warnAndCompleteError. Missing handlers now complete with error.',
  )
  warnAndAutoComplete,
  throwError,
  warnAndCompleteError,
}
