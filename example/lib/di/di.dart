import 'package:counter/src/@core/components/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:jintent/jnavigator_service.dart';
import 'package:jintent/jprogress_dialog_manager_controller.dart';

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
      () => JNavigatorService.instance,
    );

    sl.registerLazySingleton<JProgressDialogManagerController>(
        () => ProgressDialogManager());
  }
}

ProviderContainer get container => Di.sl<ProviderContainer>();
