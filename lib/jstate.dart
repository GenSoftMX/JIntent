import 'package:flutter/foundation.dart';

export 'jcontroller.dart';
export 'jintent.dart';
export 'jnavigator_service.dart';

@immutable
abstract class JState {
  JState copyWith();
}