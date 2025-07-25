import 'package:equatable/equatable.dart';

/// A simplified base class that extends [Equatable] for consistent equality.
///
/// Use this class instead of extending [Equatable] directly in your models or states.
/// It improves clarity and decouples your app code from the external dependency.
abstract class JEquatable extends Equatable {
  const JEquatable();

  @override
  bool get stringify => true; // optional: enables readable toString
}
