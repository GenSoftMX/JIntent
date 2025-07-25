import 'package:counter/navigation/navigation.dart';
import 'package:counter/src/presentation/splash/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> with NavigationConsumer{

  @override
  void initState() {
    final controller = ref.read(splashControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => controller.init(),
    );

    controller.sideEffects.listen((effect) {
      if (mounted) {
        navigation.go(context,'/counter');
      }
    });

    super.initState();
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
