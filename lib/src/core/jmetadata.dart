import 'package:jintent/jintent.dart';

/// Provides optional metadata for [JIntent]s to enhance observability and logging.
///
/// This mixin can be applied to any [JIntent] to expose descriptive information
/// such as a human-readable name, intent type/category, and custom metadata.
///
/// It is especially useful in debugging tools, analytics, or logging systems
/// that require additional context about dispatched intents.
///
/// ### Example:
/// ```dart
/// class DecrementIntent extends JIntent<CounterState> with JMetaData {
///   @override
///   String get name => 'Decrement Counter';
///
///   @override
///   String get type => 'counter';
///
///   @override
///   Map<String, dynamic> get metadata => {
///     'timestamp': DateTime.now().toIso8601String(),
///     'origin': 'user_button',
///   };
/// }
/// ```
mixin JMetaData<T extends JState> on JIntent<T> {
  /// A descriptive name for the intent. Defaults to the class name.
  String get name => runtimeType.toString();

  /// A category or type identifier for grouping intents.
  /// By default, returns the runtimeType of the implementing class.
  String get type => 'default';

  /// Arbitrary key-value metadata to provide additional context.
  Map<String, dynamic> get metadata => {};
}
