library jintent;

import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';

/// Abstract class representing an intent that can modify the state of the application.
abstract class JIntent<T extends JState> with JCommonsMixin {
  JIntent();

  /// Invokes the intent, potentially modifying the provided state.
  ///
  /// This method is used to execute the intent, perform logic, and potentially
  ///
  /// modify the provided state.
  invoke(JController<T> controller) {}
}
