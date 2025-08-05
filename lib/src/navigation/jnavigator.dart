import 'package:flutter/material.dart';

/// Base contract for navigation services in Flutter.
/// Allows abstracting navigation logic to enable different implementations,
/// making it easier to swap navigation managers without affecting the app.
abstract class JNavigator {
  /// Navigates to a route by replacing the current one.
  /// [path] is the destination route as a string.
  Future<void> go(BuildContext context, String path);

  /// Pushes a new route onto the navigation stack.
  /// [path] is the route to push.
  Future<void> push(BuildContext context, String path);

  /// Pops the current route off the navigation stack.
  void pop(BuildContext context);

  /// Pops routes until the given [predicate] returns true.
  /// Useful for returning to a specific route.
  void popUntil(BuildContext context, bool Function(Route<dynamic>) predicate);

  /// Checks if it's possible to pop a route.
  bool canPop(BuildContext context);

  /// Replaces the current route with a new one.
  /// [path] is the new route.
  Future<void> replace(BuildContext context, String path);

  /// Replaces the entire navigation stack with a new route.
  /// [path] is the new root route.
  Future<void> replaceAll(BuildContext context, String path);

  /// Pushes a named route onto the stack.
  /// Supports optional path parameters and extra data.
  Future<void> pushNamed(
    BuildContext context,
    String name, {
    Map<String, String>? params,
    Object? extra,
  });

  /// Navigates to a named route by replacing the current one.
  /// Supports optional path parameters and extra data.
  Future<void> goNamed(
    BuildContext context,
    String name, {
    Map<String, String>? params,
    Object? extra,
  });

  /// Pops the current route and returns a [result] to the previous one.
  void popWithResult<T>(BuildContext context, T result);

  /// Clears the navigation stack and pushes a new route.
  Future<void> clearAndPush(BuildContext context, String path);

  /// Checks if the current route matches the given [path].
  bool isCurrentRoute(BuildContext context, String path);

  /// Returns the current route path as a string, or null if unavailable.
  String? currentRoute(BuildContext context);

  /// Navigates back to the root of the navigation stack.
  void navigateBackToRoot(BuildContext context);

  /// Pushes a dialog route onto the stack and waits for a result.
  Future<T?> pushDialog<T>(BuildContext context, Widget dialog);

  /// Replaces the current route with a dialog and waits for a result.
  Future<T?> pushReplacementDialog<T>(BuildContext context, Widget dialog);
}
