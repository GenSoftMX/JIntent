import 'package:counter/src/presentation/counter/presentation/counter_view.dart';
import 'package:counter/src/presentation/splash/controllers/splash_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView> {
  @override
  void initState() {
    final controller = ref.read(splashControllerProvider.notifier);
    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => controller.init());

    controller.sideEffects.listen((effect) {
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CounterView(
            title: 'Flutter Demo Home Page',
          ),
        ));
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'Counter App',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator())
        ],
      ),
    );
  }
}
