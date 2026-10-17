import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

/// Shows a dialog owned by one effect, dismissing only that route if its result
/// settles externally (for example through timeout or controller disposal).
/// The handler still owns translating the dialog answer into effect.complete.
Future<T?> showEffectDialog<T>({
  required BuildContext context,
  required JEffect<T> effect,
  required WidgetBuilder builder,
}) async {
  if (effect.isCompleted) return null;
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<T>(context: context, builder: builder);
  final answer = navigator.push<T>(route);

  void dismissOwnedRoute() {
    if (navigator.mounted && route.isActive) navigator.removeRoute(route);
  }

  final settled = effect.result.then<T?>(
    (_) {
      dismissOwnedRoute();
      return null;
    },
    onError: (Object error, StackTrace stackTrace) {
      dismissOwnedRoute();
      return null;
    },
  );
  // Older supported Flutter releases do not complete push's future when a
  // route is removed. Also settle this handler from the effect's own result.
  return Future.any([answer, settled]);
}
