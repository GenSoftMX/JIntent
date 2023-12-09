import 'package:flutter/foundation.dart';
import 'package:jintent/commons.dart';

@immutable
abstract class JProgressDialogManagerController<T> extends JCommonsMixin {
  Future<T> show({String? msg});
  Future<T> hide();
}
