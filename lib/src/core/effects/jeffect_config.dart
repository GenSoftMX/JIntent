import 'package:jintent/jintent.dart';

/// Global configuration for JEffect behavior.
class JEffectsConfig {
  static final JEffectsConfig _instance = JEffectsConfig._internal();
  factory JEffectsConfig() => _instance;
  JEffectsConfig._internal();

  /// Default timeout applied when using emitAndWaitSideEffect if none supplied.
  Duration? defaultTimeout;

  /// Strategy when an awaitable effect has no handler.
  UnhandledEffectStrategy unhandledStrategy = UnhandledEffectStrategy.warnAndAutoComplete;

  /// Generates effect IDs; override for custom formats.
  String Function()? idGenerator;

  /// Resolves a category for an effect if the effect does not implement [JCategorizableEffect].
  String Function(JEffect effect)? categoryResolver;
}

/// Strategy for handling unhandled effects.
/// - `warnOnly`: Log a warning but do not complete the effect.
/// - `warnAndAutoComplete`: Log a warning and auto-complete the effect with null.
/// - `throwError`: Log a warning and throw an error for unhandled awaitable effects.
enum UnhandledEffectStrategy {
  warnOnly,
  warnAndAutoComplete,
  throwError,
}