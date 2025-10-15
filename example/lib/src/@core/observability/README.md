# Observability Integration

This module demonstrates how to integrate JIntent's observability features into your application.

## Features

- **Structured JSON Logging**: All logs are output as JSON for easy parsing and analysis
- **Metrics Collection**: Automatic tracking of intents, state changes, and effects
- **Correlation IDs**: Track user actions across multiple operations

## Setup

Initialize observability in your `main()` function:

```dart
import 'package:counter/src/@core/observability/observability_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize observability
  ObservabilitySetup.initialize(
    serviceName: 'counter-app',
    version: '1.0.0',
    minLevel: LogLevel.info,
    enableMetrics: true,
  );
  
  runApp(MyApp());
}
```

## Usage

### Logging

```dart
import 'package:counter/src/@core/observability/observability_setup.dart';

// Get the logger
final logger = ObservabilitySetup.logger;

// Log messages
logger.info('User action completed', context: {
  'action': 'increment',
  'value': 5,
});

// Log errors
logger.error('Operation failed', 
  error: exception,
  context: {'operation': 'save'},
);
```

### Child Logger with Context

```dart
// Create a logger with additional context
final requestLogger = ObservabilitySetup.createChildLogger({
  'userId': userId,
  'sessionId': sessionId,
});

requestLogger.info('Processing request');
```

### Metrics

Metrics are automatically collected when you dispatch intents:

```dart
// Metrics are automatically tracked for:
// - Intent dispatches (intent.dispatched)
// - State changes (state.changed)
// - Effect emissions (effect.emitted)

// Get metrics summary
final summary = ObservabilitySetup.getMetricsSummary();
print('Total intents dispatched: ${summary['counters']['intent.dispatched']}');

// Export and clear metrics (e.g., for sending to monitoring service)
final metrics = ObservabilitySetup.exportAndClearMetrics();
await sendToMonitoring(metrics);
```

### Correlation IDs

Track user actions with correlation IDs:

```dart
// In your UI code
onButtonPressed() async {
  await CorrelationContext.runWithCorrelation(() async {
    // Create logger with correlation context
    final logger = ObservabilitySetup.logger.withContext(
      CorrelationContext.asContext ?? {},
    );
    
    logger.info('User initiated action');
    
    // All intents dispatched here will share the same correlation ID
    await controller.dispatch(MyIntent());
  });
}
```

## Example Output

### Structured Log

```json
{
  "timestamp": "2025-10-15T12:34:56.789Z",
  "level": "INFO",
  "message": "User action completed",
  "service": "counter-app",
  "version": "1.0.0",
  "context": {
    "env": "development",
    "platform": "android",
    "action": "increment",
    "value": 5,
    "correlationId": "1697368496789-0"
  }
}
```

### Metrics Summary

```dart
{
  'enabled': true,
  'totalMetrics': 42,
  'activeTimers': 0,
  'counters': {
    'intent.dispatched|type=IncrementIntent': 15,
    'state.changed|stateType=CounterState': 15,
    'effect.emitted|type=ShowRejectOperation': 2,
  },
  'counterCount': 32,
  'gaugeCount': 0,
  'histogramCount': 0,
  'timerCount': 10,
}
```

## Best Practices

1. **Initialize Early**: Call `ObservabilitySetup.initialize()` as early as possible in `main()`
2. **Use Correlation IDs**: Wrap user actions in `CorrelationContext.runWithCorrelation()`
3. **Include Context**: Always include relevant context in log messages
4. **Protect PII**: Never log sensitive information like passwords or credit card numbers
5. **Export Metrics**: Periodically export and clear metrics to avoid memory growth

## Testing

The observability setup is designed to work seamlessly in tests:

```dart
testWidgets('observability works', (tester) async {
  ObservabilitySetup.initialize(enableMetrics: true);
  
  // Your test code
  
  // Check metrics were recorded
  final summary = ObservabilitySetup.getMetricsSummary();
  expect(summary['totalMetrics'], greaterThan(0));
});
```

## Production Considerations

In production, you may want to:

1. Set `minLevel: LogLevel.info` or higher to reduce log volume
2. Integrate with a log aggregation service (CloudWatch, Datadog, etc.)
3. Export metrics to a monitoring service (Prometheus, CloudWatch, etc.)
4. Implement log sampling for high-traffic applications
5. Redact sensitive data before logging

## See Also

- [Main Observability Guide](../../../../../../docs/OBSERVABILITY_GUIDE.md)
- [Observability Example](../../../../../../docs/examples/observability_example.dart)
