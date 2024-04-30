import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

export 'jcontroller.dart';
export 'jintent.dart';
export 'jnavigator_service.dart';

/// An immutable base class representing the state in an application.
///
/// The `JState` class is designed to be used as a base class for defining state
/// in an application. It extends `Equatable`, allowing instances of `JState` to
/// be compared for equality based on their properties. This makes it useful in
/// state management scenarios, where changes in state need to be detected
/// efficiently.
///
/// This class is intended to be extended by concrete state classes, which
/// should implement their own `copyWith` method to create new instances
/// with modified properties.
///
/// **Key Features**:
/// - **Immutable**: Once an instance of `JState` is created, it cannot be
///   modified.
/// - **Equatable Integration**: Supports equality comparison based on properties.
///
/// Subclasses must override:
/// - `copyWith`: To create a new instance of the state with modified properties.
/// - `props`: To define the list of properties used for equality comparison.
@immutable
abstract class JState extends Equatable {
  /// Creates a copy of the current state with optional modifications.
  ///
  /// This method should be implemented by subclasses to create a new instance
  /// of the state, allowing partial updates to specific properties without
  /// changing the original instance.
  JState copyWith();

  const JState();

  /// The list of properties used to determine equality.
  ///
  /// This list should include all properties that are considered significant
  /// for determining if two instances of `JState` are the same.
  @override
  List<Object?> get props;
}
