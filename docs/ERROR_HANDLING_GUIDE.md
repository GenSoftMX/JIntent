# JIntent Error Handling Guide

**Version:** 1.0  
**Status:** Active  
**Last Updated:** 2025-10-15  
**Applies To:** JIntent 2.1.0+

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Error Handling Philosophy](#2-error-handling-philosophy)
3. [Either Pattern](#3-either-pattern)
4. [Exception Patterns](#4-exception-patterns)
5. [Global Error Handling](#5-global-error-handling)
6. [Error Handling in Layers](#6-error-handling-in-layers)
7. [Error Handling with Side Effects](#7-error-handling-with-side-effects)
8. [Best Practices](#8-best-practices)
9. [Common Patterns](#9-common-patterns)
10. [Testing Error Scenarios](#10-testing-error-scenarios)

---

## 1. Introduction

### 1.1 Purpose

This guide provides comprehensive guidance on error handling patterns in JIntent applications. It covers both functional (Either monad) and imperative (exceptions) approaches to error management.

### 1.2 Goals

- **Type Safety:** Compile-time guarantee that errors are handled
- **Explicit Errors:** Clear indication when operations can fail
- **Fail Securely:** Errors don't expose sensitive information
- **Testability:** Easy to test error scenarios
- **User Experience:** Graceful error handling with helpful messages

### 1.3 Dual Approach

JIntent uses two complementary error handling strategies:

1. **Either Monad (Functional):** For expected errors in domain layer
2. **Dart Exceptions (Imperative):** For unexpected errors and framework issues

---

## 2. Error Handling Philosophy

### 2.1 Expected vs. Unexpected Errors

#### Expected Errors (Use Either)

Errors that are **part of normal business logic**:
- Validation failures
- Business rule violations
- Resource not found
- Permission denied
- Network timeouts (expected)

**Characteristics:**
- Can be anticipated
- Part of the API contract
- Should be handled explicitly
- Use `Either<Exception, T>`

#### Unexpected Errors (Use Exceptions)

Errors that indicate **programming errors or system failures**:
- Null pointer errors
- Type casting errors
- Assertion failures
- Out of memory
- System failures

**Characteristics:**
- Cannot be anticipated
- Indicate bugs or system issues
- Should crash in development, log in production
- Use Dart exceptions

### 2.2 Error Handling Layers

```
┌─────────────────────────────────────────────────────┐
│         Presentation Layer (UI/Intents)             │
│  - Handle Either results                            │
│  - Catch unexpected exceptions                      │
│  - Emit side effects for user feedback              │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│            Domain Layer (Use Cases)                  │
│  - Return Either<Exception, Result>                 │
│  - Validate inputs                                   │
│  - Apply business rules                              │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│         Data Layer (Repositories)                    │
│  - Return Either<Exception, Data>                   │
│  - Catch infrastructure errors                       │
│  - Map to domain exceptions                          │
└─────────────────────────────────────────────────────┘
```

---

## 3. Either Pattern

### 3.1 Either Basics

The `Either` type represents a value of one of two possible types:
- `Left<L, R>`: Contains an error (by convention)
- `Right<L, R>`: Contains a success value

```dart
import 'package:jintent/jintent.dart';

// Either<Error, Success>
Either<Exception, User> result = Right(user);  // Success
Either<Exception, User> result = Left(Exception('Not found'));  // Error
```

### 3.2 Creating Either Results

#### Success Case

```dart
Either<Exception, User> getUser(String id) {
  final user = _findUser(id);
  if (user != null) {
    return Right(user);  // Success
  } else {
    return Left(Exception('User not found'));  // Error
  }
}
```

#### Error Case

```dart
Future<Either<Exception, Post>> createPost(PostInput input) async {
  try {
    final post = await _api.createPost(input);
    return Right(post);
  } catch (e) {
    return Left(Exception('Failed to create post: ${e.toString()}'));
  }
}
```

### 3.3 Handling Either Results

#### Using fold()

```dart
final result = await getUser('123');

result.fold(
  // Left handler (error)
  (exception) {
    print('Error: ${exception.toString()}');
  },
  // Right handler (success)
  (user) {
    print('Success: ${user.name}');
  },
);
```

#### Using isLeft / isRight

```dart
final result = await getUser('123');

if (result.isLeft) {
  // Handle error
  final error = result.left!;
  print('Error: $error');
} else {
  // Handle success
  final user = result.right!;
  print('User: ${user.name}');
}
```

### 3.4 Chaining Either Operations

#### Example: Multiple Operations

```dart
Future<Either<Exception, Receipt>> processPayment(PaymentInput input) async {
  // Step 1: Validate card
  final cardResult = await _validateCard(input.cardNumber);
  if (cardResult.isLeft) return Left(cardResult.left!);
  
  // Step 2: Charge card
  final chargeResult = await _chargeCard(cardResult.right!, input.amount);
  if (chargeResult.isLeft) return Left(chargeResult.left!);
  
  // Step 3: Generate receipt
  final receiptResult = await _generateReceipt(chargeResult.right!);
  return receiptResult;
}
```

#### Using fold for Chaining

```dart
Future<Either<Exception, Receipt>> processPayment(PaymentInput input) async {
  return (await _validateCard(input.cardNumber)).fold(
    (error) => Left(error),
    (card) async => (await _chargeCard(card, input.amount)).fold(
      (error) => Left(error),
      (charge) => _generateReceipt(charge),
    ),
  );
}
```

### 3.5 Either in Use Cases

```dart
import 'package:jintent/jintent.dart';

class GetUserProfileUseCase extends JUseCase<String, UserProfile> {
  final UserRepository _repository;

  GetUserProfileUseCase(this._repository) {
    addValidator(_validateUserId);
  }

  // Validator returns Either
  Either<Exception, String> _validateUserId(String userId) {
    if (userId.trim().isEmpty) {
      return Left(Exception('User ID cannot be empty'));
    }
    return Right(userId);
  }

  @override
  Future<Either<Exception, UserProfile>> run(String userId) async {
    try {
      // Repository returns Either
      final userResult = await _repository.getUser(userId);
      
      return userResult.fold(
        (error) => Left(error),
        (user) async {
          // Get additional profile data
          final profileResult = await _repository.getProfile(user.id);
          
          return profileResult.fold(
            (error) => Left(error),
            (profile) => Right(UserProfile.from(user, profile)),
          );
        },
      );
    } catch (e) {
      return Left(Exception('Failed to load user profile'));
    }
  }
}
```

---

## 4. Exception Patterns

### 4.1 Custom Exception Hierarchy

Define custom exceptions for different error types:

```dart
/// Base exception for all application errors
abstract class AppException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  AppException(this.message, this.code, [this.details]);

  @override
  String toString() => message;
}

/// Validation errors (user input)
class ValidationException extends AppException {
  ValidationException(String message, [dynamic details])
      : super(message, 'VALIDATION_ERROR', details);
}

/// Resource not found errors
class NotFoundException extends AppException {
  NotFoundException(String message, [dynamic details])
      : super(message, 'NOT_FOUND', details);
}

/// Network-related errors
class NetworkException extends AppException {
  NetworkException(String message, [dynamic details])
      : super(message, 'NETWORK_ERROR', details);
}

/// Authentication/authorization errors
class AuthenticationException extends AppException {
  AuthenticationException(String message, [dynamic details])
      : super(message, 'AUTH_ERROR', details);
}

/// Business logic errors
class BusinessRuleException extends AppException {
  BusinessRuleException(String message, [dynamic details])
      : super(message, 'BUSINESS_RULE_ERROR', details);
}

/// System/infrastructure errors
class SystemException extends AppException {
  SystemException(String message, [dynamic details])
      : super(message, 'SYSTEM_ERROR', details);
}
```

### 4.2 Using Custom Exceptions

```dart
class CreateOrderUseCase extends JUseCase<OrderInput, Order> {
  CreateOrderUseCase() {
    addValidator(_validateInput);
  }

  Either<Exception, OrderInput> _validateInput(OrderInput input) {
    if (input.items.isEmpty) {
      return Left(ValidationException('Order must have at least one item'));
    }
    
    if (input.totalAmount <= 0) {
      return Left(ValidationException('Order total must be greater than zero'));
    }
    
    return Right(input);
  }

  @override
  Future<Either<Exception, Order>> run(OrderInput input) async {
    try {
      // Check inventory
      for (final item in input.items) {
        final available = await _inventory.checkAvailability(item.productId);
        if (available < item.quantity) {
          return Left(BusinessRuleException(
            'Insufficient inventory for ${item.productName}',
          ));
        }
      }

      // Create order
      final order = await _repository.createOrder(input);
      return Right(order);
    } on NetworkException catch (e) {
      return Left(NetworkException('Failed to create order: ${e.message}'));
    } catch (e) {
      return Left(SystemException('Unexpected error creating order'));
    }
  }
}
```

### 4.3 Framework Exceptions

JIntent uses standard Dart exceptions for framework-level errors:

```dart
// ArgumentError for invalid arguments
void emitSideEffect(JEffect effect) {
  if (effect == null) {
    throw ArgumentError.notNull('effect');
  }
  // ...
}

// TimeoutException for effect timeouts
Future<T> emitAndWaitSideEffect<T>(
  JEffect<T> effect, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  if (timeout.isNegative) {
    throw ArgumentError.value(timeout, 'timeout', 'Must be non-negative');
  }
  
  final timer = Timer(timeout, () {
    if (!effect.isCompleted) {
      effect.completeError(TimeoutException('Effect timeout'));
    }
  });
  
  try {
    return await effect.result;
  } finally {
    timer.cancel();
  }
}

// StateError for invalid state
void _dispatchIntent(JIntent intent) {
  if (_isDisposed) {
    throw StateError('Cannot dispatch intent after controller is disposed');
  }
  // ...
}
```

---

## 5. Global Error Handling

### 5.1 Either Error Logger

Configure global error logging for `Left` creations:

```dart
import 'package:jintent/jintent.dart';
import 'package:flutter/foundation.dart';

void configureGlobalErrorHandling() {
  // Configure Either error logger (debug mode only)
  EitherConfig.configureLogger((error) {
    if (kDebugMode) {
      // Detailed logging in debug mode
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ Error: ${error.runtimeType}');
      debugPrint('Message: $error');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else {
      // Production logging (analytics/crash reporting)
      if (error is AppException) {
        _analytics.logError(
          code: error.code,
          message: error.message,
        );
      } else {
        _analytics.logError(
          code: 'UNKNOWN',
          message: 'An error occurred',
        );
      }
    }
  });
}
```

### 5.2 Flutter Error Handling

Catch uncaught errors at the Flutter level:

```dart
import 'package:flutter/material.dart';

void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // Show error in debug mode
      FlutterError.presentError(details);
    } else {
      // Log to crash reporting in production
      _crashReporting.logFlutterError(details);
    }
  };

  // Catch other Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
    } else {
      _crashReporting.logError(error, stack);
    }
    return true;
  };

  // Configure JIntent error handling
  configureGlobalErrorHandling();

  runApp(MyApp());
}
```

### 5.3 Global Error Handler Intent

Create a centralized error handler:

```dart
class GlobalErrorHandlerIntent extends JIntent<AppState> {
  final Object error;
  final StackTrace? stackTrace;

  GlobalErrorHandlerIntent(this.error, [this.stackTrace]);

  @override
  Future<void> onInvoke() async {
    // Log error
    _logger.error('Global error', error: error, stackTrace: stackTrace);

    // Determine error type and show appropriate message
    String message;
    if (error is AppException) {
      message = error.message;
    } else if (error is NetworkException) {
      message = 'Network error. Please check your connection.';
    } else if (error is TimeoutException) {
      message = 'Request timeout. Please try again.';
    } else {
      message = 'An unexpected error occurred.';
    }

    // Show error to user
    controller.emitSideEffect(ShowErrorEffect(message: message));

    // Update state
    controller.update((state) => state.copyWith(
      hasError: true,
      errorMessage: message,
    ));
  }
}
```

---

## 6. Error Handling in Layers

### 6.1 Presentation Layer (Intents)

```dart
class LoginIntent extends JIntent<AuthState> {
  final String email;
  final String password;

  LoginIntent({required this.email, required this.password});

  @override
  Future<void> onInvoke() async {
    // Set loading state
    controller.update((state) => state.copyWith(isLoading: true));

    // Call use case
    final result = await _loginUseCase(
      LoginInput(email: email, password: password),
    );

    // Handle result
    result.fold(
      // Error case
      (exception) {
        controller.update((state) => state.copyWith(
          isLoading: false,
          error: exception.toString(),
        ));

        // Show error to user
        controller.emitSideEffect(
          ShowSnackbarEffect(
            message: exception.toString(),
            type: SnackbarType.error,
          ),
        );
      },
      // Success case
      (authToken) {
        controller.update((state) => state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: authToken.userId,
          error: null,
        ));

        // Navigate to home
        controller.emitSideEffect(NavigateToHomeEffect());
      },
    );
  }
}
```

### 6.2 Domain Layer (Use Cases)

```dart
class LoginUseCase extends JUseCase<LoginInput, AuthToken> {
  final AuthRepository _repository;

  LoginUseCase(this._repository) {
    addValidator(_validateInput);
  }

  Either<Exception, LoginInput> _validateInput(LoginInput input) {
    if (input.email.trim().isEmpty) {
      return Left(ValidationException('Email is required'));
    }

    if (input.password.isEmpty) {
      return Left(ValidationException('Password is required'));
    }

    if (!_isValidEmail(input.email)) {
      return Left(ValidationException('Invalid email format'));
    }

    return Right(input);
  }

  @override
  Future<Either<Exception, AuthToken>> run(LoginInput input) async {
    try {
      final result = await _repository.login(input.email, input.password);
      return result;
    } catch (e) {
      return Left(SystemException('Login failed'));
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
```

### 6.3 Data Layer (Repositories)

```dart
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;

  AuthRepositoryImpl(this._api);

  @override
  Future<Either<Exception, AuthToken>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await _api.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = AuthToken.fromJson(response.data);
        return Right(token);
      } else if (response.statusCode == 401) {
        return Left(AuthenticationException('Invalid credentials'));
      } else if (response.statusCode == 429) {
        return Left(BusinessRuleException('Too many attempts. Try again later.'));
      } else {
        return Left(SystemException('Login failed'));
      }
    } on SocketException {
      return Left(NetworkException('No internet connection'));
    } on TimeoutException {
      return Left(NetworkException('Request timeout'));
    } catch (e) {
      _logger.error('Unexpected error in login', error: e);
      return Left(SystemException('Login failed'));
    }
  }
}
```

---

## 7. Error Handling with Side Effects

### 7.1 Overview

JIntent's side effect system (`JEffect`) provides a clean way to handle transient UI events like errors, notifications, and confirmations. This section covers how to use side effects for error communication between the domain layer and the UI.

### 7.2 Error Effect Types

Define custom error effects to communicate different error severities:

```dart
/// Base error effect
abstract class ErrorEffect extends JFireAndForgetEffect {
  final String message;
  final ErrorSeverity severity;
  
  ErrorEffect(this.message, this.severity);
}

/// Error severity levels
enum ErrorSeverity {
  info,      // Informational messages
  warning,   // Warning messages
  error,     // Error messages that require attention
  critical,  // Critical errors that may block functionality
}

/// Show snackbar/toast error
class ShowSnackbarEffect extends ErrorEffect {
  ShowSnackbarEffect({
    required String message,
    ErrorSeverity severity = ErrorSeverity.error,
  }) : super(message, severity);
}

/// Show error dialog
class ShowErrorDialogEffect extends JDialogEffect<bool> {
  final String title;
  final String message;
  final String? actionLabel;
  
  ShowErrorDialogEffect({
    required this.title,
    required this.message,
    this.actionLabel,
  });
}

/// Show validation errors
class ShowValidationErrorEffect extends ErrorEffect {
  final Map<String, String> fieldErrors;
  
  ShowValidationErrorEffect({
    required String message,
    required this.fieldErrors,
  }) : super(message, ErrorSeverity.warning);
}

/// Network error with retry option
class ShowNetworkErrorEffect extends JDialogEffect<bool> {
  final String message;
  final VoidCallback? onRetry;
  
  ShowNetworkErrorEffect({
    required this.message,
    this.onRetry,
  });
}
```

### 7.3 Emitting Error Effects from Intents

```dart
class LoginIntent extends JIntent<AuthState> {
  final String email;
  final String password;
  final LoginUseCase _loginUseCase;

  LoginIntent(this.email, this.password, this._loginUseCase);

  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(isLoading: true));

    final result = await _loginUseCase(LoginInput(
      email: email,
      password: password,
    ));

    result.fold(
      (exception) {
        // Update state
        controller.update((state) => state.copyWith(
          isLoading: false,
          error: exception.toString(),
        ));

        // Emit appropriate error effect based on exception type
        if (exception is ValidationException) {
          controller.emitSideEffect(ShowSnackbarEffect(
            message: exception.message,
            severity: ErrorSeverity.warning,
          ));
        } else if (exception is NetworkException) {
          controller.emitSideEffect(ShowNetworkErrorEffect(
            message: 'No internet connection. Please try again.',
            onRetry: () => controller.intent(this),
          ));
        } else if (exception is AuthenticationException) {
          controller.emitSideEffect(ShowErrorDialogEffect(
            title: 'Login Failed',
            message: exception.message,
            actionLabel: 'Try Again',
          ));
        } else {
          controller.emitSideEffect(ShowSnackbarEffect(
            message: 'An unexpected error occurred',
            severity: ErrorSeverity.error,
          ));
        }
      },
      (authToken) {
        controller.update((state) => state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userId: authToken.userId,
          error: null,
        ));

        controller.emitSideEffect(NavigateToHomeEffect());
      },
    );
  }
}
```

### 7.4 Handling Error Effects in UI

Create a centralized effect handler to display errors consistently:

```dart
class AppEffectHandler extends JSideEffectHandler<AppState> {
  AppEffectHandler(super.controller) {
    register<ShowSnackbarEffect>(_handleSnackbar);
    register<ShowErrorDialogEffect>(_handleErrorDialog);
    register<ShowValidationErrorEffect>(_handleValidationError);
    register<ShowNetworkErrorEffect>(_handleNetworkError);
  }

  Future<void> _handleSnackbar(
    ShowSnackbarEffect effect,
    JController<AppState> controller,
    BuildContext context,
  ) async {
    final color = _getColorForSeverity(effect.severity);
    final icon = _getIconForSeverity(effect.severity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(effect.message)),
          ],
        ),
        backgroundColor: color,
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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(effect.title),
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

  Future<void> _handleValidationError(
    ShowValidationErrorEffect effect,
    JController<AppState> controller,
    BuildContext context,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Text(effect.message),
              ],
            ),
            if (effect.fieldErrors.isNotEmpty) ...[
              SizedBox(height: 8),
              ...effect.fieldErrors.entries.map((entry) => Text(
                '• ${entry.key}: ${entry.value}',
                style: TextStyle(fontSize: 12),
              )),
            ],
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );

    effect.complete(null);
  }

  Future<void> _handleNetworkError(
    ShowNetworkErrorEffect effect,
    JController<AppState> controller,
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Network Error'),
          ],
        ),
        content: Text(effect.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          if (effect.onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                effect.onRetry?.call();
              },
              child: Text('RETRY'),
            ),
        ],
      ),
    );

    effect.complete(result ?? false);
  }

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

### 7.5 Error Effect Best Practices

#### 1. Use Fire-and-Forget for Non-Blocking Errors

```dart
// ✅ Good - snackbar doesn't need a response
class ShowSnackbarEffect extends JFireAndForgetEffect {
  final String message;
  ShowSnackbarEffect(this.message);
}

// ❌ Bad - unnecessary dialog for simple errors
class ShowSimpleErrorEffect extends JDialogEffect<void> {
  final String message;
  ShowSimpleErrorEffect(this.message);
}
```

#### 2. Use Dialog Effects for Critical Errors

```dart
// ✅ Good - critical error needs user acknowledgment
class ShowCriticalErrorEffect extends JDialogEffect<bool> {
  final String message;
  ShowCriticalErrorEffect(this.message);
}
```

#### 3. Provide Contextual Error Messages

```dart
// ❌ Bad
controller.emitSideEffect(ShowSnackbarEffect('Error'));

// ✅ Good
controller.emitSideEffect(ShowSnackbarEffect(
  message: 'Failed to save user profile. Please check your internet connection.',
  severity: ErrorSeverity.error,
));
```

#### 4. Include Recovery Actions

```dart
// ✅ Good - provide retry mechanism
controller.emitSideEffect(ShowNetworkErrorEffect(
  message: 'Unable to load data',
  onRetry: () => controller.intent(LoadDataIntent()),
));
```

#### 5. Complete Effects Properly

```dart
// ✅ Good - always complete effects
Future<void> _handleError(
  ShowErrorEffect effect,
  JController controller,
  BuildContext context,
) async {
  // Show error
  await showDialog(...);
  
  // Complete the effect
  effect.complete(null);
}

// ❌ Bad - forgot to complete
Future<void> _handleError(
  ShowErrorEffect effect,
  JController controller,
  BuildContext context,
) async {
  await showDialog(...);
  // Effect never completed - will cause warnings
}
```

### 7.6 Error Effect Timeout Handling

Configure timeout behavior for awaitable error effects:

```dart
class ConfirmDangerousActionIntent extends JIntent<AppState> {
  @override
  Future<void> onInvoke() async {
    try {
      final confirmed = await controller.emitAndWaitSideEffect(
        ShowConfirmationDialogEffect(
          title: 'Delete Account?',
          message: 'This action cannot be undone.',
        ),
        timeout: Duration(seconds: 30),
      );

      if (confirmed) {
        // Proceed with dangerous action
        await _deleteAccountUseCase();
      }
    } on TimeoutException {
      // User didn't respond in time
      controller.emitSideEffect(ShowSnackbarEffect(
        message: 'Confirmation timeout. Action cancelled.',
        severity: ErrorSeverity.warning,
      ));
    }
  }
}
```

### 7.7 Unhandled Effect Strategy

Configure how unhandled error effects are treated:

```dart
void main() {
  // Configure unhandled effect strategy
  JEffectsConfig().unhandledStrategy = UnhandledEffectStrategy.throwError;
  
  runApp(MyApp());
}
```

Strategies:
- **warnOnly**: Log a warning (development only)
- **warnAndAutoComplete**: Log and auto-complete with null (default)
- **throwError**: Throw an error for unhandled awaitable effects

### 7.8 Error Effect Categories

Use categories to group error effects for analytics and debugging:

```dart
class ShowErrorEffect extends JFireAndForgetEffect with JCategorizableEffect {
  final String message;
  
  ShowErrorEffect(this.message);
  
  @override
  String get category => 'error_feedback';
}

class ShowNetworkErrorEffect extends JDialogEffect<bool> with JCategorizableEffect {
  final String message;
  
  ShowNetworkErrorEffect(this.message);
  
  @override
  String get category => 'error_network';
}
```

This enables filtering in devtools and analytics:

```dart
// Track error effects by category
controller.sideEffects
  .where((effect) => effect.resolvedCategory?.startsWith('error_') ?? false)
  .listen((effect) {
    analytics.logErrorShown(
      category: effect.resolvedCategory,
      effectType: effect.runtimeType.toString(),
    );
  });
```

---

## 8. Best Practices

### 8.1 Do's ✅

#### 1. Use Either for Expected Errors

```dart
// ✅ Good
Future<Either<Exception, User>> getUser(String id) async {
  // ...
}
```

#### 2. Fail Fast with Validation

```dart
// ✅ Good
class CreateUserUseCase extends JUseCase<CreateUserInput, User> {
  CreateUserUseCase() {
    addValidator(_validateInput);  // Validate early
  }
}
```

#### 3. Provide Actionable Error Messages

```dart
// ✅ Good
return Left(ValidationException(
  'Email is required. Please enter your email address.',
));
```

#### 4. Catch Specific Exceptions

```dart
// ✅ Good
try {
  // ...
} on SocketException {
  return Left(NetworkException('No internet connection'));
} on TimeoutException {
  return Left(NetworkException('Request timeout'));
} catch (e) {
  return Left(SystemException('An error occurred'));
}
```

#### 5. Log Errors Internally

```dart
// ✅ Good
} catch (e, stackTrace) {
  _logger.error('Failed to create user', error: e, stackTrace: stackTrace);
  return Left(SystemException('Failed to create user'));
}
```

### 7.2 Don'ts ❌

#### 1. Don't Expose Internal Details

```dart
// ❌ Bad
return Left(Exception('Database query failed: $query'));

// ✅ Good
return Left(SystemException('Failed to load data'));
```

#### 2. Don't Swallow Errors

```dart
// ❌ Bad
try {
  await riskyOperation();
} catch (e) {
  // Silently ignoring error
}

// ✅ Good
try {
  await riskyOperation();
} catch (e) {
  _logger.error('Risky operation failed', error: e);
  return Left(SystemException('Operation failed'));
}
```

#### 3. Don't Use Generic Exceptions Everywhere

```dart
// ❌ Bad
return Left(Exception('Error'));

// ✅ Good
return Left(ValidationException('Email is required'));
```

#### 4. Don't Catch and Rethrow Without Adding Value

```dart
// ❌ Bad
try {
  return await operation();
} catch (e) {
  throw e;  // No value added
}

// ✅ Good - add context
try {
  return await operation();
} catch (e) {
  _logger.error('Operation failed', error: e);
  throw SystemException('Failed to complete operation');
}

// ✅ Better - return Either
try {
  final result = await operation();
  return Right(result);
} catch (e) {
  _logger.error('Operation failed', error: e);
  return Left(SystemException('Failed to complete operation'));
}
```

#### 5. Don't Ignore Error Types

```dart
// ❌ Bad - handle all errors the same
result.fold(
  (error) => print('Error'),  // Loses error type info
  (value) => print('Success'),
);

// ✅ Good - handle different error types
result.fold(
  (error) {
    if (error is ValidationException) {
      showValidationError(error.message);
    } else if (error is NetworkException) {
      showNetworkError(error.message);
    } else {
      showGenericError();
    }
  },
  (value) => handleSuccess(value),
);
```

---

## 8. Common Patterns

### 8.1 Retry Pattern

```dart
Future<Either<Exception, T>> retryOperation<T>(
  Future<Either<Exception, T>> Function() operation, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  int attempt = 0;
  
  while (attempt < maxAttempts) {
    final result = await operation();
    
    if (result.isRight) {
      return result;  // Success
    }
    
    attempt++;
    if (attempt < maxAttempts) {
      await Future.delayed(delay);
    }
  }
  
  return Left(SystemException('Operation failed after $maxAttempts attempts'));
}

// Usage
final result = await retryOperation(
  () => _repository.fetchData(),
  maxAttempts: 3,
  delay: Duration(seconds: 2),
);
```

### 8.2 Fallback Pattern

```dart
Future<Either<Exception, T>> withFallback<T>(
  Future<Either<Exception, T>> Function() primary,
  Future<Either<Exception, T>> Function() fallback,
) async {
  final primaryResult = await primary();
  
  if (primaryResult.isRight) {
    return primaryResult;
  }
  
  // Primary failed, try fallback
  _logger.info('Primary operation failed, trying fallback');
  return await fallback();
}

// Usage
final result = await withFallback(
  () => _remoteRepository.fetchData(),
  () => _localRepository.fetchCachedData(),
);
```

### 8.3 Error Recovery Pattern

```dart
class LoadDataIntent extends JIntent<DataState> {
  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(isLoading: true));

    final result = await _loadDataUseCase();

    result.fold(
      (error) async {
        // Try recovery strategies
        if (error is NetworkException) {
          // Try loading from cache
          final cachedResult = await _loadFromCache();
          
          cachedResult.fold(
            (cacheError) {
              // Both failed
              controller.update((state) => state.copyWith(
                isLoading: false,
                error: 'Unable to load data. Please check your connection.',
              ));
              controller.emitSideEffect(
                ShowErrorEffect(message: 'No internet connection'),
              );
            },
            (cachedData) {
              // Cache succeeded
              controller.update((state) => state.copyWith(
                isLoading: false,
                data: cachedData,
                isFromCache: true,
              ));
              controller.emitSideEffect(
                ShowWarningEffect(message: 'Showing cached data'),
              );
            },
          );
        } else {
          // Other errors
          controller.update((state) => state.copyWith(
            isLoading: false,
            error: error.toString(),
          ));
        }
      },
      (data) {
        // Success
        controller.update((state) => state.copyWith(
          isLoading: false,
          data: data,
          isFromCache: false,
          error: null,
        ));
      },
    );
  }
}
```

### 8.4 Error Aggregation Pattern

```dart
class ValidateFormUseCase extends JUseCase<FormInput, ValidatedForm> {
  @override
  Future<Either<Exception, ValidatedForm>> run(FormInput input) async {
    final errors = <String>[];

    // Validate each field
    if (input.name.trim().isEmpty) {
      errors.add('Name is required');
    }

    if (input.email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(input.email)) {
      errors.add('Email format is invalid');
    }

    if (input.age < 18) {
      errors.add('Must be 18 or older');
    }

    if (input.password.length < 8) {
      errors.add('Password must be at least 8 characters');
    }

    // If any errors, return aggregated
    if (errors.isNotEmpty) {
      return Left(ValidationException(
        errors.join('\n'),
        errors,  // Pass list as details
      ));
    }

    return Right(ValidatedForm.from(input));
  }
}
```

---

## 9. Common Patterns

### 9.1 Testing Either Results

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/jintent.dart';

void main() {
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LoginUseCase(mockRepository);
    });

    test('returns Left when email is empty', () async {
      final result = await useCase(LoginInput(email: '', password: 'pass123'));

      expect(result.isLeft, true);
      expect(result.left, isA<ValidationException>());
      expect(result.left.toString(), contains('Email is required'));
    });

    test('returns Left when password is empty', () async {
      final result = await useCase(
        LoginInput(email: 'test@example.com', password: ''),
      );

      expect(result.isLeft, true);
      expect(result.left, isA<ValidationException>());
    });

    test('returns Left when repository fails', () async {
      when(() => mockRepository.login(any(), any()))
          .thenAnswer((_) async => Left(NetworkException('Network error')));

      final result = await useCase(
        LoginInput(email: 'test@example.com', password: 'pass123'),
      );

      expect(result.isLeft, true);
      expect(result.left, isA<NetworkException>());
    });

    test('returns Right when login succeeds', () async {
      final token = AuthToken(userId: '123', token: 'abc');
      when(() => mockRepository.login(any(), any()))
          .thenAnswer((_) async => Right(token));

      final result = await useCase(
        LoginInput(email: 'test@example.com', password: 'pass123'),
      );

      expect(result.isRight, true);
      expect(result.right, equals(token));
    });
  });
}
```

### 9.2 Testing Intent Error Handling

```dart
void main() {
  group('LoginIntent', () {
    late AppController controller;
    late MockLoginUseCase mockUseCase;

    setUp(() {
      mockUseCase = MockLoginUseCase();
      controller = AppController(loginUseCase: mockUseCase);
    });

    test('updates state with error when use case fails', () async {
      when(() => mockUseCase.call(any()))
          .thenAnswer((_) async => Left(ValidationException('Invalid email')));

      await controller.intent(
        LoginIntent(email: 'invalid', password: 'pass'),
      );

      expect(controller.state.hasError, true);
      expect(controller.state.error, contains('Invalid email'));
    });

    test('emits error side effect when login fails', () async {
      when(() => mockUseCase.call(any()))
          .thenAnswer((_) async => Left(AuthenticationException('Wrong password')));

      final effects = <JEffect>[];
      controller.sideEffects.listen(effects.add);

      await controller.intent(
        LoginIntent(email: 'test@example.com', password: 'wrong'),
      );

      expect(effects, hasLength(1));
      expect(effects.first, isA<ShowErrorEffect>());
    });
  });
}
```

### 9.3 Testing Global Error Handler

```dart
void main() {
  group('GlobalErrorHandler', () {
    setUp(() {
      EitherConfig.configureLogger((error) {
        // Mock logger for testing
      });
    });

    test('logs errors when Left is created', () {
      final errors = <Object>[];
      EitherConfig.configureLogger(errors.add);

      final result = Left<Exception, String>(
        Exception('Test error'),
      );

      expect(errors, hasLength(1));
      expect(errors.first.toString(), contains('Test error'));
    });
  });
}
```

---

## 10. Testing Error Scenarios

### 10.1 Testing Use Case Errors

**JIntent Guides:**
- [Security Guide](./SECURITY_GUIDE.md) - Error security considerations and logging
- [API Versioning Guide](./API_VERSIONING.md) - Error handling in version migrations
- [Validation Examples](./examples/validation_examples.md) - Input validation patterns
- [Error Handling Examples](./examples/error_handling_examples.md) - Practical error handling code

**Architecture Decision Records:**
- [ADR-006: Error Handling Patterns](./adr/ADR-006-error-handling-patterns.md) - Error strategy decisions
- [ADR-007: Validation Framework](./adr/ADR-007-validation-framework.md) - Validation approach
- [ADR-005: Security Architecture](./adr/ADR-005-security-architecture.md) - Security error handling

**Project Documentation:**
- [Documentation Index](./README.md) - Complete documentation navigation
- [Exception Inventory](./EXCEPTION_INVENTORY.md) - Exception governance and catalog

### 10.2 Testing Intent Error Handling

**Example Application:**
- `example/lib/src/domain/use_cases/` - Use case error handling
- `example/lib/src/presentation/intents/` - Intent error handling
- `example/lib/src/data/repositories/` - Repository error handling

**Example Documentation:**
- [Error Handling Examples](./examples/error_handling_examples.md) - Comprehensive code samples
- [Validation Examples](./examples/validation_examples.md) - Input validation patterns

### 10.3 Testing Error Effects

```dart
void main() {
  group('Error Effect Tests', () {
    late AppController controller;
    late AppEffectHandler handler;

    setUp(() {
      controller = AppController();
      handler = AppEffectHandler(controller);
    });

    test('emits ShowSnackbarEffect when login fails', () async {
      final effects = <JEffect>[];
      controller.sideEffects.listen(effects.add);

      await controller.intent(LoginIntent(
        email: 'test@example.com',
        password: 'wrong',
        mockLoginUseCase: MockLoginUseCase()..shouldFail = true,
      ));

      expect(effects.length, 1);
      expect(effects.first, isA<ShowSnackbarEffect>());
      expect((effects.first as ShowSnackbarEffect).message, contains('Invalid'));
    });

    test('completes ShowErrorDialogEffect properly', () async {
      final effect = ShowErrorDialogEffect(
        title: 'Test Error',
        message: 'Test message',
      );

      await handler.handle(effect, controller, MockBuildContext());

      expect(effect.isCompleted, isTrue);
    });
  });
}
```

---

## 11. Additional Resources

### 11.1 Related Documentation

**JIntent Guides:**
- [Security Guide](./SECURITY_GUIDE.md) - Error security considerations and logging
- [API Versioning Guide](./API_VERSIONING.md) - Error handling in version migrations
- [Validation Examples](./examples/validation_examples.md) - Input validation patterns
- [Error Handling Examples](./examples/error_handling_examples.md) - Practical error handling code
- [Global Error Handler Guide](./GLOBAL_ERROR_HANDLER.md) - Centralized error interception and handling
- [Effects Guide](../doc/effects.md) - Complete side effects documentation

**Architecture Decision Records:**
- [ADR-006: Error Handling Patterns](./adr/ADR-006-error-handling-patterns.md) - Error strategy decisions
- [ADR-007: Validation Framework](./adr/ADR-007-validation-framework.md) - Validation approach
- [ADR-005: Security Architecture](./adr/ADR-005-security-architecture.md) - Security error handling

**Project Documentation:**
- [Documentation Index](./README.md) - Complete documentation navigation
- [Exception Inventory](./EXCEPTION_INVENTORY.md) - Exception governance and catalog

### 11.2 Code Examples

**Example Application:**
- `example/lib/src/domain/use_cases/` - Use case error handling
- `example/lib/src/presentation/intents/` - Intent error handling
- `example/lib/src/data/repositories/` - Repository error handling
- `example/lib/src/presentation/*/effect_handler.dart` - Effect handler implementations

**Example Documentation:**
- [Error Handling Examples](./examples/error_handling_examples.md) - Comprehensive code samples
- [Validation Examples](./examples/validation_examples.md) - Input validation patterns

### 11.3 Community & Support

- [GitHub Issues](https://github.com/GenSoftMX/JIntent/issues) - Report bugs or request features
- [GitHub Discussions](https://github.com/GenSoftMX/JIntent/discussions) - Ask questions and share ideas

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-15  
**Next Review:** 2025-11-15  
**Maintained By:** JIntent Core Team

---

**Quick Links:**
- [← Back to Documentation Index](./README.md)
- [← Security Guide](./SECURITY_GUIDE.md)
- [API Versioning Guide →](./API_VERSIONING.md)
- [Main README](../README.md)
