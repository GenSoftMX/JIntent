import 'package:counter/di/di.dart';
import 'package:counter/src/presentation/counter/presentation/counter_view.dart';
import 'package:counter/src/presentation/splash/presentation/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  navigatorKey: globalNavigatorKey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashView()),
    GoRoute(
      path: '/counter',
      builder: (context, state) {
        return const CounterView();
      },
    ),
  ],
  errorBuilder:
      (context, state) =>
          Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
);
