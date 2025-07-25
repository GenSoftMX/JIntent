import 'package:counter/navigation/navigation.dart';
import 'package:counter/src/domain/use_cases/decrement_use_case.dart';
import 'package:counter/src/domain/use_cases/get_current_value_use_case.dart';
import 'package:counter/src/domain/use_cases/increment_use_case.dart';
import 'package:counter/src/domain/use_cases/save_current_value_use_case.dart';
import 'package:counter/src/presentation/counter/intents/decrement_intent.dart';
import 'package:counter/src/presentation/counter/intents/get_current_counter_value_intent.dart';
import 'package:counter/src/presentation/counter/intents/increment_intent.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jintent/jintent.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Di {
  bool loaded = false;
  static final GetIt sl = GetIt.I;
  static final Di _singleton = Di._internal();

  factory Di() {
    return _singleton;
  }

  Di._internal();

  Future<void> init() async {
    sl.registerLazySingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance(),
    );

    await sl.isReady<SharedPreferences>();

    sl.registerLazySingleton<JNavigator>(() => NavigatorImpl());

    await loadUseCases();
    await loadIntents();

    loaded = true;
  }

  Future<void> loadUseCases() async {
    sl.registerLazySingleton<IncrementUseCase>(() => IncrementUseCase());
    sl.registerLazySingleton<DecrementUseCase>(() => DecrementUseCase());

    sl.registerLazySingleton<GetCurrentValueUseCase>(
      () => GetCurrentValueUseCase(preferences: sl()),
    );

    sl.registerLazySingleton<SaveCurrentValueUseCase>(
      () => SaveCurrentValueUseCase(preferences: sl()),
    );
  }

  Future<void> loadIntents() async {
    sl.registerLazySingleton<IncrementIntent>(
      () => IncrementIntent(
        incrementUseCase: sl(),
        saveCurrentValueUseCase: sl(),
      ),
    );
    sl.registerLazySingleton<DecrementIntent>(
      () => DecrementIntent(
        decrementUseCase: sl(),
        saveCurrentValueUseCase: sl(),
      ),
    );

    sl.registerLazySingleton<GetCurrentCounterValueIntent>(
      () => GetCurrentCounterValueIntent(getCurrentValueUseCase: sl()),
    );
  }
}

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();
