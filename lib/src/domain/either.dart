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

/// Represents a value of one of two possible types, [Left] or [Right].
///
/// The hierarchy is sealed: `switch` expressions over an [Either] are checked
/// for exhaustiveness and can destructure the held value.
///
/// ```dart
/// final message = switch (result) {
///   Left(:final value) => 'Failed: $value',
///   Right(:final value) => 'Got $value',
/// };
/// ```
sealed class Either<L, R> {
  const Either();

  /// Applies `leftFn` if this is a [Left], or `rightFn` if this is a [Right].
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn);
}

/// Represents a failure or error case.
///
/// Two [Left]s are equal when they have exactly the same runtime type
/// (including type arguments) and equal [value]s, so `==` is symmetric:
/// `Left<String, int>('x')` never equals `Left<String, num>('x')`.
final class Left<L, R> extends Either<L, R> {
  /// The failure held by this [Left].
  final L value;

  /// Creates a Left with the given value.
  /// If [EitherConfig.errorLogger] is set and in debug mode, logs a non-null
  /// error value.
  Left(this.value) {
    final logger = EitherConfig.errorLogger;
    if (kDebugMode && logger != null) {
      if (value case final Object error) logger(error);
    }
  }

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) {
    return leftFn(value);
  }

  @override
  bool operator ==(Object other) =>
      other is Left && other.runtimeType == runtimeType && other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Left($value)';
}

/// Represents a success case.
///
/// Two [Right]s are equal when they have exactly the same runtime type
/// (including type arguments) and equal [value]s, so `==` is symmetric.
final class Right<L, R> extends Either<L, R> {
  /// The success value held by this [Right].
  final R value;

  /// Creates a Right with the given value.
  const Right(this.value);

  @override
  T fold<T>(T Function(L l) leftFn, T Function(R r) rightFn) {
    return rightFn(value);
  }

  @override
  bool operator ==(Object other) =>
      other is Right &&
      other.runtimeType == runtimeType &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => 'Right($value)';
}

/// Useful extensions for working with Either.
extension EitherExtensions<L, R> on Either<L, R> {
  /// Returns `true` if this is a [Left].
  bool get isLeft => this is Left<L, R>;

  /// Returns `true` if this is a [Right].
  bool get isRight => this is Right<L, R>;

  /// Returns the Left value if present, otherwise `null`.
  L? get left => this is Left<L, R> ? (this as Left<L, R>).value : null;

  /// Returns the Right value if present, otherwise `null`.
  R? get right => this is Right<L, R> ? (this as Right<L, R>).value : null;
}
