import 'package:flutter/material.dart';
import 'package:jintent/commons.dart';

/// A service for managing navigation within the application, using a singleton pattern.
///
/// The `JNavigatorService` class provides a single instance (singleton) to manage
/// navigation within the application. It holds a `GlobalKey` for accessing and
/// controlling the state of the application's navigator, allowing you to manage
/// navigation tasks such as pushing and popping routes.
///
/// The singleton pattern ensures that there is only one instance of this service
/// throughout the application's lifecycle, enabling centralized control of navigation.
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
