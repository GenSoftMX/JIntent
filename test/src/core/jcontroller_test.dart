import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';
import 'package:mocktail/mocktail.dart';


class MockIntent<T extends JState> extends Mock implements JIntent<T> {}

class MockController<T extends JState> extends Mock implements JController<T> {}

class MockJIntentDispatcher extends Mock implements JIntentDispatcher {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockController());
  });

  group('JDefaultIntentDispatcher', () {
    late JDefaultIntentDispatcher dispatcher;
    late MockIntent<JState> intent;
    late MockController<JState> controller;

    setUp(() {
      dispatcher = JDefaultIntentDispatcher();
      intent = MockIntent();
      controller = MockController();

      when(() => intent.run(controller)).thenAnswer((_) async {});
      JObserver.onIntentDispatched = null; // Reset observer
    });

    test('dispatch calls intent.run and notifies observer', () async {
      var notified = false;
      JObserver.onIntentDispatched = (dispatchedIntent) {
        expect(dispatchedIntent, intent);
        notified = true;
      };

      await dispatcher.dispatch(intent, controller);

      verify(() => intent.run(controller)).called(1);
      expect(notified, isTrue);
    });
  });

  group('LoggingDispatcher', () {
    late MockIntent<JState> intent;
    late MockController<JState> controller;
    late JIntentDispatcher innerDispatcher;
    late LoggingDispatcher dispatcher;

    setUp(() {
      intent = MockIntent();
      controller = MockController();

      innerDispatcher = MockJIntentDispatcher();
      dispatcher = LoggingDispatcher(innerDispatcher);

      // when(() => intent.runtimeType).thenReturn(Type);
      when(() => intent.run(controller)).thenAnswer((_) async {});
      when(() => innerDispatcher.dispatch(intent, controller))
          .thenAnswer((_) async {});
    });

    test('dispatch logs and calls inner dispatcher', () async {
      final logs = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      await dispatcher.dispatch(intent, controller);

      expect(
        logs,
        containsAll([
          contains('Dispatching'),
          contains('Completed'),
        ]),
      );

      verify(() => innerDispatcher.dispatch(intent, controller)).called(1);

      debugPrint = debugPrintSynchronously;
    });
  });
}


