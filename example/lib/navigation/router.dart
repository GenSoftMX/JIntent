import 'package:counter/di/di.dart';
import 'package:counter/src/demos/concurrency_lab/presentation/lab_page.dart';
import 'package:counter/src/demos/observability_lab/presentation/observability_page.dart';
import 'package:counter/src/demos/startup_effects/presentation/startup_page.dart';
import 'package:counter/src/demos/undo_notes/presentation/notes_page.dart';
import 'package:counter/src/gallery/gallery_home.dart';
import 'package:counter/src/presentation/counter/presentation/counter_view.dart';
import 'package:counter/src/presentation/splash/presentation/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  navigatorKey: globalNavigatorKey,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashView()),
    GoRoute(
      path: '/gallery',
      builder:
          (context, state) =>
              GalleryHome(onOpen: (route) => context.push(route)),
    ),
    GoRoute(
      path: '/demos/concurrency',
      builder: (context, state) => const ConcurrencyLabPage(),
    ),
    GoRoute(
      path: '/demos/startup',
      builder: (context, state) => const StartupEffectsPage(),
    ),
    GoRoute(
      path: '/demos/observability',
      builder: (context, state) => const ObservabilityLabPage(),
    ),
    GoRoute(
      path: '/demos/undo',
      builder: (context, state) => const UndoNotesPage(),
    ),
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
