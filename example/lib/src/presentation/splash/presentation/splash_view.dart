import 'dart:async';

import 'package:counter/navigation/navigation.dart';
import 'package:counter/src/presentation/splash/controller/splash_controller.dart';
import 'package:counter/src/presentation/splash/effects/navigate_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jintent/jintent.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with NavigationConsumer {
  StreamSubscription<JEffect>? _effectSubscription;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(splashControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize(controller));
    });

    _effectSubscription = controller.sideEffects.listen((effect) {
      if (effect is NavigateEffect && mounted) {
        unawaited(_navigate(effect));
      }
    });
  }

  Future<void> _initialize(SplashController controller) async {
    try {
      await controller.init();
    } catch (error, stackTrace) {
      if (!mounted) return;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while initializing the splash screen'),
        ),
      );
    }
  }

  Future<void> _navigate(NavigateEffect effect) async {
    try {
      await navigation.go(context, '/gallery');
      effect.complete(null);
    } catch (error, stackTrace) {
      effect.result.ignore();
      effect.completeError(error, stackTrace);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          context: ErrorDescription('while navigating from the splash screen'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _effectSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon_white.png', height: 200, width: 200),
                const Text(
                  'JIntent Example',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const LinearProgressIndicator(),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text(
              '2025 © TodoFlutter. Todos los derechos reservados.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
