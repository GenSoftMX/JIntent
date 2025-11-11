# Error Handling Examples

This document provides practical examples of error handling patterns using JIntent's Either monad and exception handling.

## Table of Contents

1. [Either Pattern Basics](#either-pattern-basics)
2. [Use Case Error Handling](#use-case-error-handling)
3. [Intent Error Handling](#intent-error-handling)
4. [Repository Error Handling](#repository-error-handling)
5. [Global Error Handlers](#global-error-handlers)
6. [Advanced Patterns](#advanced-patterns)

---

## Either Pattern Basics

### Example 1: Simple Either Usage

```dart
import 'package:jintent/jintent.dart';

// Success case
Either<Exception, String> getUsername() {
  return Right('john_doe');
}

// Error case
Either<Exception, String> getUsername() {
  return Left(Exception('User not found'));
}

// Handling with fold
void main() {
  final result = getUsername();
  
  result.fold(
    (error) => print('Error: $error'),
    (username) => print('Username: $username'),
  );
}

// Handling with isLeft/isRight
void main() {
  final result = getUsername();
  
  if (result.isLeft) {
    print('Error: ${result.left}');
  } else {
    print('Username: ${result.right}');
  }
}
```

---

## Use Case Error Handling

### Example 2: Basic Use Case with Error Handling

```dart
class GetUserUseCase extends JUseCase<String, User> {
  final UserRepository _repository;

  GetUserUseCase(this._repository);

  @override
  Future<Either<Exception, User>> run(String userId) async {
    try {
      final user = await _repository.getUser(userId);
      
      if (user == null) {
        return Left(Exception('User not found'));
      }
      
      return Right(user);
    } on NetworkException catch (e) {
      return Left(Exception('Network error: ${e.message}'));
    } catch (e) {
      return Left(Exception('Failed to get user'));
    }
  }
}
```

### Example 3: Use Case with Multiple Error Types

```dart
// Define custom exceptions
class UserNotFoundException implements Exception {
  final String userId;
  UserNotFoundException(this.userId);
  
  @override
  String toString() => 'User not found: $userId';
}

class InvalidUserDataException implements Exception {
  final String reason;
  InvalidUserDataException(this.reason);
  
  @override
  String toString() => 'Invalid user data: $reason';
}

class LoadUserProfileUseCase extends JUseCase<String, UserProfile> {
  final UserRepository _userRepo;
  final ProfileRepository _profileRepo;

  LoadUserProfileUseCase(this._userRepo, this._profileRepo);

  @override
  Future<Either<Exception, UserProfile>> run(String userId) async {
    try {
      // Step 1: Get user
      final userResult = await _userRepo.getUser(userId);
      if (userResult.isLeft) {
        return Left(userResult.left!);
      }
      final user = userResult.right!;
      
      // Step 2: Validate user data
      if (user.isDeleted) {
        return Left(InvalidUserDataException('User account is deleted'));
      }
      
      // Step 3: Get profile
      final profileResult = await _profileRepo.getProfile(userId);
      if (profileResult.isLeft) {
        return Left(profileResult.left!);
      }
      final profile = profileResult.right!;
      
      // Step 4: Combine data
      return Right(UserProfile(user: user, profile: profile));
      
    } on NetworkException catch (e) {
      return Left(Exception('Network error. Please check your connection.'));
    } on TimeoutException {
      return Left(Exception('Request timeout. Please try again.'));
    } catch (e) {
      _logger.error('Unexpected error loading profile', error: e);
      return Left(Exception('Failed to load user profile'));
    }
  }
}
```

### Example 4: Chaining Use Case Operations

```dart
class ProcessOrderUseCase extends JUseCase<OrderInput, OrderReceipt> {
  final InventoryRepository _inventory;
  final PaymentRepository _payment;
  final OrderRepository _orderRepo;

  ProcessOrderUseCase(this._inventory, this._payment, this._orderRepo);

  @override
  Future<Either<Exception, OrderReceipt>> run(OrderInput input) async {
    // Step 1: Check inventory
    final inventoryResult = await _checkInventory(input.items);
    if (inventoryResult.isLeft) {
      return Left(inventoryResult.left!);
    }
    
    // Step 2: Process payment
    final paymentResult = await _processPayment(input.paymentMethod, input.total);
    if (paymentResult.isLeft) {
      // Rollback inventory if needed
      await _releaseInventory(input.items);
      return Left(paymentResult.left!);
    }
    final payment = paymentResult.right!;
    
    // Step 3: Create order
    final orderResult = await _createOrder(input, payment);
    if (orderResult.isLeft) {
      // Rollback payment
      await _refundPayment(payment.id);
      await _releaseInventory(input.items);
      return Left(orderResult.left!);
    }
    
    // Step 4: Generate receipt
    final order = orderResult.right!;
    return Right(OrderReceipt.from(order, payment));
  }

  Future<Either<Exception, void>> _checkInventory(List<OrderItem> items) async {
    for (final item in items) {
      final available = await _inventory.getAvailableQuantity(item.productId);
      if (available < item.quantity) {
        return Left(Exception('Insufficient inventory for ${item.productName}'));
      }
    }
    return Right(null);
  }

  Future<Either<Exception, Payment>> _processPayment(
    PaymentMethod method,
    double amount,
  ) async {
    try {
      final payment = await _payment.charge(method, amount);
      return Right(payment);
    } on PaymentDeclinedException {
      return Left(Exception('Payment was declined. Please try another payment method.'));
    } on InsufficientFundsException {
      return Left(Exception('Insufficient funds'));
    } catch (e) {
      return Left(Exception('Payment processing failed'));
    }
  }

  Future<Either<Exception, Order>> _createOrder(
    OrderInput input,
    Payment payment,
  ) async {
    try {
      final order = await _orderRepo.create(input, payment.id);
      return Right(order);
    } catch (e) {
      return Left(Exception('Failed to create order'));
    }
  }

  // Rollback helpers
  Future<void> _releaseInventory(List<OrderItem> items) async {
    // Release reserved inventory
  }

  Future<void> _refundPayment(String paymentId) async {
    // Initiate refund
  }
}
```

---

## Intent Error Handling

### Example 5: Basic Intent Error Handling

```dart
class LoginIntent extends JIntent<AuthState> {
  final String email;
  final String password;
  final LoginUseCase _loginUseCase;

  LoginIntent(this.email, this.password, this._loginUseCase);

  @override
  Future<void> onInvoke() async {
    // Set loading state
    controller.update((state) => state.copyWith(isLoading: true));

    // Execute use case
    final result = await _loginUseCase(LoginInput(
      email: email,
      password: password,
    ));

    // Handle result
    result.fold(
      // Error case
      (exception) {
        controller.update((state) => state.copyWith(
          isLoading: false,
          error: exception.toString(),
          isAuthenticated: false,
        ));

        // Show error to user
        controller.emitSideEffect(ShowSnackbarEffect(
          message: exception.toString(),
          type: SnackbarType.error,
        ));
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

### Example 6: Intent with Multiple Error Types

```dart
class CreateAccountIntent extends JIntent<RegistrationState> {
  final RegistrationInput input;
  final CreateAccountUseCase _createAccountUseCase;

  CreateAccountIntent(this.input, this._createAccountUseCase);

  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(isCreating: true));

    final result = await _createAccountUseCase(input);

    result.fold(
      (error) {
        // Handle different error types
        String userMessage;
        SnackbarType snackbarType;

        if (error is ValidationException) {
          userMessage = error.message;
          snackbarType = SnackbarType.warning;
        } else if (error is NetworkException) {
          userMessage = 'No internet connection. Please try again.';
          snackbarType = SnackbarType.error;
        } else if (error is DuplicateEmailException) {
          userMessage = 'This email is already registered. Please log in instead.';
          snackbarType = SnackbarType.info;
          
          // Emit navigation to login
          controller.emitSideEffect(ShowLoginSuggestionEffect());
        } else {
          userMessage = 'Failed to create account. Please try again.';
          snackbarType = SnackbarType.error;
        }

        controller.update((state) => state.copyWith(
          isCreating: false,
          error: userMessage,
        ));

        controller.emitSideEffect(ShowSnackbarEffect(
          message: userMessage,
          type: snackbarType,
        ));
      },
      (account) {
        controller.update((state) => state.copyWith(
          isCreating: false,
          account: account,
          error: null,
        ));

        controller.emitSideEffect(ShowSnackbarEffect(
          message: 'Account created successfully!',
          type: SnackbarType.success,
        ));

        controller.emitSideEffect(NavigateToWelcomeEffect());
      },
    );
  }
}
```

### Example 7: Intent with Retry Logic

```dart
class LoadDataIntent extends JIntent<DataState> {
  final String dataId;
  final LoadDataUseCase _loadDataUseCase;
  final LoadFromCacheUseCase _loadFromCacheUseCase;

  LoadDataIntent(this.dataId, this._loadDataUseCase, this._loadFromCacheUseCase);

  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(isLoading: true));

    // Try to load from network
    final result = await _loadDataUseCase(dataId);

    result.fold(
      (error) async {
        // Network failed, try cache
        if (error is NetworkException) {
          final cacheResult = await _loadFromCacheUseCase(dataId);
          
          cacheResult.fold(
            (cacheError) {
              // Both network and cache failed
              controller.update((state) => state.copyWith(
                isLoading: false,
                error: 'Unable to load data. Please check your connection.',
              ));

              controller.emitSideEffect(ShowRetryDialogEffect(
                message: 'Failed to load data',
                onRetry: () => controller.intent(LoadDataIntent(
                  dataId,
                  _loadDataUseCase,
                  _loadFromCacheUseCase,
                )),
              ));
            },
            (cachedData) {
              // Cache succeeded
              controller.update((state) => state.copyWith(
                isLoading: false,
                data: cachedData,
                isFromCache: true,
                error: null,
              ));

              controller.emitSideEffect(ShowSnackbarEffect(
                message: 'Showing cached data',
                type: SnackbarType.info,
              ));
            },
          );
        } else {
          // Other errors
          controller.update((state) => state.copyWith(
            isLoading: false,
            error: error.toString(),
          ));

          controller.emitSideEffect(ShowSnackbarEffect(
            message: error.toString(),
            type: SnackbarType.error,
          ));
        }
      },
      (data) {
        // Network succeeded
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

---

## Repository Error Handling

### Example 8: Repository with Either Pattern

```dart
class UserRepositoryImpl implements UserRepository {
  final ApiClient _api;
  final Database _db;

  UserRepositoryImpl(this._api, this._db);

  @override
  Future<Either<Exception, User>> getUser(String userId) async {
    try {
      final response = await _api.get('/users/$userId');
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        return Right(user);
      } else if (response.statusCode == 404) {
        return Left(UserNotFoundException(userId));
      } else if (response.statusCode == 401) {
        return Left(UnauthorizedException('Authentication required'));
      } else {
        return Left(Exception('Failed to load user'));
      }
    } on SocketException {
      return Left(NetworkException('No internet connection'));
    } on TimeoutException {
      return Left(NetworkException('Request timeout'));
    } catch (e) {
      _logger.error('Unexpected error in getUser', error: e);
      return Left(Exception('Failed to load user'));
    }
  }

  @override
  Future<Either<Exception, User>> updateUser(String userId, UserUpdate update) async {
    try {
      final response = await _api.put('/users/$userId', update.toJson());
      
      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        // Update local cache
        await _db.saveUser(user);
        return Right(user);
      } else if (response.statusCode == 400) {
        return Left(ValidationException('Invalid user data'));
      } else if (response.statusCode == 409) {
        return Left(ConflictException('User data has been modified by another user'));
      } else {
        return Left(Exception('Failed to update user'));
      }
    } on NetworkException catch (e) {
      return Left(e);
    } catch (e) {
      _logger.error('Error updating user', error: e);
      return Left(Exception('Failed to update user'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteUser(String userId) async {
    try {
      final response = await _api.delete('/users/$userId');
      
      if (response.statusCode == 204) {
        // Delete from local cache
        await _db.deleteUser(userId);
        return Right(null);
      } else if (response.statusCode == 404) {
        return Left(UserNotFoundException(userId));
      } else {
        return Left(Exception('Failed to delete user'));
      }
    } catch (e) {
      _logger.error('Error deleting user', error: e);
      return Left(Exception('Failed to delete user'));
    }
  }
}
```

---

## Global Error Handlers

### Example 9: Configure Global Error Logger

```dart
import 'package:jintent/jintent.dart';
import 'package:flutter/foundation.dart';

void configureGlobalErrorHandling() {
  // Configure Either error logger
  EitherConfig.configureLogger((error) {
    if (kDebugMode) {
      // Detailed logging in debug
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ Error: ${error.runtimeType}');
      debugPrint('Message: $error');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } else {
      // Production logging
      _logToAnalytics(error);
    }
  });
}

void _logToAnalytics(Object error) {
  // Send to your analytics service
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
```

### Example 10: Global Error Handler Intent

```dart
class GlobalErrorHandlerIntent extends JIntent<AppState> {
  final Object error;
  final StackTrace? stackTrace;

  GlobalErrorHandlerIntent(this.error, [this.stackTrace]);

  @override
  Future<void> onInvoke() async {
    // Log error
    _logger.error('Global error caught', error: error, stackTrace: stackTrace);

    // Determine error type and message
    String userMessage;
    ErrorSeverity severity;

    if (error is NetworkException) {
      userMessage = 'Network error. Please check your connection.';
      severity = ErrorSeverity.warning;
    } else if (error is TimeoutException) {
      userMessage = 'Request timeout. Please try again.';
      severity = ErrorSeverity.warning;
    } else if (error is ValidationException) {
      userMessage = error.message;
      severity = ErrorSeverity.info;
    } else if (error is AuthenticationException) {
      userMessage = 'Session expired. Please log in again.';
      severity = ErrorSeverity.error;
      // Trigger logout
      controller.emitSideEffect(LogoutEffect());
    } else {
      userMessage = 'An unexpected error occurred.';
      severity = ErrorSeverity.error;
    }

    // Update state
    controller.update((state) => state.copyWith(
      lastError: userMessage,
      errorTimestamp: DateTime.now(),
    ));

    // Show error to user
    controller.emitSideEffect(ShowErrorEffect(
      message: userMessage,
      severity: severity,
    ));

    // Report to crash reporting
    if (severity == ErrorSeverity.error && !kDebugMode) {
      _crashReporting.recordError(error, stackTrace);
    }
  }
}
```

### Example 11: Flutter Error Boundary

```dart
void main() {
  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      _crashReporting.logFlutterError(details);
    }
  };

  // Catch other Dart errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack: $stack');
    } else {
      _crashReporting.logError(error, stack);
    }
    return true;
  };

  // Configure JIntent error handling
  configureGlobalErrorHandling();

  runApp(MyApp());
}

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

// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({required this.child});

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Something went wrong'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                },
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return ErrorWidget.builder = (FlutterErrorDetails details) {
      setState(() {
        _error = details.exception;
      });
      return Container();
    };
    
    return widget.child;
  }
}
```

---

## Advanced Patterns

### Example 12: Retry with Exponential Backoff

```dart
Future<Either<Exception, T>> retryWithBackoff<T>(
  Future<Either<Exception, T>> Function() operation, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  double backoffMultiplier = 2.0,
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (attempt < maxAttempts) {
    final result = await operation();

    if (result.isRight) {
      return result;  // Success
    }

    attempt++;
    if (attempt < maxAttempts) {
      await Future.delayed(delay);
      delay *= backoffMultiplier;
    }
  }

  return Left(Exception('Operation failed after $maxAttempts attempts'));
}

// Usage
final result = await retryWithBackoff(
  () => _repository.fetchData(),
  maxAttempts: 3,
  initialDelay: Duration(seconds: 1),
  backoffMultiplier: 2.0,
);
```

### Example 13: Circuit Breaker Pattern

```dart
class CircuitBreaker<T> {
  final Duration timeout;
  final int failureThreshold;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreaker({
    this.timeout = const Duration(seconds: 30),
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 1),
  });

  Future<Either<Exception, T>> execute(
    Future<Either<Exception, T>> Function() operation,
  ) async {
    // Check if circuit is open
    if (_isOpen) {
      if (_shouldAttemptReset()) {
        _isOpen = false;
        _failureCount = 0;
      } else {
        return Left(Exception('Circuit breaker is open. Service unavailable.'));
      }
    }

    try {
      final result = await operation().timeout(timeout);

      if (result.isLeft) {
        _recordFailure();
      } else {
        _recordSuccess();
      }

      return result;
    } on TimeoutException {
      _recordFailure();
      return Left(Exception('Operation timeout'));
    } catch (e) {
      _recordFailure();
      return Left(Exception('Operation failed'));
    }
  }

  void _recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _isOpen = true;
    }
  }

  void _recordSuccess() {
    _failureCount = 0;
    _isOpen = false;
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) >= resetTimeout;
  }
}

// Usage
class RemoteDataRepository {
  final CircuitBreaker<List<Item>> _circuitBreaker = CircuitBreaker();

  Future<Either<Exception, List<Item>>> getItems() async {
    return await _circuitBreaker.execute(() => _fetchItemsFromApi());
  }

  Future<Either<Exception, List<Item>>> _fetchItemsFromApi() async {
    // API call implementation
  }
}
```

### Example 14: Error Recovery with Fallbacks

```dart
class DataLoadingIntent extends JIntent<DataState> {
  final String dataId;

  DataLoadingIntent(this.dataId);

  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(isLoading: true));

    // Primary: Load from remote
    final remoteResult = await _remoteRepository.getData(dataId);

    await remoteResult.fold(
      (remoteError) async {
        // Fallback 1: Try local cache
        final cacheResult = await _cacheRepository.getData(dataId);

        await cacheResult.fold(
          (cacheError) async {
            // Fallback 2: Try last known good
            final lastKnownResult = await _getLastKnownGood(dataId);

            lastKnownResult.fold(
              (lastKnownError) {
                // All fallbacks failed
                controller.update((state) => state.copyWith(
                  isLoading: false,
                  error: 'Unable to load data from any source',
                ));

                controller.emitSideEffect(ShowErrorEffect(
                  message: 'Failed to load data. Please try again later.',
                ));
              },
              (lastKnownData) {
                // Last known good succeeded
                controller.update((state) => state.copyWith(
                  isLoading: false,
                  data: lastKnownData,
                  dataSource: DataSource.lastKnown,
                  error: null,
                ));

                controller.emitSideEffect(ShowWarningEffect(
                  message: 'Showing last known data',
                ));
              },
            );
          },
          (cachedData) {
            // Cache succeeded
            controller.update((state) => state.copyWith(
              isLoading: false,
              data: cachedData,
              dataSource: DataSource.cache,
              error: null,
            ));

            controller.emitSideEffect(ShowInfoEffect(
              message: 'Showing cached data',
            ));

            // Try to refresh in background
            _refreshInBackground(dataId);
          },
        );
      },
      (remoteData) {
        // Remote succeeded
        controller.update((state) => state.copyWith(
          isLoading: false,
          data: remoteData,
          dataSource: DataSource.remote,
          error: null,
        ));

        // Cache for future use
        _cacheRepository.saveData(dataId, remoteData);
      },
    );
  }

  Future<Either<Exception, Data>> _getLastKnownGood(String dataId) async {
    // Implement last known good retrieval
  }

  Future<void> _refreshInBackground(String dataId) async {
    // Attempt to refresh from remote in background
  }
}
```

---

## Summary

Key patterns covered:
- **Either Pattern:** Type-safe error handling
- **Use Case Errors:** Validation and business logic errors
- **Intent Errors:** UI error handling and user feedback
- **Repository Errors:** Data layer error mapping
- **Global Handlers:** Centralized error logging and reporting
- **Advanced Patterns:** Retry, circuit breaker, fallbacks

For more information, see:
- [Error Handling Guide](../ERROR_HANDLING_GUIDE.md)
- [Security Guide](../SECURITY_GUIDE.md)
- [Validation Examples](./validation_examples.md)
