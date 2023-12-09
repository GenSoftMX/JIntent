library jintent;

import 'package:flutter/cupertino.dart';
import 'package:jintent/commons.dart';
import 'package:jintent/jstate.dart';

/// Abstract class representing an intent that can modify the state of the application.
@immutable
abstract class JIntent<T extends JState> extends JCommonsMixin {
  /// Invokes the intent, potentially modifying the provided state.
  ///
  /// This method is used to execute the intent, perform logic, and potentially
  ///
  /// modify the provided state.
  Future<T> invoke(JController<T> controller);
}
