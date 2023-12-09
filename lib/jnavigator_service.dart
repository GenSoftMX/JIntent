import 'package:flutter/material.dart';

class JNavigatorService {
  // Private constructor to prevent instantiation from outside
  JNavigatorService._privateConstructor();

  // Instance of the singleton
  static final JNavigatorService _instance =
      JNavigatorService._privateConstructor();

  // Getter to access the singleton instance
  static JNavigatorService get instance => _instance;

  // GlobalKey for the navigator state
  final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  BuildContext get context => key.currentState!.context;
}
