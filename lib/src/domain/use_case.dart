import 'dart:async';
import 'package:jintent/src/domain/either.dart';

/// A function type that validates the input for a use case.
///
/// Takes an input of type [I] and returns an [Either] containing:
/// - a failure ([Exception]) on the `Left` if the input is invalid,
/// - or the validated input [I] on the `Right` if the input is valid.
///
/// This validator can be used to enforce preconditions or business rules
/// before executing the use case logic.
typedef UseCaseInputValidator<I> = Either<Exception, I> Function(I input);

/// Base interface for all asynchronous use cases.
///
/// Follows the Clean Architecture principle where each use case
/// encapsulates a single piece of business logic.
///
/// - [OUTPUT] - The return type of the use case (usually a model or entity).
/// - [INPUT] - The type of parameters required to execute the use case.
abstract class JUseCase<INPUT, OUTPUT> {
  final List<UseCaseInputValidator<INPUT>> _validators = [];

  void addValidator(UseCaseInputValidator<INPUT> validator) {
    _validators.add(validator);
  }

  Future<Either<Exception, OUTPUT>> call(INPUT input) async {
    for (final validator in _validators) {
      final result = validator(input);
      if (result.isLeft) return Left(result.left!);
    }
    return run(input);
  }

  /// Executes the use case with the given [input].
  ///
  /// Returns an [Either] containing an [Exception] on failure
  /// or [OUTPUT] on success.
  Future<Either<Exception, OUTPUT>> run(INPUT input);
}

/// Base interface for synchronous use cases.
///
/// Allows execution of business logic that completes immediately
/// without asynchronous operations.
///
/// - [INPUT] - The type of parameters required to execute the use case.
/// - [OUTPUT] - The return type of the use case.

abstract class JSyncUseCase<INPUT, OUTPUT> {
  final List<UseCaseInputValidator<INPUT>> _validators = [];

  void addValidator(UseCaseInputValidator<INPUT> validator) {
    _validators.add(validator);
  }

  /// Executes the use case synchronously with the given [input].
  ///
  /// Returns an [Either] containing an [Exception] on failure
  /// - [INPUT] - The type of parameters required to execute the use case.
  /// - [OUTPUT] on success.
  Either<Exception, OUTPUT> call(INPUT input) {
    for (final validator in _validators) {
      final result = validator(input);
      if (result.isLeft) return Left(result.left!);
    }
    return run(input);
  }

  Either<Exception, OUTPUT> run(INPUT input);
}

/// Interface for asynchronous use cases that do not return a value.
///
/// Useful for use cases that represent actions or side-effects.
///
/// - [INPUT] - The type of parameters required to execute the use case.
abstract class JUseCaseVoid<INPUT> {
  /// Executes the use case with the given [input].
  ///
  /// Returns an [Either] containing an [Exception] on failure
  /// or `void` on success.
  Future<void> run(INPUT input);
}

/// A placeholder class representing no parameters for use cases that
/// do not require input parameters.
class JNoParams {
  const JNoParams();
}
