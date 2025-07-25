import 'package:flutter/foundation.dart';

/// Function signature for a global error logger.
typedef ErrorLogger = void Function(Object error);

/// Global configuration for error logging.
class EitherConfig {
  /// Optional global error logger for when a Left is created.
  static ErrorLogger? errorLogger;

  /// Sets the global error logger.
  static void configureLogger(ErrorLogger logger) {
    errorLogger = logger;
  }
}

/// Abstract base class for Either.
/// Represents a value of one of two possible types (Left or Right).
abstract class Either<L, R> {
  /// Applies `leftFn` if this is a [Left], or `rightFn` if this is a [Right].
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn);
}

/// Represents a failure or error case.
class Left<L, R> extends Either<L, R> {
  final L _value;

  /// Creates a Left with the given value.
  /// If [EitherConfig.errorLogger] is set and in debug mode, logs the error.
  Left(this._value) {
    if (kDebugMode && EitherConfig.errorLogger != null) {
      EitherConfig.errorLogger!(_value as Object);
    }
  }

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) {
    return leftFn(_value);
  }
}

/// Represents a success case.
class Right<L, R> extends Either<L, R> {
  final R _value;

  /// Creates a Right with the given value.
  Right(this._value);

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) {
    return rightFn(_value);
  }
}

/// Useful extensions for working with Either.
extension EitherExtensions<L, R> on Either<L, R> {
  /// Returns `true` if this is a [Left].
  bool get isLeft => this is Left<L, R>;

  /// Returns `true` if this is a [Right].
  bool get isRight => this is Right<L, R>;

  /// Returns the Left value if present, otherwise `null`.
  L? get left => this is Left<L, R> ? (this as Left<L, R>)._value : null;

  /// Returns the Right value if present, otherwise `null`.
  R? get right => this is Right<L, R> ? (this as Right<L, R>)._value : null;
}
