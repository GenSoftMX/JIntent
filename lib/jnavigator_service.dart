import 'package:flutter/material.dart';
import 'package:jintent/commons.dart';

/// Service that manages application navigation.
///
/// The `JNavigatorService` class provides an abstraction for handling
/// navigation within the application. It typically encapsulates logic
/// for navigating between different screens or routes, allowing
/// for a centralized approach to navigation.
///
/// This service might include:
/// - Methods to navigate to specific routes or screens.
/// - Logic for handling navigation-related events.
/// - Access to the current `BuildContext` for operations that require it.
///
/// By using a service for navigation, you can decouple navigation logic
/// from individual widgets, making the application more maintainable.
class JNavigatorService with JCommonsMixin {
  // Private constructor to prevent direct instantiation from outside
  JNavigatorService._privateConstructor() {
    key = di<GlobalKey<NavigatorState>>();
  }

  // Singleton instance
  static final JNavigatorService _instance =
      JNavigatorService._privateConstructor();

  // Getter to access the singleton instance
  static JNavigatorService get instance => _instance;

  // GlobalKey for accessing the navigator's state
  late final GlobalKey<NavigatorState> key;
}
