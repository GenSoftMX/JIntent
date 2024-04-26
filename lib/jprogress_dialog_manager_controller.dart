import 'package:flutter/foundation.dart';

@immutable
abstract class JProgressDialogManagerController<T> {
  Future<T> show({String? msg});
  Future<T> hide();
}
