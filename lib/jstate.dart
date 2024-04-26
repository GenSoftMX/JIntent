import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

export 'jcontroller.dart';
export 'jintent.dart';
export 'jnavigator_service.dart';

@immutable
abstract class JState extends Equatable {
  JState copyWith();

  const JState();

  @override
  List<Object?> get props;
}
