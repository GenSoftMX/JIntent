import 'package:flutter/material.dart';

/// A service class that encapsulates navigation functionality in the application.
///
/// The `JNavigatorService` holds a [GlobalKey] to the [NavigatorState],
/// allowing centralized access to the navigator for performing navigation
/// actions such as pushing or popping routes.
///
/// This service enables decoupling of navigation logic from UI components,
/// making navigation easier to manage and test.
///
/// Example usage:
/// ```dart
/// final navigatorService = JNavigatorService(key: GlobalKey<NavigatorState>());
///
/// // Navigate to a new route
/// navigatorService.key.currentState?.pushNamed('/home');
///```
class JNavigatorService {
  final GlobalKey<NavigatorState> key;

  JNavigatorService({required this.key});
}
