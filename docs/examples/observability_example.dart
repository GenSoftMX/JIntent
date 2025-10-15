// ignore_for_file: avoid_print
import 'dart:async';
import 'package:jintent/jintent.dart';

/// This example demonstrates how to use JIntent's observability features:
/// - Structured JSON logging
/// - Correlation IDs for request tracing
/// - Metrics collection
/// 
/// Run this example to see the observability features in action.

// ============================================================================
// Domain Models
// ============================================================================

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

// ============================================================================
// State
// ============================================================================

class AuthState extends JState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  @override
  List<Object?> get props => [user, isLoading, isAuthenticated];
}

// ============================================================================
// Effects
// ============================================================================

class ShowErrorEffect extends JEffect<void> {
  final String message;
  ShowErrorEffect(this.message);
}

class NavigateToHomeEffect extends JEffect<void> {}

// ============================================================================
// Intent
// ============================================================================

class LoginIntent extends JIntent<AuthState> with JIntentHelpers {
  final String username;
  final String password;
  final JStructuredLogger logger;

  LoginIntent({
    required this.username,
    required this.password,
    required this.logger,
  });

  @override
  Future<void> onInvoke() async {
    // Wrap the entire login flow in a correlation context
    await CorrelationContext.runWithCorrelation(() async {
      // Create a logger with correlation context
      final correlatedLogger = logger.withContext({
        ...?CorrelationContext.asContext,
        'username': username,
      });

      correlatedLogger.info('Login attempt started');

      // Set loading state
      update((state) => state.copyWith(isLoading: true));

      // Start timing the login operation
      final timerId = JMetrics.startTimer('login.duration', tags: {
        'flow': 'authentication',
      });

      try {
        // Simulate API call
        correlatedLogger.debug('Validating credentials');
        await _validateCredentials(username, password);

        correlatedLogger.debug('Fetching user data');
        final user = await _fetchUserData(username);

        // Stop timer on success
        JMetrics.stopTimer(timerId, tags: {'status': 'success'});

        // Track successful login
        JMetrics.incrementCounter('login.success', tags: {
          'method': 'password',
        });

        correlatedLogger.info('Login successful', context: {
          'userId': user.id,
        });

        // Update state
        update((state) => state.copyWith(
              user: user,
              isAuthenticated: true,
              isLoading: false,
            ));

        // Emit navigation effect
        emitSideEffect(NavigateToHomeEffect());
      } catch (e, stackTrace) {
        // Stop timer on error
        JMetrics.stopTimer(timerId, tags: {'status': 'error'});

        // Track failed login
        JMetrics.incrementCounter('login.failed', tags: {
          'reason': e.runtimeType.toString(),
        });

        correlatedLogger.error(
          'Login failed',
          error: e,
          stackTrace: stackTrace,
          context: {'errorType': e.runtimeType.toString()},
        );

        // Update state
        update((state) => state.copyWith(isLoading: false));

        // Emit error effect
        emitSideEffect(ShowErrorEffect('Login failed: ${e.toString()}'));
      }
    });
  }

  Future<void> _validateCredentials(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (password.length < 6) {
      throw Exception('Invalid credentials');
    }
  }

  Future<User> _fetchUserData(String username) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return User(
      id: 'user-123',
      name: username,
      email: '$username@example.com',
    );
  }
}

// ============================================================================
// Main Example
// ============================================================================

void main() async {
  print('=== JIntent Observability Example ===\n');

  // 1. Setup structured logging
  print('1. Setting up structured logging...');
  final logger = JStructuredLogger(
    serviceName: 'auth-service',
    version: '1.0.0',
    minLevel: LogLevel.debug,
    defaultContext: {
      'env': 'development',
      'region': 'us-east-1',
    },
  );

  // 2. Enable metrics collection
  print('2. Enabling metrics collection...');
  JMetrics.enable();
  JMetrics.attachToObserver();

  // 3. Create controller
  print('3. Creating controller...\n');
  final controller = JController<AuthState>(
    const AuthState(),
    effectCategory: 'auth',
  );

  // 4. Setup effect handling
  controller.effects.listen((effect) {
    if (effect is ShowErrorEffect) {
      print('[Effect] Error: ${effect.message}');
    } else if (effect is NavigateToHomeEffect) {
      print('[Effect] Navigating to home screen...');
    }
  });

  // 5. Simulate successful login
  print('--- Simulating Successful Login ---\n');
  await controller.dispatch(LoginIntent(
    username: 'testuser',
    password: 'password123',
    logger: logger,
  ));

  await Future.delayed(const Duration(milliseconds: 100));

  // 6. Simulate failed login
  print('\n--- Simulating Failed Login ---\n');
  await controller.dispatch(LoginIntent(
    username: 'baduser',
    password: 'bad',
    logger: logger,
  ));

  await Future.delayed(const Duration(milliseconds: 100));

  // 7. Display metrics summary
  print('\n--- Metrics Summary ---');
  final summary = JMetrics.getSummary();
  print('Enabled: ${summary['enabled']}');
  print('Total Metrics: ${summary['totalMetrics']}');
  print('Counters: ${summary['counterCount']}');
  print('Timers: ${summary['timerCount']}');

  print('\n--- Counter Metrics ---');
  final counters = JMetrics.getMetricsByType(MetricType.counter);
  for (final metric in counters) {
    print('${metric.name}: ${metric.value} ${metric.tags}');
  }

  print('\n--- Timer Metrics ---');
  final timers = JMetrics.getMetricsByType(MetricType.timer);
  for (final metric in timers) {
    final durationMs = (metric.value / 1000).toStringAsFixed(2);
    print('${metric.name}: ${durationMs}ms ${metric.tags}');
  }

  // 8. Export metrics (simulated)
  print('\n--- Exporting Metrics ---');
  final allMetrics = JMetrics.getMetrics();
  print('Total metrics to export: ${allMetrics.length}');
  for (final metric in allMetrics.take(5)) {
    print('  - ${metric.name}: ${metric.value}');
  }

  // 9. Demonstrate correlation ID propagation
  print('\n--- Correlation ID Propagation ---');
  await CorrelationContext.runWithCorrelation(() async {
    final id1 = CorrelationContext.current;
    print('Correlation ID in outer scope: $id1');

    await Future.delayed(const Duration(milliseconds: 10));

    final id2 = CorrelationContext.current;
    print('Correlation ID after await: $id2');
    print('IDs match: ${id1 == id2}');
  });

  // 10. Demonstrate child logger with context
  print('\n--- Child Logger with Context ---');
  final requestLogger = logger.withContext({
    'requestId': 'req-456',
    'userId': 'user-789',
  });
  requestLogger.info('Processing user request');

  // Clean up
  controller.dispose();
  JMetrics.clear();

  print('\n=== Example Complete ===');
}
