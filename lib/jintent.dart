library jintent;

import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';

/// Abstract class representing an intent that can modify the state of the application.
///
/// A [JIntent] encapsulates an action or command that can affect the state of
/// the application when invoked. It typically contains logic to be executed,
/// which may lead to changes in the state managed by a [JController].
///
/// This class serves as a blueprint for defining various intents that carry out
/// specific operations. Subclasses should implement the [invoke] method to
/// execute the intended logic.
abstract class JIntent<T extends JState> with JCommonsMixin {
  /// Invokes the intent, potentially modifying the state managed by the [controller].
  ///
  /// This method is called to execute the logic defined in the intent.
  /// It is intended to perform specific operations and may result in changes
  /// to the state of the given [controller].
  ///
  /// - [controller]: The [JController] whose state may be modified by this intent.
  void invoke(JController<T> controller);
}
