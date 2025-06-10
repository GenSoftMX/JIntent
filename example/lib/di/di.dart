import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jintent/jnavigator_service.dart';

class Di {
  bool loaded = false;
  static final GetIt sl = GetIt.I;
  static final Di _singleton = Di._internal();

  factory Di() {
    return _singleton;
  }

  Di._internal();

  Future<void> init() async {
    sl.registerLazySingleton<GlobalKey<NavigatorState>>(
      () => GlobalKey<NavigatorState>(),
    );

    sl.registerLazySingleton<JNavigatorService>(
      () => JNavigatorService(key: GlobalKey()),
    );
  }
}