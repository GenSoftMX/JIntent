import 'package:counter/src/presentation/splash/effects/navigate_effect.dart';
import 'package:counter/src/presentation/splash/state/splash_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';

final splashControllerProvider =
    StateNotifierProvider<SplashController, SplashState>((ref) {
      return SplashController(SplashState.initialState());
    });

class SplashController extends JController<SplashState> {
  SplashController(super.initialState);

  Future<void> init() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    emitSideEffect(NavigateEffect());
  }

  @override
  void onInit() {}
}
