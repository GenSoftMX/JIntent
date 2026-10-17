import 'package:counter/main.dart';
import 'package:counter/navigation/router.dart';
import 'package:counter/src/gallery/gallery_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'gallery opens demos, expires confirmation and updates undo history',
    (tester) async {
      await prepareCounterApp();
      appRouter.go('/gallery');
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      for (final demo in galleryDemos) {
        final card = find.byKey(Key('demo-${demo.route}'));
        await tester.scrollUntilVisible(card, 200);
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.text(demo.title), findsOneWidget);

        if (demo.route == '/demos/undo') {
          await tester.enterText(
            find.byKey(const Key('note-field')),
            'Native note',
          );
          await tester.tap(find.byKey(const Key('add-note')));
          await tester.pumpAndSettle();
          expect(find.text('Native note'), findsOneWidget);
          await tester.tap(find.byKey(const Key('undo')));
          await tester.pumpAndSettle();
          expect(find.text('Native note'), findsNothing);
          await tester.tap(find.byKey(const Key('redo')));
          await tester.pumpAndSettle();
          expect(find.text('Native note'), findsOneWidget);
          await tester.tap(find.byKey(const Key('clear-history')));
          await tester.pumpAndSettle();
          expect(find.text('Native note'), findsOneWidget);
          expect(
            tester.widget<IconButton>(find.byKey(const Key('undo'))).onPressed,
            isNull,
          );
          expect(
            tester.widget<IconButton>(find.byKey(const Key('redo'))).onPressed,
            isNull,
          );
        }

        if (demo.route == '/demos/startup') {
          await tester.tap(find.text('Ask confirmation'));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsOneWidget);
          await tester.pump(const Duration(seconds: 11));
          await tester.pumpAndSettle();
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.text('Status: No answer in time'), findsOneWidget);
        }

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('JIntent gallery'), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
