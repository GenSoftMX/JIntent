import 'package:counter/src/modules/counter/presentation/counter_view.dart';
import 'package:counter/src/modules/splash/states/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jstate.dart';

final splashControllerProvider =
    StateNotifierProvider<SplashController, SplashState>((ref) {
  return SplashController(SplashState.initialState());
});

class SplashController extends JController<SplashState> {
  SplashController(super.initialState);

  init() async {
    Future.delayed(const Duration(seconds: 2))
        .then((value) => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => const CounterView(
                title: 'Flutter Demo Home Page',
              ),
            )));
  }
}
