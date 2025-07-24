import 'package:flutter/material.dart';
import 'jnavigator.dart';

/// Default implementation of JNavigator using Flutter's Navigator 1.0 API.
/// You can swap this with a GoRouter-based implementation if needed.
class JNavigatorImpl implements JNavigator {
  @override
  Future<void> go(BuildContext context, String path) async {
    await Navigator.pushReplacementNamed(context, path);
  }

  @override
  Future<void> push(BuildContext context, String path) async {
    await Navigator.pushNamed(context, path);
  }

  @override
  void pop(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  void popUntil(BuildContext context, bool Function(Route<dynamic>) predicate) {
    Navigator.popUntil(context, predicate);
  }

  @override
  bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }

  @override
  Future<void> replace(BuildContext context, String path) async {
    Navigator.pop(context);
    await Navigator.pushNamed(context, path);
  }

  @override
  Future<void> replaceAll(BuildContext context, String path) async {
    Navigator.pushNamedAndRemoveUntil(context, path, (route) => false);
  }

  @override
  Future<void> pushNamed(
    BuildContext context,
    String name, {
    Map<String, String>? params,
    Object? extra,
  }) async {
    await Navigator.pushNamed(
      context,
      name,
      arguments: extra,
    );
  }

  @override
  Future<void> goNamed(
    BuildContext context,
    String name, {
    Map<String, String>? params,
    Object? extra,
  }) async {
    await Navigator.pushReplacementNamed(
      context,
      name,
      arguments: extra,
    );
  }

  @override
  void popWithResult<T>(BuildContext context, T result) {
    Navigator.pop<T>(context, result);
  }

  @override
  Future<void> clearAndPush(BuildContext context, String path) async {
    Navigator.pushNamedAndRemoveUntil(context, path, (route) => false);
  }

  @override
  bool isCurrentRoute(BuildContext context, String path) {
    final route = ModalRoute.of(context);
    return route?.settings.name == path;
  }

  @override
  String? currentRoute(BuildContext context) {
    return ModalRoute.of(context)?.settings.name;
  }

  @override
  void navigateBackToRoot(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Future<T?> pushDialog<T>(BuildContext context, Widget dialog) {
    return showDialog<T>(
      context: context,
      builder: (_) => dialog,
    );
  }

  @override
  Future<T?> pushReplacementDialog<T>(BuildContext context, Widget dialog) {
    Navigator.pop(context);
    return showDialog<T>(
      context: context,
      builder: (_) => dialog,
    );
  }
}
