# Observability Guide for JIntent

This guide provides comprehensive documentation for the observability features in JIntent, including structured logging, correlation IDs, and metrics collection.

## Table of Contents

1. [Overview](#overview)
2. [Structured Logging](#structured-logging)
3. [Correlation IDs](#correlation-ids)
4. [Metrics Collection](#metrics-collection)
5. [Best Practices](#best-practices)
6. [Integration Examples](#integration-examples)

## Overview

JIntent provides production-ready observability features to help you monitor, debug, and understand your application's behavior. The observability stack includes:

- **Structured JSON Logging**: Machine-readable logs for easy parsing and analysis
- **Correlation IDs**: Track user actions across multiple operations
- **Metrics Collection**: Performance and operational metrics for monitoring
- **Integration with JObserver**: Automatic tracking of intents, state changes, and effects

## Structured Logging

### Basic Usage

```dart
import 'package:jintent/jintent.dart';

void main() {
  final logger = JStructuredLogger(
    serviceName: 'my-app',
    version: '1.0.0',
    minLevel: LogLevel.info,
  );
  
  logger.info('Application started');
  logger.warn('Configuration missing', context: {
    'config': 'api_key',
  });
  logger.error('Failed to connect', 
    error: Exception('Connection refused'),
    context: {'host': 'api.example.com'},
  );
  
  runApp(MyApp());
}
```

### Log Levels

JStructuredLogger supports five log levels:

- `LogLevel.trace`: Detailed diagnostic information
- `LogLevel.debug`: Debug-level information for development
- `LogLevel.info`: Informational messages about normal operation
- `LogLevel.warn`: Warning messages about potential issues
- `LogLevel.error`: Error messages about failures

### Log Output Format

All logs are output as JSON with the following structure:

```json
{
  "timestamp": "2025-10-15T12:34:56.789Z",
  "level": "INFO",
  "message": "User logged in",
  "service": "my-app",
  "version": "1.0.0",
  "context": {
    "userId": "12345",
    "correlationId": "1697368496789-0"
  }
}
```

### Context Propagation

Create child loggers with additional context:

```dart
final baseLogger = JStructuredLogger(
  serviceName: 'my-app',
  defaultContext: {'env': 'production'},
);

// Create child logger with request-specific context
final requestLogger = baseLogger.withContext({
  'correlationId': correlationId,
  'userId': userId,
});

requestLogger.info('Processing request');
```

## Correlation IDs

Correlation IDs help you trace a single user action through your entire application stack.

### Basic Usage

```dart
import 'package:jintent/jintent.dart';

// Wrap user actions in a correlation context
await CorrelationContext.runWithCorrelation(() async {
  // All code here shares the same correlation ID
  await controller.dispatch(LoginIntent());
  
  // Access the correlation ID anywhere
  final id = CorrelationContext.current;
  logger.info('User action', context: {'correlationId': id});
});
```

### Integration with Logging

```dart
final logger = JStructuredLogger(serviceName: 'my-app');

await CorrelationContext.runWithCorrelation(() async {
  // Create logger with correlation context
  final correlatedLogger = logger.withContext(
    CorrelationContext.asContext ?? {},
  );
  
  correlatedLogger.info('Starting operation');
  await controller.dispatch(SomeIntent());
  correlatedLogger.info('Operation complete');
});
```

### Intent-Level Correlation

Track intents with correlation IDs:

```dart
class MyIntent extends JIntent<MyState> {
  @override
  Future<void> onInvoke() async {
    final correlationId = CorrelationContext.current;
    
    // Use in logging
    logger.debug('Intent invoked', context: {
      'intentType': runtimeType.toString(),
      'correlationId': correlationId,
    });
    
    // Continue with intent logic
    await performOperation();
  }
}
```

## Metrics Collection

JMetrics provides a flexible framework for collecting operational and performance metrics.

### Enabling Metrics

```dart
void main() {
  // Enable metrics collection
  JMetrics.enable();
  
  // Automatically track all intents, state changes, and effects
  JMetrics.attachToObserver();
  
  runApp(MyApp());
}
```

### Metric Types

#### Counters

Track the number of occurrences:

```dart
JMetrics.incrementCounter('user.login');
JMetrics.incrementCounter('api.request', tags: {
  'endpoint': '/users',
  'method': 'GET',
});
```

#### Gauges

Record values that can go up or down:

```dart
JMetrics.recordGauge('memory.usage', 1024);
JMetrics.recordGauge('active.users', userCount);
```

#### Timers

Measure operation duration:

```dart
final timerId = JMetrics.startTimer('api.request');
try {
  await performOperation();
} finally {
  JMetrics.stopTimer(timerId, tags: {'status': 'success'});
}
```

#### Histograms

Record distributions of values:

```dart
JMetrics.recordHistogram('response.size', responseBytes);
JMetrics.recordHistogram('queue.depth', queueSize);
```

### Automatic Intent Tracking

When you attach JMetrics to JObserver, it automatically tracks:

- `intent.dispatched`: Count of dispatched intents (tagged by type)
- `intent.execution`: Duration of intent execution
- `state.changed`: Count of state changes (tagged by state type)
- `effect.emitted`: Count of emitted effects (tagged by type and category)

### Retrieving Metrics

```dart
// Get all metrics
final allMetrics = JMetrics.getMetrics();

// Filter by name
final intentMetrics = JMetrics.getMetricsByName('intent.dispatched');

// Filter by type
final counters = JMetrics.getMetricsByType(MetricType.counter);

// Get summary
final summary = JMetrics.getSummary();
print('Total metrics: ${summary['totalMetrics']}');
print('Counters: ${summary['counterCount']}');
```

### Exporting Metrics

```dart
// Export metrics to JSON
final metrics = JMetrics.getMetrics();
final jsonData = metrics.map((m) => m.toJson()).toList();

// Send to monitoring system
await sendToMonitoring(jsonData);

// Clear after export
JMetrics.clear();
```

## Best Practices

### 1. Use Correlation IDs for User Actions

Always wrap user-initiated actions in correlation contexts:

```dart
// Good
onButtonPressed() async {
  await CorrelationContext.runWithCorrelation(() async {
    await controller.dispatch(ButtonPressedIntent());
  });
}

// Not recommended
onButtonPressed() async {
  await controller.dispatch(ButtonPressedIntent());
}
```

### 2. Log at Appropriate Levels

- Use `trace` for very detailed debugging (disabled in production)
- Use `debug` for development debugging
- Use `info` for important business events
- Use `warn` for recoverable errors or warnings
- Use `error` for actual errors that need attention

### 3. Include Context in Logs

Always include relevant context:

```dart
// Good
logger.error('Payment failed', context: {
  'userId': userId,
  'amount': amount,
  'currency': currency,
  'correlationId': CorrelationContext.current,
});

// Not recommended
logger.error('Payment failed');
```

### 4. Protect PII

Never log sensitive information:

```dart
// Bad - logs password
logger.info('Login attempt', context: {
  'username': username,
  'password': password,  // Never log passwords!
});

// Good
logger.info('Login attempt', context: {
  'username': username,
  'passwordLength': password.length,
});
```

### 5. Use Structured Context

Prefer structured data over string concatenation:

```dart
// Good
logger.info('Order created', context: {
  'orderId': order.id,
  'items': order.items.length,
  'total': order.total,
});

// Not recommended
logger.info('Order ${order.id} created with ${order.items.length} items');
```

## Integration Examples

### Complete Example: Login Flow

```dart
class LoginIntent extends JIntent<AuthState> with JIntentHelpers {
  final LoginUseCase _loginUseCase;
  final JStructuredLogger _logger;

  LoginIntent(this._loginUseCase, this._logger);

  @override
  Future<void> onInvoke() async {
    // Wrap in correlation context
    await CorrelationContext.runWithCorrelation(() async {
      final correlatedLogger = _logger.withContext(
        CorrelationContext.asContext ?? {},
      );

      correlatedLogger.info('Login attempt started');
      
      // Track timing
      final timerId = JMetrics.startTimer('login.duration');
      
      try {
        final result = await _loginUseCase.execute();
        
        result.fold(
          (error) {
            correlatedLogger.error('Login failed', 
              error: error,
              context: {'errorType': error.runtimeType.toString()},
            );
            JMetrics.incrementCounter('login.failed', tags: {
              'reason': error.runtimeType.toString(),
            });
            JMetrics.stopTimer(timerId, tags: {'status': 'failed'});
            handleFailure(error);
          },
          (user) {
            correlatedLogger.info('Login successful', context: {
              'userId': user.id,
            });
            JMetrics.incrementCounter('login.success');
            JMetrics.stopTimer(timerId, tags: {'status': 'success'});
            handleSuccess(user);
          },
        );
      } catch (e, stackTrace) {
        correlatedLogger.error('Unexpected error during login',
          error: e,
          stackTrace: stackTrace,
        );
        JMetrics.incrementCounter('login.error');
        JMetrics.stopTimer(timerId, tags: {'status': 'error'});
        rethrow;
      }
    });
  }

  void handleFailure(Exception error) {
    emitSideEffect(ShowErrorEffect(error.toString()));
  }

  void handleSuccess(User user) {
    update((state) => state.copyWith(user: user, isAuthenticated: true));
    emitSideEffect(NavigateToHomeEffect());
  }
}
```

### Example: Monitoring Setup

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize structured logging
  final logger = JStructuredLogger(
    serviceName: 'my-app',
    version: '1.0.0',
    minLevel: LogLevel.info,
    defaultContext: {
      'env': kReleaseMode ? 'production' : 'development',
    },
  );
  
  // Enable metrics
  JMetrics.enable();
  JMetrics.attachToObserver();
  
  // Setup periodic metric export
  Timer.periodic(const Duration(minutes: 1), (_) {
    final metrics = JMetrics.getMetrics();
    if (metrics.isNotEmpty) {
      exportMetrics(metrics);
      JMetrics.clear();
    }
  });
  
  logger.info('Application started');
  
  runApp(MyApp());
}

void exportMetrics(List<Metric> metrics) {
  // Export to your monitoring system
  // e.g., send to CloudWatch, Datadog, Prometheus, etc.
}
```

## Advanced Topics

### Custom Metric Collectors

Create custom metrics for your domain:

```dart
class CartMetrics {
  static void trackAddToCart(String productId, int quantity) {
    JMetrics.incrementCounter('cart.item_added', tags: {
      'productId': productId,
    });
    JMetrics.recordHistogram('cart.quantity', quantity);
  }
  
  static void trackCheckout(double amount) {
    JMetrics.incrementCounter('cart.checkout');
    JMetrics.recordHistogram('cart.amount', amount);
  }
}
```

### Log Aggregation

For production systems, integrate with log aggregation services:

- **AWS CloudWatch**: Use CloudWatch Logs for centralized logging
- **Datadog**: Send structured logs to Datadog
- **Splunk**: Forward logs to Splunk for analysis
- **ELK Stack**: Use Elasticsearch, Logstash, and Kibana

### Alerting

Set up alerts based on metrics and logs:

```dart
// Monitor error rates
final errorCount = JMetrics.getMetricsByName('login.failed').length;
if (errorCount > threshold) {
  sendAlert('High login failure rate');
}
```

## Troubleshooting

### Logs Not Appearing

- Ensure you're in debug mode or have configured proper output
- Check that log level is appropriate (e.g., debug logs won't show if minLevel is info)

### Correlation IDs Not Propagating

- Ensure you're using `runWithCorrelation` for async operations
- All async operations must be within the correlation context

### Metrics Not Being Recorded

- Verify `JMetrics.enable()` has been called
- Check that metrics collection hasn't been disabled
- Ensure observer is attached if tracking automatic metrics

## References

- [JObserver Documentation](./REPOSITORY_ANALYSIS.md#6-observability--operational-readiness)
- [Error Handling Guide](./ERROR_HANDLING_GUIDE.md)
- [Testing Guide](../README.md#testing)
