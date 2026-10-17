import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/utils.dart';

void main() {
  const interval = Duration(milliseconds: 100);

  testWidgets(
    'first call runs immediately and later calls keep only the last',
    (tester) async {
      final throttler = JThrottler(interval);
      final calls = <String>[];

      throttler.call(() => calls.add('first'));
      throttler.call(() => calls.add('second'));
      throttler.call(() => calls.add('third'));
      expect(calls, ['first']);

      await tester.pump(interval);
      expect(calls, ['first', 'third']);
    },
  );

  testWidgets('a call after the interval runs immediately again', (
    tester,
  ) async {
    final throttler = JThrottler(interval);
    var count = 0;

    throttler.call(() => count++);
    await tester.pump(interval);
    expect(count, 1);

    throttler.call(() => count++);
    expect(count, 2);
    await tester.pump(interval);
  });

  testWidgets('immediateCall false defers execution to the interval end', (
    tester,
  ) async {
    final throttler = JThrottler(interval);
    var count = 0;

    throttler.call(() => count++, immediateCall: false);
    expect(count, 0);

    await tester.pump(interval);
    expect(count, 1);
  });

  testWidgets('reset discards the pending action', (tester) async {
    final throttler = JThrottler(interval);
    final calls = <String>[];

    throttler.call(() => calls.add('first'));
    throttler.call(() => calls.add('pending'));
    throttler.reset();

    await tester.pump(interval);
    expect(calls, ['first']);
  });

  testWidgets('a stale timer after reset does not release the throttle', (
    tester,
  ) async {
    final throttler = JThrottler(interval);
    final calls = <String>[];

    throttler.call(() => calls.add('first'));
    await tester.pump(const Duration(milliseconds: 50));
    throttler.reset();
    throttler.call(() => calls.add('second'));
    expect(calls, ['first', 'second']);

    // The first timer would have fired here; the second is still running.
    await tester.pump(const Duration(milliseconds: 50));
    throttler.call(() => calls.add('third'));
    expect(calls, ['first', 'second']);

    await tester.pump(const Duration(milliseconds: 50));
    expect(calls, ['first', 'second', 'third']);
  });
}
