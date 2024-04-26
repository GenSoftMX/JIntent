import 'package:flutter/material.dart';
import 'package:jintent/commons.dart';

class JNavigatorService with JCommonsMixin {
  // Private constructor to prevent instantiation from outside
  JNavigatorService._privateConstructor() {
    key = di<GlobalKey<NavigatorState>>();
  }

  // Instance of the singleton
  static final JNavigatorService _instance =
      JNavigatorService._privateConstructor();

  // Getter to access the singleton instance
  static JNavigatorService get instance => _instance;

  // GlobalKey for the navigator state
  late final GlobalKey<NavigatorState> key;
}
