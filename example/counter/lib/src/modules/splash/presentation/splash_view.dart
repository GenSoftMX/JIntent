import 'package:counter/src/modules/splash/controllers/splash_controller.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => ref.read(splashControllerProvider.notifier).init());

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
