library jintent;

import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';

/// Represents an action or event that can modify application state.
///
/// The `JIntent` class is an abstraction that encapsulates a specific
/// action or event that may result in a change to the application's state.
/// This concept helps to structure the application by clearly defining
/// the different actions and how they affect the state.
///
/// When implemented, an `JIntent` typically contains:
/// - A method to invoke the action (`invoke()`).
/// - Any parameters or dependencies required to perform the action.
///
/// Intents are used in conjunction with controllers to manage
/// the logic and state changes within the application.
abstract class JIntent<T extends JState> with JCommonsMixin {
  /// Invokes the intent, potentially modifying the state managed by the [controller].
  ///
  /// This method is called to execute the logic defined in the intent.
  /// It is intended to perform specific operations and may result in changes
  /// to the state of the given [controller].
  ///
  /// - [controller]: The [JController] whose state may be modified by this intent.
  Future<void> invoke(JController<T> controller);
}
