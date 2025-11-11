# Global Error Handler & Interceptor Guide

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2025-10-15  
**Applies To:** JIntent 2.1.0+

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Global Error Handling Patterns](#2-global-error-handling-patterns)
3. [Interceptor Architecture](#3-interceptor-architecture)
4. [Implementation Strategies](#4-implementation-strategies)
5. [Error Aggregation & Logging](#5-error-aggregation--logging)
6. [Production Best Practices](#6-production-best-practices)
7. [Testing Global Handlers](#7-testing-global-handlers)

---

## 1. Introduction

### 1.1 Purpose

This guide provides recommendations for implementing global error handlers and interceptors in JIntent applications. It covers centralized error handling, logging, analytics, and crash reporting strategies.

### 1.2 Why Global Error Handling?

**Benefits:**
- **Consistency:** Uniform error handling across the application
- **Observability:** Centralized error logging and monitoring
- **User Experience:** Consistent error messaging and recovery options
- **Maintenance:** Single source of truth for error handling logic
- **Debugging:** Easier to track and diagnose issues

**Use Cases:**
- Catching uncaught exceptions
- Logging all errors to analytics/crash reporting
- Transforming technical errors into user-friendly messages
- Implementing retry mechanisms
- Session management (e.g., auto-logout on auth errors)

---

## 2. Global Error Handling Patterns

### 2.1 Flutter-Level Error Handling

Catch uncaught errors at the Flutter framework level:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  // 1. Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // Log to crash reporting in production
      _globalErrorHandler.reportFlutterError(details);
    }
  };

  // 2. Catch Dart errors outside Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('❌ Uncaught error: $error');
      debugPrint('Stack trace: $stack');
    } else {
      _globalErrorHandler.reportError(error, stack);
    }
    return true; // Handled
  };

  // 3. Configure JIntent error handling
  _configureJIntentErrorHandling();

  runApp(MyApp());
}
```

### 2.2 JIntent Global Error Handler

Create a centralized error handler for your application:

```dart
import 'package:jintent/jintent.dart';
import 'package:flutter/foundation.dart';

/// Global error handler singleton
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final _errorLog = <ErrorRecord>[];
  final _errorController = StreamController<ErrorRecord>.broadcast();
  
  Stream<ErrorRecord> get errors => _errorController.stream;
  List<ErrorRecord> get recentErrors => List.unmodifiable(_errorLog);

  /// Report a Flutter framework error
  void reportFlutterError(FlutterErrorDetails details) {
    final record = ErrorRecord(
      error: details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework',
      timestamp: DateTime.now(),
    );

    _logError(record);
    _sendToCrashReporting(record);
    _emitErrorEffect(record);
  }

  /// Report a Dart error
  void reportError(Object error, StackTrace? stackTrace) {
    final record = ErrorRecord(
      error: error,
      stackTrace: stackTrace,
      context: 'Dart Runtime',
      timestamp: DateTime.now(),
    );

    _logError(record);
    _sendToCrashReporting(record);
    _emitErrorEffect(record);
  }

  /// Report an application error (from Either)
  void reportAppError(Exception error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    final record = ErrorRecord(
      error: error,
      stackTrace: stackTrace,
      context: context ?? 'Application',
      timestamp: DateTime.now(),
    );

    _logError(record);
    
    // Only send certain errors to crash reporting
    if (_shouldReportToCrashReporting(error)) {
      _sendToCrashReporting(record);
    }
    
    _emitErrorEffect(record);
  }

  void _logError(ErrorRecord record) {
    _errorLog.add(record);
    _errorController.add(record);

    // Keep only recent errors (last 100)
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ Error: ${record.error.runtimeType}');
      debugPrint('Context: ${record.context}');
      debugPrint('Message: ${record.error}');
      if (record.stackTrace != null) {
        debugPrint('Stack: ${record.stackTrace}');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  void _sendToCrashReporting(ErrorRecord record) {
    if (kReleaseMode) {
      // Send to your crash reporting service
      // CrashReporting.instance.recordError(
      //   record.error,
      //   record.stackTrace,
      //   reason: record.context,
      // );
    }
  }

  void _emitErrorEffect(ErrorRecord record) {
    // Emit appropriate error effect based on error type
    // This requires access to the app controller
    // See section 2.3 for implementation
  }

  bool _shouldReportToCrashReporting(Object error) {
    // Don't report expected errors like validation failures
    if (error is ValidationException) return false;
    if (error is AuthenticationException) return false;
    
    // Report unexpected system errors
    return true;
  }

  void dispose() {
    _errorController.close();
  }
}

class ErrorRecord {
  final Object error;
  final StackTrace? stackTrace;
  final String context;
  final DateTime timestamp;

  ErrorRecord({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.timestamp,
  });
}
```

### 2.3 Integrating with JController

Connect the global error handler to your application controller:

```dart
class AppController extends JController<AppState> {
  AppController() : super(AppState.initial()) {
    // Subscribe to global errors
    _globalErrorHandler.errors.listen(_handleGlobalError);
  }

  void _handleGlobalError(ErrorRecord record) {
    // Determine error severity and user message
    final userMessage = _getUserMessage(record.error);
    final severity = _getErrorSeverity(record.error);

    // Update state
    update((state) => state.copyWith(
      hasGlobalError: true,
      lastError: userMessage,
      errorTimestamp: record.timestamp,
    ));

    // Emit appropriate error effect
    if (severity == ErrorSeverity.critical) {
      emitSideEffect(ShowErrorDialogEffect(
        title: 'Critical Error',
        message: userMessage,
      ));
    } else {
      emitSideEffect(ShowSnackbarEffect(
        message: userMessage,
        severity: severity,
      ));
    }

    // Handle special cases
    if (record.error is AuthenticationException) {
      // Force logout
      emitSideEffect(LogoutEffect());
    }
  }

  String _getUserMessage(Object error) {
    if (error is AppException) {
      return error.message;
    } else if (error is NetworkException) {
      return 'Network error. Please check your connection.';
    } else if (error is TimeoutException) {
      return 'Request timeout. Please try again.';
    } else {
      return 'An unexpected error occurred.';
    }
  }

  ErrorSeverity _getErrorSeverity(Object error) {
    if (error is ValidationException) return ErrorSeverity.warning;
    if (error is NetworkException) return ErrorSeverity.warning;
    if (error is AuthenticationException) return ErrorSeverity.error;
    return ErrorSeverity.critical;
  }
}
```

### 2.4 Configure Either Error Logging

Configure the Either monad to report all Left creations:

```dart
void _configureJIntentErrorHandling() {
  // Configure Either error logging
  EitherConfig.configureLogger((error) {
    _globalErrorHandler.reportAppError(
      error as Exception,
      context: 'Either monad',
    );
  });

  // Configure unhandled effect strategy
  JEffectsConfig().unhandledStrategy = kDebugMode
      ? UnhandledEffectStrategy.throwError
      : UnhandledEffectStrategy.warnAndAutoComplete;
}
```

---

## 3. Interceptor Architecture

### 3.1 Intent Interceptor

Intercept all intents for logging and error tracking:

```dart
/// Intercepts all intents for logging and error handling
class ErrorTrackingIntent<S extends JState> extends JIntent<S> {
  final JIntent<S> _wrappedIntent;
  final String intentName;

  ErrorTrackingIntent(this._wrappedIntent, this.intentName);

  @override
  Future<void> onInvoke() async {
    try {
      _analytics.logIntentStarted(intentName);
      await _wrappedIntent.onInvoke();
      _analytics.logIntentCompleted(intentName);
    } catch (e, stack) {
      _analytics.logIntentFailed(intentName, e);
      _globalErrorHandler.reportError(e, stack);
      rethrow;
    }
  }
}

// Extension to wrap intents easily
extension IntentErrorTracking<S extends JState> on JIntent<S> {
  JIntent<S> withErrorTracking(String intentName) {
    return ErrorTrackingIntent(this, intentName);
  }
}

// Usage
controller.intent(
  LoginIntent(email, password)
    .withErrorTracking('LoginIntent'),
);
```

### 3.2 Use Case Interceptor

Wrap use cases to track errors:

```dart
/// Decorator for use cases that adds error tracking
class ErrorTrackingUseCase<I, O> extends JUseCase<I, O> {
  final JUseCase<I, O> _wrappedUseCase;
  final String useCaseName;

  ErrorTrackingUseCase(this._wrappedUseCase, this.useCaseName);

  @override
  Future<Either<Exception, O>> run(I input) async {
    try {
      _analytics.logUseCaseStarted(useCaseName);
      
      final result = await _wrappedUseCase.run(input);
      
      result.fold(
        (error) {
          _analytics.logUseCaseFailed(useCaseName, error);
          _globalErrorHandler.reportAppError(
            error,
            context: 'UseCase: $useCaseName',
          );
        },
        (value) {
          _analytics.logUseCaseCompleted(useCaseName);
        },
      );
      
      return result;
    } catch (e, stack) {
      _analytics.logUseCaseException(useCaseName, e);
      _globalErrorHandler.reportError(e, stack);
      return Left(SystemException('Use case failed'));
    }
  }
}

// Extension to wrap use cases easily
extension UseCaseErrorTracking<I, O> on JUseCase<I, O> {
  JUseCase<I, O> withErrorTracking(String name) {
    return ErrorTrackingUseCase(this, name);
  }
}
```

### 3.3 Repository Interceptor

Intercept repository calls for error handling:

```dart
/// Repository decorator that adds error handling and logging
class ErrorHandlingRepository<T> {
  final T _repository;
  final String repositoryName;

  ErrorHandlingRepository(this._repository, this.repositoryName);

  Future<Either<Exception, R>> execute<R>(
    String operationName,
    Future<Either<Exception, R>> Function() operation,
  ) async {
    try {
      _analytics.logRepositoryOperation(repositoryName, operationName);
      
      final result = await operation();
      
      result.fold(
        (error) {
          _analytics.logRepositoryError(
            repositoryName,
            operationName,
            error,
          );
          _globalErrorHandler.reportAppError(
            error,
            context: 'Repository: $repositoryName.$operationName',
          );
        },
        (_) {
          _analytics.logRepositorySuccess(repositoryName, operationName);
        },
      );
      
      return result;
    } catch (e, stack) {
      _analytics.logRepositoryException(
        repositoryName,
        operationName,
        e,
      );
      _globalErrorHandler.reportError(e, stack);
      return Left(SystemException('Repository operation failed'));
    }
  }
}

// Usage
class UserRepositoryImpl implements UserRepository {
  final ErrorHandlingRepository<UserRepositoryImpl> _errorHandler;
  
  UserRepositoryImpl() 
    : _errorHandler = ErrorHandlingRepository(this, 'UserRepository');

  @override
  Future<Either<Exception, User>> getUser(String id) {
    return _errorHandler.execute(
      'getUser',
      () => _doGetUser(id),
    );
  }

  Future<Either<Exception, User>> _doGetUser(String id) async {
    // Actual implementation
  }
}
```

---

## 4. Implementation Strategies

### 4.1 Dependency Injection Setup

Register global error handler in your DI container:

```dart
void setupDependencyInjection() {
  // Singleton error handler
  sl.registerLazySingleton(() => GlobalErrorHandler());
  
  // Repositories with error tracking
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(sl<ApiClient>())
      .withErrorTracking('UserRepository'),
  );
  
  // Use cases with error tracking
  sl.registerFactory<LoginUseCase>(
    () => LoginUseCase(sl<AuthRepository>())
      .withErrorTracking('LoginUseCase'),
  );
  
  // Controllers
  sl.registerFactory<AppController>(
    () => AppController(
      loginUseCase: sl<LoginUseCase>(),
      globalErrorHandler: sl<GlobalErrorHandler>(),
    ),
  );
}
```

### 4.2 Error Boundary Widget

Create an error boundary widget for graceful UI error handling:

```dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, VoidCallback retry)? errorBuilder;

  const ErrorBoundary({
    required this.child,
    this.errorBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(
        _error!,
        () => setState(() => _error = null),
      ) ?? _defaultErrorWidget(_error!);
    }

    return ErrorWidget.builder = (FlutterErrorDetails details) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _error = details.exception);
        }
      });
      return Container();
    };

    return widget.child;
  }

  Widget _defaultErrorWidget(Object error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'We\'re sorry for the inconvenience',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() => _error = null),
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage in main app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ErrorBoundary(
        child: HomePage(),
      ),
    );
  }
}
```

### 4.3 Global Effect Handler

Create a global effect handler that processes all error effects:

```dart
class GlobalEffectHandler extends JSideEffectHandler<AppState> {
  GlobalEffectHandler(super.controller) {
    // Register all error effect handlers
    register<ShowSnackbarEffect>(_handleSnackbar);
    register<ShowErrorDialogEffect>(_handleErrorDialog);
    register<ShowValidationErrorEffect>(_handleValidationError);
    register<ShowNetworkErrorEffect>(_handleNetworkError);
    
    // Register other effects
    register<NavigateToEffect>(_handleNavigation);
    register<LogoutEffect>(_handleLogout);
  }

  Future<void> _handleSnackbar(
    ShowSnackbarEffect effect,
    JController<AppState> controller,
    BuildContext context,
  ) async {
    // Log to analytics
    _analytics.logErrorShown(
      type: 'snackbar',
      message: effect.message,
      severity: effect.severity.name,
    );

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForSeverity(effect.severity),
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Expanded(child: Text(effect.message)),
          ],
        ),
        backgroundColor: _getColorForSeverity(effect.severity),
        duration: Duration(seconds: effect.severity == ErrorSeverity.error ? 5 : 3),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    effect.complete(null);
  }

  Future<void> _handleErrorDialog(
    ShowErrorDialogEffect effect,
    JController<AppState> controller,
    BuildContext context,
  ) async {
    // Log to analytics
    _analytics.logErrorShown(
      type: 'dialog',
      title: effect.title,
      message: effect.message,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text(effect.title)),
          ],
        ),
        content: Text(effect.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(effect.actionLabel ?? 'OK'),
          ),
        ],
      ),
    );

    effect.complete(result ?? false);
  }

  // ... other handlers

  Color _getColorForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData _getIconForSeverity(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.cancel;
    }
  }
}
```

---

## 5. Error Aggregation & Logging

### 5.1 Error Metrics

Track error metrics for monitoring:

```dart
class ErrorMetrics {
  final _errorCounts = <String, int>{};
  final _errorTrends = <DateTime, int>{};

  void recordError(String errorType) {
    _errorCounts[errorType] = (_errorCounts[errorType] ?? 0) + 1;
    
    final now = DateTime.now();
    final hourKey = DateTime(now.year, now.month, now.day, now.hour);
    _errorTrends[hourKey] = (_errorTrends[hourKey] ?? 0) + 1;
  }

  Map<String, int> getErrorCounts() => Map.unmodifiable(_errorCounts);
  
  Map<DateTime, int> getErrorTrends() => Map.unmodifiable(_errorTrends);
  
  int getTotalErrors() => _errorCounts.values.fold(0, (a, b) => a + b);
  
  String getMostCommonError() {
    if (_errorCounts.isEmpty) return 'None';
    
    return _errorCounts.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  }
}
```

### 5.2 Analytics Integration

Integrate with analytics services:

```dart
class AnalyticsService {
  void logIntentStarted(String intentName) {
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'intent_started',
    //   parameters: {'intent_name': intentName},
    // );
  }

  void logIntentFailed(String intentName, Object error) {
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'intent_failed',
    //   parameters: {
    //     'intent_name': intentName,
    //     'error_type': error.runtimeType.toString(),
    //     'error_message': error.toString(),
    //   },
    // );
  }

  void logErrorShown(String type, String message, {String? severity}) {
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'error_shown',
    //   parameters: {
    //     'error_type': type,
    //     'message': message,
    //     'severity': severity ?? 'unknown',
    //   },
    // );
  }

  // ... more logging methods
}
```

### 5.3 Crash Reporting

Integrate with crash reporting services:

```dart
class CrashReporting {
  static final CrashReporting _instance = CrashReporting._internal();
  factory CrashReporting() => _instance;
  CrashReporting._internal();

  void initialize() {
    // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  }

  void recordError(Object error, StackTrace? stackTrace, {String? reason}) {
    if (kReleaseMode) {
      // FirebaseCrashlytics.instance.recordError(
      //   error,
      //   stackTrace,
      //   reason: reason,
      // );
    }
  }

  void logFlutterError(FlutterErrorDetails details) {
    if (kReleaseMode) {
      // FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  }

  void setUserIdentifier(String userId) {
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  void log(String message) {
    // FirebaseCrashlytics.instance.log(message);
  }
}
```

---

## 6. Production Best Practices

### 6.1 Error Sampling

Implement error sampling to reduce costs:

```dart
class ErrorSampler {
  final double sampleRate;
  final Random _random = Random();

  ErrorSampler({this.sampleRate = 1.0});

  bool shouldSample() {
    return _random.nextDouble() < sampleRate;
  }
}

// Usage in GlobalErrorHandler
void _sendToCrashReporting(ErrorRecord record) {
  if (kReleaseMode && _sampler.shouldSample()) {
    CrashReporting.instance.recordError(
      record.error,
      record.stackTrace,
      reason: record.context,
    );
  }
}
```

### 6.2 Error Deduplication

Deduplicate similar errors:

```dart
class ErrorDeduplicator {
  final _recentErrors = <String, DateTime>{};
  final Duration dedupWindow;

  ErrorDeduplicator({this.dedupWindow = const Duration(minutes: 5)});

  bool isDuplicate(ErrorRecord record) {
    final key = _getErrorKey(record);
    final lastSeen = _recentErrors[key];

    if (lastSeen != null) {
      final elapsed = DateTime.now().difference(lastSeen);
      if (elapsed < dedupWindow) {
        return true; // Duplicate within window
      }
    }

    _recentErrors[key] = DateTime.now();
    return false;
  }

  String _getErrorKey(ErrorRecord record) {
    return '${record.error.runtimeType}:${record.context}';
  }

  void cleanup() {
    final cutoff = DateTime.now().subtract(dedupWindow);
    _recentErrors.removeWhere((key, time) => time.isBefore(cutoff));
  }
}
```

### 6.3 Error Rate Limiting

Prevent error storms:

```dart
class ErrorRateLimiter {
  final int maxErrorsPerMinute;
  final _errorTimestamps = <DateTime>[];

  ErrorRateLimiter({this.maxErrorsPerMinute = 60});

  bool allowError() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));

    // Remove old timestamps
    _errorTimestamps.removeWhere((t) => t.isBefore(oneMinuteAgo));

    // Check rate limit
    if (_errorTimestamps.length >= maxErrorsPerMinute) {
      return false; // Rate limited
    }

    _errorTimestamps.add(now);
    return true;
  }
}

// Usage
void reportError(Object error, StackTrace? stackTrace) {
  if (!_rateLimiter.allowError()) {
    if (kDebugMode) {
      debugPrint('⚠️ Error rate limited');
    }
    return;
  }

  // Process error
  _doReportError(error, stackTrace);
}
```

### 6.4 Sensitive Data Filtering

Filter sensitive data from error reports:

```dart
class SensitiveDataFilter {
  static final _patterns = [
    RegExp(r'\b\d{16}\b'), // Credit card numbers
    RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), // Emails
    RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), // SSN
    RegExp(r'password["\s:=]+[^"\s]+', caseSensitive: false), // Passwords
    RegExp(r'token["\s:=]+[^"\s]+', caseSensitive: false), // Tokens
  ];

  static String filter(String input) {
    var filtered = input;
    
    for (final pattern in _patterns) {
      filtered = filtered.replaceAll(pattern, '[REDACTED]');
    }
    
    return filtered;
  }

  static ErrorRecord filterRecord(ErrorRecord record) {
    return ErrorRecord(
      error: Exception(filter(record.error.toString())),
      stackTrace: record.stackTrace,
      context: filter(record.context),
      timestamp: record.timestamp,
    );
  }
}
```

---

## 7. Testing Global Handlers

### 7.1 Unit Testing

Test global error handler in isolation:

```dart
void main() {
  group('GlobalErrorHandler', () {
    late GlobalErrorHandler handler;

    setUp(() {
      handler = GlobalErrorHandler();
    });

    tearDown(() {
      handler.dispose();
    });

    test('logs errors to error stream', () async {
      final errors = <ErrorRecord>[];
      handler.errors.listen(errors.add);

      handler.reportError(Exception('Test error'), null);

      await Future.delayed(Duration(milliseconds: 100));

      expect(errors.length, 1);
      expect(errors.first.error.toString(), contains('Test error'));
    });

    test('maintains recent error history', () {
      handler.reportError(Exception('Error 1'), null);
      handler.reportError(Exception('Error 2'), null);

      expect(handler.recentErrors.length, 2);
    });

    test('respects error history limit', () {
      for (int i = 0; i < 150; i++) {
        handler.reportError(Exception('Error $i'), null);
      }

      expect(handler.recentErrors.length, lessThanOrEqualTo(100));
    });
  });
}
```

### 7.2 Integration Testing

Test error flow through the entire system:

```dart
void main() {
  testWidgets('Global error handler displays errors', (tester) async {
    final controller = AppController();
    final handler = GlobalEffectHandler(controller);

    await tester.pumpWidget(
      MaterialApp(
        home: JControllerListener<AppState>(
          controller: controller,
          effectHandler: handler,
          builder: (context, state) => HomePage(),
        ),
      ),
    );

    // Trigger an error
    controller.intent(LoginIntent(
      email: 'invalid',
      password: 'wrong',
    ));

    await tester.pumpAndSettle();

    // Verify error is shown
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
```

---

## 8. Complete Example

Here's a complete example integrating all concepts:

```dart
// main.dart
void main() {
  // Setup global error handling
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      GlobalErrorHandler().reportFlutterError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    GlobalErrorHandler().reportError(error, stack);
    return true;
  };

  // Configure JIntent
  EitherConfig.configureLogger((error) {
    GlobalErrorHandler().reportAppError(
      error as Exception,
      context: 'Either monad',
    );
  });

  JEffectsConfig().unhandledStrategy = kDebugMode
      ? UnhandledEffectStrategy.throwError
      : UnhandledEffectStrategy.warnAndAutoComplete;

  // Setup DI
  setupDependencyInjection();

  runApp(MyApp());
}

// app.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JIntent App',
      home: ErrorBoundary(
        child: JControllerListener<AppState>(
          controller: sl<AppController>(),
          effectHandler: GlobalEffectHandler(sl<AppController>()),
          builder: (context, state) => HomePage(state),
        ),
      ),
    );
  }
}
```

---

## Additional Resources

### Related Documentation
- [Error Handling Guide](./ERROR_HANDLING_GUIDE.md) - Comprehensive error handling patterns
- [Effects Guide](../doc/effects.md) - Side effects system documentation
- [Security Guide](./SECURITY_GUIDE.md) - Secure error handling practices
- [Error Handling Examples](./examples/error_handling_examples.md) - Code examples

### External Resources
- [Flutter Error Handling](https://docs.flutter.dev/testing/errors)
- [Dart Error Handling](https://dart.dev/guides/language/language-tour#exceptions)

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** 2025-11-15  
**Maintained By:** JIntent Core Team

---

**Quick Links:**
- [← Back to Error Handling Guide](./ERROR_HANDLING_GUIDE.md)
- [← Documentation Index](./README.md)
- [Effects Guide →](../doc/effects.md)
