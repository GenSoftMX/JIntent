import 'package:counter/src/presentation/splash/states/splash_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jeffect.dart';
import 'package:jintent/jstate.dart';

final splashControllerProvider =
    StateNotifierProvider<SplashController, SplashState>((ref) {
  return SplashController(SplashState.initialState());
});

class SplashController extends JController<SplashState> {
  SplashController(super.initialState);

  init() async {
    Future.delayed(const Duration(seconds: 2))
        .then((value) => emitSideEffect(NavigateEffect()));
  }
}

class NavigateEffect extends JEffect {
  NavigateEffect();
}
