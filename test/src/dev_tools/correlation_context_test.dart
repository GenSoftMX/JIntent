import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('CorrelationContext', () {
    setUp(() {
      CorrelationContext.resetCounter();
    });

    test('current returns null outside correlated context', () {
      expect(CorrelationContext.current, isNull);
    });

    test('runWithCorrelation provides correlation ID', () async {
      String? capturedId;

      await CorrelationContext.runWithCorrelation(() async {
        capturedId = CorrelationContext.current;
      });

      expect(capturedId, isNotNull);
      expect(capturedId, isA<String>());
    });

    test('runWithCorrelation uses provided correlation ID', () async {
      const testId = 'test-correlation-id';
      String? capturedId;

      await CorrelationContext.runWithCorrelation(() async {
        capturedId = CorrelationContext.current;
      }, correlationId: testId);

      expect(capturedId, testId);
    });

    test('correlation ID is accessible in nested async calls', () async {
      String? outerCapturedId;
      String? innerCapturedId;

      await CorrelationContext.runWithCorrelation(() async {
        outerCapturedId = CorrelationContext.current;

        await Future.delayed(Duration.zero);

        innerCapturedId = CorrelationContext.current;
      });

      expect(outerCapturedId, isNotNull);
      expect(innerCapturedId, outerCapturedId);
    });

    test('nested correlations maintain their own IDs', () async {
      String? outer;
      String? inner;

      await CorrelationContext.runWithCorrelation(() async {
        outer = CorrelationContext.current;

        await CorrelationContext.runWithCorrelation(() async {
          inner = CorrelationContext.current;
        });
      });

      expect(outer, isNotNull);
      expect(inner, isNotNull);
      expect(outer, isNot(equals(inner)));
    });

    test('runSyncWithCorrelation provides correlation ID', () {
      String? capturedId;

      CorrelationContext.runSyncWithCorrelation(() {
        capturedId = CorrelationContext.current;
      });

      expect(capturedId, isNotNull);
    });

    test('runSyncWithCorrelation uses provided correlation ID', () {
      const testId = 'sync-test-id';
      String? capturedId;

      CorrelationContext.runSyncWithCorrelation(() {
        capturedId = CorrelationContext.current;
      }, correlationId: testId);

      expect(capturedId, testId);
    });

    test('asContext returns null when no correlation ID', () {
      expect(CorrelationContext.asContext, isNull);
    });

    test('asContext returns map with correlation ID', () async {
      Map<String, String>? capturedContext;

      await CorrelationContext.runWithCorrelation(() async {
        capturedContext = CorrelationContext.asContext;
      });

      expect(capturedContext, isNotNull);
      expect(capturedContext!['correlationId'], isNotNull);
    });

    test('generated IDs are unique', () async {
      String? id1;
      String? id2;

      await CorrelationContext.runWithCorrelation(() async {
        id1 = CorrelationContext.current;
      });

      await CorrelationContext.runWithCorrelation(() async {
        id2 = CorrelationContext.current;
      });

      expect(id1, isNot(equals(id2)));
    });

    test('correlation ID persists across await boundaries', () async {
      String? id1;
      String? id2;
      String? id3;

      await CorrelationContext.runWithCorrelation(() async {
        id1 = CorrelationContext.current;

        await Future.delayed(const Duration(milliseconds: 10));
        id2 = CorrelationContext.current;

        await Future.delayed(const Duration(milliseconds: 10));
        id3 = CorrelationContext.current;
      });

      expect(id1, isNotNull);
      expect(id1, equals(id2));
      expect(id2, equals(id3));
    });

    test('returns value from runWithCorrelation', () async {
      final result = await CorrelationContext.runWithCorrelation(() async {
        return 42;
      });

      expect(result, 42);
    });

    test('returns value from runSyncWithCorrelation', () {
      final result = CorrelationContext.runSyncWithCorrelation(() {
        return 'test';
      });

      expect(result, 'test');
    });

    test('correlation ID contains timestamp and counter', () async {
      String? id;

      await CorrelationContext.runWithCorrelation(() async {
        id = CorrelationContext.current;
      });

      expect(id, matches(RegExp(r'^\d+-\d+$')));
    });
  });
}
