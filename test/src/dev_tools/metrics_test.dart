import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

class FakeIntent extends JIntent<FakeState> {
  @override
  Future<void> onInvoke() async {}
}

class FakeState extends JState {
  @override
  JState copyWith() => this;

  @override
  List<Object?> get props => [];
}

class FakeEffect extends JEffect<void> {}

void main() {
  group('JMetrics', () {
    setUp(() {
      JMetrics.enable();
      JMetrics.clear();
    });

    tearDown(() {
      JMetrics.disable();
      JMetrics.clear();
      // Clean up observers
      JObserver.onIntentDispatched = null;
      JObserver.onStateChanged = null;
      JObserver.onEffectEmitted = null;
    });

    test('starts disabled by default', () {
      JMetrics.disable();
      JMetrics.clear();
      
      JMetrics.incrementCounter('test');
      
      expect(JMetrics.getMetrics().length, 0);
    });

    test('enable allows metric collection', () {
      JMetrics.enable();
      JMetrics.incrementCounter('test');
      
      expect(JMetrics.getMetrics().length, 1);
    });

    test('incrementCounter records counter metric', () {
      JMetrics.incrementCounter('test.counter');
      
      final metrics = JMetrics.getMetrics();
      expect(metrics.length, 1);
      expect(metrics[0].name, 'test.counter');
      expect(metrics[0].type, MetricType.counter);
      expect(metrics[0].value, 1);
    });

    test('incrementCounter increments existing counter', () {
      JMetrics.incrementCounter('test');
      JMetrics.incrementCounter('test');
      JMetrics.incrementCounter('test');
      
      final metrics = JMetrics.getMetrics();
      expect(metrics.length, 3);
      expect(metrics[0].value, 1);
      expect(metrics[1].value, 2);
      expect(metrics[2].value, 3);
    });

    test('recordGauge records gauge metric', () {
      JMetrics.recordGauge('memory.usage', 1024);
      
      final metrics = JMetrics.getMetrics();
      expect(metrics.length, 1);
      expect(metrics[0].name, 'memory.usage');
      expect(metrics[0].type, MetricType.gauge);
      expect(metrics[0].value, 1024);
    });

    test('startTimer and stopTimer record duration', () async {
      final timerId = JMetrics.startTimer('operation');
      await Future.delayed(const Duration(milliseconds: 10));
      JMetrics.stopTimer(timerId);
      
      final metrics = JMetrics.getMetrics();
      expect(metrics.length, 1);
      expect(metrics[0].name, 'operation.duration');
      expect(metrics[0].type, MetricType.timer);
      expect(metrics[0].value, greaterThan(0));
      expect(metrics[0].tags['unit'], 'microseconds');
    });

    test('recordHistogram records histogram metric', () {
      JMetrics.recordHistogram('response.size', 512);
      
      final metrics = JMetrics.getMetrics();
      expect(metrics.length, 1);
      expect(metrics[0].name, 'response.size');
      expect(metrics[0].type, MetricType.histogram);
      expect(metrics[0].value, 512);
    });

    test('metrics include tags', () {
      JMetrics.incrementCounter('http.requests', tags: {
        'method': 'GET',
        'status': '200',
      });
      
      final metrics = JMetrics.getMetrics();
      expect(metrics[0].tags['method'], 'GET');
      expect(metrics[0].tags['status'], '200');
    });

    test('getMetricsByName filters correctly', () {
      JMetrics.incrementCounter('metric1');
      JMetrics.incrementCounter('metric2');
      JMetrics.incrementCounter('metric1');
      
      final filtered = JMetrics.getMetricsByName('metric1');
      expect(filtered.length, 2);
      expect(filtered.every((m) => m.name == 'metric1'), true);
    });

    test('getMetricsByType filters correctly', () {
      JMetrics.incrementCounter('counter1');
      JMetrics.recordGauge('gauge1', 100);
      JMetrics.incrementCounter('counter2');
      
      final counters = JMetrics.getMetricsByType(MetricType.counter);
      expect(counters.length, 2);
      expect(counters.every((m) => m.type == MetricType.counter), true);
    });

    test('clear removes all metrics', () {
      JMetrics.incrementCounter('test1');
      JMetrics.incrementCounter('test2');
      expect(JMetrics.getMetrics().length, 2);
      
      JMetrics.clear();
      expect(JMetrics.getMetrics().length, 0);
    });

    test('getSummary returns metric summary', () {
      JMetrics.incrementCounter('counter1');
      JMetrics.recordGauge('gauge1', 100);
      
      final summary = JMetrics.getSummary();
      expect(summary['enabled'], true);
      expect(summary['totalMetrics'], 2);
      expect(summary['counterCount'], 1);
      expect(summary['gaugeCount'], 1);
    });

    test('metric toJson includes all fields', () {
      final metric = Metric(
        name: 'test',
        type: MetricType.counter,
        value: 42,
        tags: {'tag1': 'value1'},
      );
      
      final json = metric.toJson();
      expect(json['name'], 'test');
      expect(json['type'], 'counter');
      expect(json['value'], 42);
      expect(json['timestamp'], isNotNull);
      expect(json['tags']['tag1'], 'value1');
    });

    group('attachToObserver', () {
      test('tracks intent dispatches', () {
        JMetrics.attachToObserver();
        
        final intent = FakeIntent();
        JObserver.notifyIntentDispatched(intent);
        
        final metrics = JMetrics.getMetricsByName('intent.dispatched');
        expect(metrics.length, 1);
        expect(metrics[0].tags['type'], 'FakeIntent');
      });

      test('tracks state changes', () {
        JMetrics.attachToObserver();
        
        final prev = FakeState();
        final next = FakeState();
        final intent = FakeIntent();
        JObserver.notifyStateChanged(prev, next, intent);
        
        final metrics = JMetrics.getMetricsByName('state.changed');
        expect(metrics.length, 1);
        expect(metrics[0].tags['stateType'], 'FakeState');
        expect(metrics[0].tags['originIntent'], 'FakeIntent');
      });

      test('tracks effect emissions', () {
        JMetrics.attachToObserver();
        
        final effect = FakeEffect();
        JObserver.notifyEffectEmitted(effect);
        
        final metrics = JMetrics.getMetricsByName('effect.emitted');
        expect(metrics.length, 1);
        expect(metrics[0].tags['type'], 'FakeEffect');
      });

      test('preserves original observer callbacks', () {
        bool originalIntentCalled = false;
        bool originalStateCalled = false;
        bool originalEffectCalled = false;
        
        JObserver.onIntentDispatched = (_) => originalIntentCalled = true;
        JObserver.onStateChanged = (_, __, ___) => originalStateCalled = true;
        JObserver.onEffectEmitted = (_) => originalEffectCalled = true;
        
        JMetrics.attachToObserver();
        
        JObserver.notifyIntentDispatched(FakeIntent());
        JObserver.notifyStateChanged(FakeState(), FakeState(), null);
        JObserver.notifyEffectEmitted(FakeEffect());
        
        expect(originalIntentCalled, true);
        expect(originalStateCalled, true);
        expect(originalEffectCalled, true);
      });
    });
  });

  group('MetricType', () {
    test('has correct values', () {
      expect(MetricType.counter.name, 'counter');
      expect(MetricType.gauge.name, 'gauge');
      expect(MetricType.histogram.name, 'histogram');
      expect(MetricType.timer.name, 'timer');
    });
  });
}
