import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/navigation.dart';

void main() {
  late JNavigatorImpl navigator;
  late BuildContext context;
  late Object? receivedArguments;

  Widget page(String name) => Scaffold(
    body: Builder(
      builder: (ctx) {
        context = ctx;
        return Text('page:$name');
      },
    ),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    receivedArguments = null;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        onGenerateRoute: (settings) {
          receivedArguments = settings.arguments ?? receivedArguments;
          return MaterialPageRoute<dynamic>(
            settings: settings,
            builder: (_) => page(settings.name ?? ''),
          );
        },
      ),
    );
  }

  setUp(() => navigator = JNavigatorImpl());

  testWidgets('push, pop and canPop manage the stack', (tester) async {
    await pumpApp(tester);
    expect(navigator.canPop(context), isFalse);

    unawaited(navigator.push(context, '/a'));
    await tester.pumpAndSettle();
    expect(find.text('page:/a'), findsOneWidget);
    expect(navigator.canPop(context), isTrue);

    navigator.pop(context);
    await tester.pumpAndSettle();
    expect(find.text('page:/'), findsOneWidget);
  });

  testWidgets('go replaces the current route', (tester) async {
    await pumpApp(tester);
    unawaited(navigator.go(context, '/a'));
    await tester.pumpAndSettle();
    expect(find.text('page:/a'), findsOneWidget);
    expect(navigator.canPop(context), isFalse);
  });

  testWidgets('replace pops then pushes', (tester) async {
    await pumpApp(tester);
    unawaited(navigator.push(context, '/a'));
    await tester.pumpAndSettle();
    unawaited(navigator.replace(context, '/b'));
    await tester.pumpAndSettle();
    expect(find.text('page:/b'), findsOneWidget);
    expect(navigator.currentRoute(context), '/b');
  });

  testWidgets('replaceAll and clearAndPush clear the stack', (tester) async {
    await pumpApp(tester);
    unawaited(navigator.push(context, '/a'));
    await tester.pumpAndSettle();

    unawaited(navigator.replaceAll(context, '/b'));
    await tester.pumpAndSettle();
    expect(navigator.canPop(context), isFalse);
    expect(find.text('page:/b'), findsOneWidget);

    unawaited(navigator.push(context, '/c'));
    await tester.pumpAndSettle();
    unawaited(navigator.clearAndPush(context, '/d'));
    await tester.pumpAndSettle();
    expect(navigator.canPop(context), isFalse);
    expect(find.text('page:/d'), findsOneWidget);
  });

  testWidgets('pushNamed and goNamed pass extra as arguments', (tester) async {
    await pumpApp(tester);
    unawaited(navigator.pushNamed(context, '/a', extra: 'x'));
    await tester.pumpAndSettle();
    expect(receivedArguments, 'x');

    unawaited(navigator.goNamed(context, '/b', extra: 'y'));
    await tester.pumpAndSettle();
    expect(receivedArguments, 'y');
    expect(find.text('page:/b'), findsOneWidget);
  });

  testWidgets('route inspection reports the current route', (tester) async {
    await pumpApp(tester);
    expect(navigator.isCurrentRoute(context, '/'), isTrue);
    expect(navigator.isCurrentRoute(context, '/a'), isFalse);
    expect(navigator.currentRoute(context), '/');
  });

  testWidgets('popUntil and navigateBackToRoot unwind the stack', (
    tester,
  ) async {
    await pumpApp(tester);
    // The root page stays mounted below the stack, unlike the popped pages.
    final root = context;
    for (final path in ['/a', '/b', '/c']) {
      unawaited(navigator.push(root, path));
      await tester.pumpAndSettle();
    }
    navigator.popUntil(root, (route) => route.settings.name == '/a');
    await tester.pumpAndSettle();
    expect(find.text('page:/a'), findsOneWidget);

    navigator.navigateBackToRoot(root);
    await tester.pumpAndSettle();
    expect(find.text('page:/'), findsOneWidget);
  });

  testWidgets('popWithResult returns the value to the caller', (tester) async {
    await pumpApp(tester);
    final result = navigator.push(context, '/a');
    await tester.pumpAndSettle();
    navigator.popWithResult<String>(context, 'done');
    await tester.pumpAndSettle();
    await result;
    expect(find.text('page:/'), findsOneWidget);
  });

  testWidgets('pushDialog resolves with the dialog result', (tester) async {
    await pumpApp(tester);
    final result = navigator.pushDialog<bool>(
      context,
      Builder(
        builder:
            (ctx) => TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ok'),
            ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ok'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('pushReplacementDialog pops the page before showing it', (
    tester,
  ) async {
    await pumpApp(tester);
    unawaited(navigator.push(context, '/a'));
    await tester.pumpAndSettle();

    final result = navigator.pushReplacementDialog<bool>(
      context,
      Builder(
        builder:
            (ctx) => TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('close'),
            ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('close'), findsOneWidget);
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
    expect(find.text('page:/'), findsOneWidget);
  });
}
