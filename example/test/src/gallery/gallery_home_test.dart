import 'package:counter/navigation/router.dart';
import 'package:counter/src/gallery/gallery_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('lists every demo with its features', (tester) async {
    // The list builds lazily: use a tall viewport so every card exists.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: GalleryHome(onOpen: (_) {})));

    for (final demo in galleryDemos) {
      expect(find.text(demo.title), findsOneWidget);
      expect(find.byKey(Key('demo-${demo.route}')), findsOneWidget);
    }
    expect(find.text('Restartable'), findsOneWidget);
    expect(find.text('effectBufferSize'), findsOneWidget);
    expect(find.text('JDevToolsOverlay'), findsOneWidget);
    expect(find.text('UndoRedoMixin'), findsOneWidget);
  });

  testWidgets('tapping a demo reports its route', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(MaterialApp(home: GalleryHome(onOpen: opened.add)));

    final key = Key('demo-${galleryDemos[1].route}');
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));

    expect(opened, [galleryDemos[1].route]);
  });

  test('every demo route is registered in the router', () {
    final paths =
        appRouter.configuration.routes
            .whereType<GoRoute>()
            .map((route) => route.path)
            .toSet();

    expect(paths, containsAll(galleryDemos.map((demo) => demo.route)));
    expect(paths, contains('/gallery'));
  });
}
