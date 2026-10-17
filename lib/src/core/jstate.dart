import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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
/// [immutable] is an analyzer contract, not a runtime freeze. Use final fields
/// and defensive copies or unmodifiable collections, including nested values.
/// Include every value relevant to state equality in [props]. Controllers skip
/// updates when the previous and next states compare equal.
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
  /// For nullable fields, distinguish an omitted argument from an explicit null.
  /// One option is a private sentinel, with argument validation in the subclass:
  /// ```dart
  /// const _unchanged = Object();
  ///
  /// class ProfileState extends JState {
  ///   final String? name;
  ///   const ProfileState({this.name});
  ///
  ///   @override
  ///   ProfileState copyWith({Object? name = _unchanged}) {
  ///     if (!identical(name, _unchanged) && name != null && name is! String) {
  ///       throw ArgumentError.value(name, 'name', 'Must be a String or null');
  ///     }
  ///     return ProfileState(
  ///       name: identical(name, _unchanged) ? this.name : name as String?,
  ///     );
  ///   }
  ///
  ///   @override
  ///   List<Object?> get props => [name];
  /// }
  /// ```
  JState copyWith();

  const JState();

  /// The list of properties used to determine equality.
  ///
  /// This list should include all properties that are considered significant
  /// for determining if two instances of `JState` are the same.
  @override
  List<Object?> get props;
}
