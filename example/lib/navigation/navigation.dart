import 'package:counter/di/di.dart';
import 'package:counter/navigation/router.dart';
import 'package:flutter/material.dart';
import 'package:jintent/jintent.dart';

class NavigatorImpl implements JNavigator {
  @override
  Future<void> go(BuildContext context, String path) async {
    appRouter.go(path);
  }

  @override
  Future<void> push(BuildContext context, String path) async {
    appRouter.push(path);
  }

  @override
  void pop(BuildContext context) {
    appRouter.pop();
  }

  @override
  void popUntil(BuildContext context, bool Function(Route<dynamic>) predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  @override
  bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  @override
  Future<void> replace(BuildContext context, String path) async {
    appRouter.go(path);
  }

  @override
  Future<void> replaceAll(BuildContext context, String path) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    appRouter.go(path);
  }

  @override
  Future<void> pushNamed(
    BuildContext context,
    String name, {
    Map<String, String>? params,
    Object? extra,
  }) async {
    final location = appRouter.namedLocation(
      name,
      queryParameters: params ?? {},
    );
    appRouter.push(location, extra: extra);
  }

  @override
  Future<void> goNamed(
    BuildContext context,
    String name, {
    Map<String, String>? params,
    Object? extra,
  }) async {
    final location = appRouter.namedLocation(
      name,
      queryParameters: params ?? {},
    );
    appRouter.go(location, extra: extra);
  }

  @override
  void popWithResult<T>(BuildContext context, T result) {
    Navigator.of(context).pop(result);
  }

  @override
  Future<void> clearAndPush(BuildContext context, String path) async {
    Navigator.of(context).popUntil((route) => route.isFirst);
    appRouter.push(path);
  }

  @override
  bool isCurrentRoute(BuildContext context, String path) {
    final uri = appRouter.routeInformationProvider.value.uri;
    return uri.path == path;
  }

  @override
  String? currentRoute(BuildContext context) {
    final uri = appRouter.routeInformationProvider.value.uri;
    return uri.path;
  }

  @override
  void navigateBackToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Future<T?> pushDialog<T>(BuildContext context, Widget dialog) {
    return showDialog<T>(context: context, builder: (_) => dialog);
  }

  @override
  Future<T?> pushReplacementDialog<T>(BuildContext context, Widget dialog) {
    return showDialog<T>(
      context: context,
      builder: (_) => dialog,
      useRootNavigator: true,
    );
  }
}

mixin NavigationConsumer {
  JNavigator get navigation => Di.sl<JNavigator>();
}
