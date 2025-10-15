# Data Layer Guidance

**Version:** 1.0  
**Date:** 2025-10-15  
**Status:** Phase 2 Complete

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Patterns](#architecture-patterns)
3. [Repository Pattern](#repository-pattern)
4. [Mapper Patterns](#mapper-patterns)
5. [Either-Based Error Handling](#either-based-error-handling)
6. [Validation Pipelines](#validation-pipelines)
7. [Best Practices](#best-practices)
8. [Testing Strategies](#testing-strategies)
9. [Examples](#examples)

---

## Overview

The data layer in JIntent applications bridges your domain logic and external data sources (APIs, databases, local storage). This guide demonstrates recommended patterns for building maintainable, testable data layers using JIntent's core abstractions.

### Key Principles

1. **Separation of Concerns**: Data layer handles data access, domain layer handles business logic
2. **Type Safety**: Use `Either<Exception, T>` for explicit error handling
3. **Transformation**: Use `JMapper` and `IBiMapper` for converting between data and domain models
4. **Validation**: Validate at boundaries using `UseCaseInputValidator`
5. **Testability**: Design for easy mocking and testing

### JIntent Data Layer Components

- **`Either<L, R>`**: Type-safe result monad for success/failure
- **`JMapper<INPUT, OUTPUT>`**: One-way data transformation
- **`IBiMapper<A, B>`**: Bidirectional data transformation
- **`JUseCase<INPUT, OUTPUT>`**: Business logic with built-in validation
- **`UseCaseInputValidator`**: Input validation pipeline

---

## Architecture Patterns

### Recommended Layered Architecture

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Widgets, Controllers, Intents)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Domain Layer               │
│    (Use Cases, Domain Models)       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│          Data Layer                 │
│  (Repositories, Mappers, DTOs)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Data Sources                 │
│  (APIs, Databases, Local Storage)   │
└─────────────────────────────────────┘
```

### Data Flow

```
API Response (DTO) 
    ↓
Mapper (DTO → Domain Model)
    ↓
Repository (Either<Exception, Model>)
    ↓
Use Case (Business Logic + Validation)
    ↓
Intent (State Updates + Side Effects)
    ↓
UI (State Rendering)
```

---

## Repository Pattern

The Repository pattern abstracts data access, providing a clean API for the domain layer.

### Repository Interface

```dart
/// Abstract repository interface for user data
abstract class UserRepository {
  /// Fetches a user by ID
  Future<Either<Exception, User>> getUser(String userId);
  
  /// Updates user information
  Future<Either<Exception, User>> updateUser(String userId, User user);
  
  /// Deletes a user
  Future<Either<Exception, void>> deleteUser(String userId);
  
  /// Lists all users with optional filters
  Future<Either<Exception, List<User>>> listUsers({
    int? limit,
    String? cursor,
  });
}
```

### Repository Implementation

```dart
import 'package:jintent/jintent.dart';

class UserRepositoryImpl implements UserRepository {
  final ApiClient _apiClient;
  final UserMapper _mapper;
  final Logger _logger;

  UserRepositoryImpl({
    required ApiClient apiClient,
    required UserMapper mapper,
    Logger? logger,
  })  : _apiClient = apiClient,
        _mapper = mapper,
        _logger = logger ?? Logger('UserRepository');

  @override
  Future<Either<Exception, User>> getUser(String userId) async {
    try {
      // 1. Fetch data from API
      final response = await _apiClient.get('/users/$userId');
      
      // 2. Check response status
      if (response.statusCode != 200) {
        return Left(_handleHttpError(response.statusCode, response.body));
      }
      
      // 3. Parse DTO
      final userDto = UserDto.fromJson(response.data);
      
      // 4. Transform DTO to domain model
      final user = _mapper.transform(userDto);
      
      // 5. Return success
      return Right(user);
    } on NetworkException catch (e) {
      _logger.error('Network error fetching user', error: e);
      return Left(Exception('No internet connection'));
    } on TimeoutException catch (e) {
      _logger.error('Timeout fetching user', error: e);
      return Left(Exception('Request timeout. Please try again.'));
    } on FormatException catch (e) {
      _logger.error('Invalid response format', error: e);
      return Left(Exception('Invalid server response'));
    } catch (e, stackTrace) {
      _logger.error('Unexpected error fetching user', 
        error: e, 
        stackTrace: stackTrace
      );
      return Left(Exception('Failed to fetch user'));
    }
  }

  @override
  Future<Either<Exception, User>> updateUser(
    String userId, 
    User user,
  ) async {
    try {
      // 1. Transform domain model to DTO
      final userDto = _mapper.reverse(user);
      
      // 2. Send update request
      final response = await _apiClient.put(
        '/users/$userId',
        userDto.toJson(),
      );
      
      if (response.statusCode != 200) {
        return Left(_handleHttpError(response.statusCode, response.body));
      }
      
      // 3. Parse and transform response
      final updatedDto = UserDto.fromJson(response.data);
      final updatedUser = _mapper.transform(updatedDto);
      
      return Right(updatedUser);
    } on NetworkException catch (e) {
      _logger.error('Network error updating user', error: e);
      return Left(Exception('No internet connection'));
    } catch (e, stackTrace) {
      _logger.error('Error updating user', error: e, stackTrace: stackTrace);
      return Left(Exception('Failed to update user'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteUser(String userId) async {
    try {
      final response = await _apiClient.delete('/users/$userId');
      
      if (response.statusCode == 204) {
        return Right(null);
      }
      
      return Left(_handleHttpError(response.statusCode, response.body));
    } catch (e, stackTrace) {
      _logger.error('Error deleting user', error: e, stackTrace: stackTrace);
      return Left(Exception('Failed to delete user'));
    }
  }

  @override
  Future<Either<Exception, List<User>>> listUsers({
    int? limit,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (cursor != null) queryParams['cursor'] = cursor;
      
      final response = await _apiClient.get(
        '/users',
        queryParameters: queryParams,
      );
      
      if (response.statusCode != 200) {
        return Left(_handleHttpError(response.statusCode, response.body));
      }
      
      // Parse list of DTOs
      final List<dynamic> jsonList = response.data['users'];
      final dtos = jsonList.map((json) => UserDto.fromJson(json)).toList();
      
      // Transform to domain models
      final users = _mapper.transformList(dtos);
      
      return Right(users);
    } catch (e, stackTrace) {
      _logger.error('Error listing users', error: e, stackTrace: stackTrace);
      return Left(Exception('Failed to fetch users'));
    }
  }

  Exception _handleHttpError(int statusCode, dynamic body) {
    switch (statusCode) {
      case 400:
        return Exception('Invalid request');
      case 401:
        return Exception('Authentication required');
      case 403:
        return Exception('Access denied');
      case 404:
        return Exception('User not found');
      case 409:
        return Exception('User data conflict');
      case 500:
        return Exception('Server error. Please try again later.');
      default:
        return Exception('Request failed with status $statusCode');
    }
  }
}
```

### Repository with Local Cache

```dart
class CachedUserRepository implements UserRepository {
  final UserRepository _remoteRepository;
  final CacheStore _cache;
  final Duration _cacheDuration;

  CachedUserRepository({
    required UserRepository remoteRepository,
    required CacheStore cache,
    Duration cacheDuration = const Duration(minutes: 5),
  })  : _remoteRepository = remoteRepository,
        _cache = cache,
        _cacheDuration = cacheDuration;

  @override
  Future<Either<Exception, User>> getUser(String userId) async {
    // Try cache first
    final cached = await _cache.get<User>('user_$userId');
    if (cached != null && !_cache.isExpired('user_$userId', _cacheDuration)) {
      return Right(cached);
    }
    
    // Fetch from remote
    final result = await _remoteRepository.getUser(userId);
    
    // Cache on success
    if (result.isRight) {
      await _cache.set('user_$userId', result.right!);
    }
    
    return result;
  }

  @override
  Future<Either<Exception, User>> updateUser(
    String userId,
    User user,
  ) async {
    final result = await _remoteRepository.updateUser(userId, user);
    
    // Invalidate cache on successful update
    if (result.isRight) {
      await _cache.remove('user_$userId');
    }
    
    return result;
  }

  @override
  Future<Either<Exception, void>> deleteUser(String userId) async {
    final result = await _remoteRepository.deleteUser(userId);
    
    // Invalidate cache on successful delete
    if (result.isRight) {
      await _cache.remove('user_$userId');
    }
    
    return result;
  }

  @override
  Future<Either<Exception, List<User>>> listUsers({
    int? limit,
    String? cursor,
  }) async {
    // For lists, implement cache invalidation strategy
    return _remoteRepository.listUsers(limit: limit, cursor: cursor);
  }
}
```

---

## Mapper Patterns

Mappers transform data between different representations (DTOs, entities, domain models).

### Basic JMapper

```dart
import 'package:jintent/jintent.dart';

/// Maps UserDto (API response) to User (domain model)
class UserMapper extends JMapper<UserDto, User> {
  @override
  User map(UserDto dto) {
    return User(
      id: dto.id,
      name: dto.fullName,
      email: dto.email,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}

// Usage
final mapper = UserMapper();

// Single transformation
final user = mapper.transform(userDto);

// List transformation
final users = mapper.transformList(userDtoList);

// Dynamic transformation
try {
  final result = mapper.transformDynamic(dynamicInput);
  if (result is User) {
    // Handle single user
  } else if (result is List<User>) {
    // Handle list of users
  }
} on ArgumentError catch (e) {
  // Handle unsupported type
  print('Transformation failed: ${e.message}');
}
```

### Bidirectional Mapper (IBiMapper)

```dart
/// Bidirectional mapper for User ↔ UserDto
class UserBiMapper implements IBiMapper<User, UserDto> {
  @override
  UserDto to(User user) {
    return UserDto(
      id: user.id,
      fullName: user.name,
      email: user.email,
      createdAt: user.createdAt.toIso8601String(),
    );
  }

  @override
  User from(UserDto dto) {
    return User(
      id: dto.id,
      name: dto.fullName,
      email: dto.email,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}

// Usage
final biMapper = UserBiMapper();

// Domain → DTO (for API requests)
final dto = biMapper.to(user);

// DTO → Domain (for API responses)
final user = biMapper.from(dto);
```

### Mapper with Validation

```dart
class ValidatingUserMapper extends JMapper<UserDto, User> {
  @override
  User map(UserDto dto) {
    // Validate required fields
    if (dto.id.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    
    if (dto.email.isEmpty || !_isValidEmail(dto.email)) {
      throw ArgumentError('Invalid email format');
    }
    
    // Transform with validation
    return User(
      id: dto.id,
      name: dto.fullName.trim(),
      email: dto.email.toLowerCase(),
      createdAt: _parseDate(dto.createdAt),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      throw ArgumentError('Invalid date format: $dateString');
    }
  }
}
```

### Handling ArgumentError in Mappers

```dart
Future<Either<Exception, User>> getUserSafely(String userId) async {
  try {
    final response = await _apiClient.get('/users/$userId');
    final dto = UserDto.fromJson(response.data);
    
    // Transform with error handling
    try {
      final user = _mapper.transform(dto);
      return Right(user);
    } on ArgumentError catch (e) {
      // Handle mapper validation errors
      return Left(Exception('Invalid user data: ${e.message}'));
    }
  } on NetworkException catch (e) {
    return Left(Exception('Network error: ${e.message}'));
  } catch (e) {
    return Left(Exception('Failed to fetch user'));
  }
}
```

### Complex Nested Mapping

```dart
class OrderMapper extends JMapper<OrderDto, Order> {
  final UserMapper _userMapper;
  final ProductMapper _productMapper;

  OrderMapper({
    required UserMapper userMapper,
    required ProductMapper productMapper,
  })  : _userMapper = userMapper,
        _productMapper = productMapper;

  @override
  Order map(OrderDto dto) {
    return Order(
      id: dto.id,
      user: _userMapper.transform(dto.user),
      items: dto.items.mapWith(_productMapper),
      totalAmount: dto.totalAmount,
      status: OrderStatus.values.byName(dto.status),
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}
```

---

## Either-Based Error Handling

### Why Either?

`Either<L, R>` makes error handling explicit and type-safe:

- **Left**: Represents failure (Exception, Error)
- **Right**: Represents success (actual value)
- **No Silent Failures**: Forces handling of both cases
- **Composable**: Can be chained and transformed

### Basic Either Usage

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
final result = getUsername();
result.fold(
  (error) => print('Error: $error'),
  (username) => print('Username: $username'),
);

// Handling with isLeft/isRight
if (result.isLeft) {
  print('Error: ${result.left}');
} else {
  print('Username: ${result.right}');
}
```

### Repository with Either

```dart
class ProductRepository {
  Future<Either<Exception, Product>> getProduct(String id) async {
    try {
      final response = await _api.get('/products/$id');
      
      if (response.statusCode == 404) {
        return Left(Exception('Product not found'));
      }
      
      if (response.statusCode != 200) {
        return Left(Exception('Failed to load product'));
      }
      
      final dto = ProductDto.fromJson(response.data);
      final product = _mapper.transform(dto);
      
      return Right(product);
    } on NetworkException {
      return Left(Exception('No internet connection'));
    } catch (e) {
      return Left(Exception('Unexpected error'));
    }
  }

  Future<Either<Exception, List<Product>>> searchProducts(
    String query,
  ) async {
    try {
      final response = await _api.get('/products/search?q=$query');
      
      if (response.statusCode != 200) {
        return Left(Exception('Search failed'));
      }
      
      final List<dynamic> jsonList = response.data['results'];
      final products = jsonList
          .map((json) => ProductDto.fromJson(json))
          .map(_mapper.transform)
          .toList();
      
      return Right(products);
    } catch (e) {
      return Left(Exception('Search error'));
    }
  }
}
```

### Use Case with Either

```dart
class GetUserProfileUseCase extends JUseCase<String, UserProfile> {
  final UserRepository _userRepo;
  final ProfileRepository _profileRepo;

  GetUserProfileUseCase(this._userRepo, this._profileRepo);

  @override
  Future<Either<Exception, UserProfile>> run(String userId) async {
    // Get user
    final userResult = await _userRepo.getUser(userId);
    if (userResult.isLeft) {
      return Left(userResult.left!);
    }
    final user = userResult.right!;
    
    // Get profile
    final profileResult = await _profileRepo.getProfile(userId);
    if (profileResult.isLeft) {
      return Left(profileResult.left!);
    }
    final profile = profileResult.right!;
    
    // Combine results
    return Right(UserProfile(user: user, profile: profile));
  }
}
```

### Intent with Either

```dart
class LoadUserIntent extends JIntent<UserState> {
  final String userId;
  final GetUserProfileUseCase _useCase;

  LoadUserIntent(this.userId, this._useCase);

  @override
  Future<void> onInvoke() async {
    controller.update((state) => state.copyWith(isLoading: true));

    final result = await _useCase(userId);

    result.fold(
      // Error case
      (exception) {
        controller.update((state) => state.copyWith(
          isLoading: false,
          error: exception.toString(),
        ));

        controller.emitSideEffect(ShowErrorEffect(
          message: exception.toString(),
        ));
      },
      // Success case
      (userProfile) {
        controller.update((state) => state.copyWith(
          isLoading: false,
          userProfile: userProfile,
          error: null,
        ));
      },
    );
  }
}
```

### Chaining Either Operations

```dart
class ProcessOrderUseCase extends JUseCase<OrderInput, OrderReceipt> {
  @override
  Future<Either<Exception, OrderReceipt>> run(OrderInput input) async {
    // Step 1: Validate inventory
    final inventoryResult = await _checkInventory(input.items);
    if (inventoryResult.isLeft) return inventoryResult;
    
    // Step 2: Process payment
    final paymentResult = await _processPayment(input.payment);
    if (paymentResult.isLeft) {
      await _rollbackInventory(input.items);
      return Left(paymentResult.left!);
    }
    final payment = paymentResult.right!;
    
    // Step 3: Create order
    final orderResult = await _createOrder(input, payment);
    if (orderResult.isLeft) {
      await _refundPayment(payment);
      await _rollbackInventory(input.items);
      return Left(orderResult.left!);
    }
    
    // Step 4: Generate receipt
    final order = orderResult.right!;
    return Right(OrderReceipt.from(order, payment));
  }
}
```

---

## Validation Pipelines

### Input Validation in Use Cases

```dart
class CreateUserUseCase extends JUseCase<CreateUserInput, User> {
  final UserRepository _repository;

  CreateUserUseCase(this._repository) {
    // Add validators in order (fail fast)
    addValidator(_validateRequired);
    addValidator(_validateEmail);
    addValidator(_validateAge);
  }

  Either<Exception, CreateUserInput> _validateRequired(
    CreateUserInput input,
  ) {
    if (input.name.trim().isEmpty) {
      return Left(Exception('Name is required'));
    }
    if (input.email.trim().isEmpty) {
      return Left(Exception('Email is required'));
    }
    return Right(input);
  }

  Either<Exception, CreateUserInput> _validateEmail(
    CreateUserInput input,
  ) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(input.email)) {
      return Left(Exception('Invalid email format'));
    }
    return Right(input);
  }

  Either<Exception, CreateUserInput> _validateAge(
    CreateUserInput input,
  ) {
    if (input.age < 13) {
      return Left(Exception('Must be at least 13 years old'));
    }
    if (input.age > 120) {
      return Left(Exception('Invalid age'));
    }
    return Right(input);
  }

  @override
  Future<Either<Exception, User>> run(CreateUserInput input) async {
    // Validators already ran, input is valid
    return await _repository.createUser(input);
  }
}
```

### Repository-Level Validation

```dart
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<Exception, User>> updateUser(
    String userId,
    User user,
  ) async {
    // Validate before API call
    final validation = _validateUser(user);
    if (validation.isLeft) {
      return Left(validation.left!);
    }
    
    try {
      final dto = _mapper.to(user);
      final response = await _api.put('/users/$userId', dto.toJson());
      
      if (response.statusCode != 200) {
        return Left(Exception('Update failed'));
      }
      
      final updatedDto = UserDto.fromJson(response.data);
      final updatedUser = _mapper.from(updatedDto);
      
      return Right(updatedUser);
    } catch (e) {
      return Left(Exception('Failed to update user'));
    }
  }

  Either<Exception, User> _validateUser(User user) {
    if (user.name.isEmpty) {
      return Left(Exception('Name cannot be empty'));
    }
    if (user.email.isEmpty) {
      return Left(Exception('Email cannot be empty'));
    }
    return Right(user);
  }
}
```

### Async Validation

```dart
class RegisterUserUseCase extends JUseCase<RegisterInput, User> {
  final UserRepository _userRepo;

  RegisterUserUseCase(this._userRepo) {
    // Sync validators run first
    addValidator(_validateFormat);
  }

  Either<Exception, RegisterInput> _validateFormat(RegisterInput input) {
    if (input.username.length < 3) {
      return Left(Exception('Username too short'));
    }
    return Right(input);
  }

  @override
  Future<Either<Exception, User>> run(RegisterInput input) async {
    // Async validation in run()
    final availabilityCheck = await _userRepo.isUsernameAvailable(
      input.username,
    );
    
    if (availabilityCheck.isLeft) {
      return Left(availabilityCheck.left!);
    }
    
    if (!availabilityCheck.right!) {
      return Left(Exception('Username already taken'));
    }
    
    // Proceed with registration
    return await _userRepo.register(input);
  }
}
```

---

## Best Practices

### 1. Repository Design

✅ **DO:**
- Define clear interfaces for repositories
- Return `Either<Exception, T>` for all operations
- Use mappers to transform DTOs to domain models
- Handle all exceptions and return Left
- Log errors for debugging
- Implement caching strategies when appropriate

❌ **DON'T:**
- Throw exceptions from repositories (use Either instead)
- Return raw DTOs to the domain layer
- Mix business logic in repositories
- Expose implementation details

### 2. Mapper Usage

✅ **DO:**
- Create separate mappers for each DTO/Model pair
- Use `JMapper` for one-way transformations
- Use `IBiMapper` for bidirectional transformations
- Handle `ArgumentError` when using `transformDynamic`
- Validate data during mapping when appropriate

❌ **DON'T:**
- Put business logic in mappers
- Ignore mapper validation errors
- Create overly complex nested mappers

### 3. Error Handling

✅ **DO:**
- Use `Either<Exception, T>` for all repository methods
- Create specific exception types for different errors
- Handle errors at appropriate layers
- Provide user-friendly error messages
- Log technical details for debugging

❌ **DON'T:**
- Swallow exceptions silently
- Return null instead of Left
- Expose technical error details to users

### 4. Validation

✅ **DO:**
- Validate at boundaries (use case input, repository calls)
- Use `UseCaseInputValidator` for synchronous validation
- Perform async validation in use case `run()` method
- Fail fast with clear error messages
- Sanitize inputs before validation

❌ **DON'T:**
- Skip validation assuming data is correct
- Perform expensive validation in constructors
- Mix validation with business logic

### 5. Testing

✅ **DO:**
- Mock repositories in use case tests
- Test mapper transformations with edge cases
- Test error paths with Left values
- Test validation logic independently
- Use integration tests for data layer

❌ **DON'T:**
- Skip testing error scenarios
- Test implementation details
- Ignore edge cases in mappers

---

## Testing Strategies

### Testing Mappers

```dart
void main() {
  group('UserMapper', () {
    late UserMapper mapper;

    setUp(() {
      mapper = UserMapper();
    });

    test('should map DTO to domain model', () {
      final dto = UserDto(
        id: '1',
        fullName: 'John Doe',
        email: 'john@example.com',
        createdAt: '2024-01-01T00:00:00Z',
      );

      final user = mapper.transform(dto);

      expect(user.id, '1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    test('should handle transformList', () {
      final dtos = [
        UserDto(id: '1', fullName: 'John', email: 'john@example.com', createdAt: '2024-01-01T00:00:00Z'),
        UserDto(id: '2', fullName: 'Jane', email: 'jane@example.com', createdAt: '2024-01-01T00:00:00Z'),
      ];

      final users = mapper.transformList(dtos);

      expect(users.length, 2);
      expect(users[0].name, 'John');
      expect(users[1].name, 'Jane');
    });

    test('should throw ArgumentError for unsupported type', () {
      expect(
        () => mapper.transformDynamic('invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should recover from ArgumentError', () {
      User? result;
      try {
        result = mapper.transformDynamic('invalid');
      } on ArgumentError {
        // Provide fallback
        result = User.empty();
      }
      
      expect(result, isNotNull);
    });
  });
}
```

### Testing Repositories

```dart
void main() {
  group('UserRepository', () {
    late UserRepository repository;
    late MockApiClient mockApiClient;
    late MockUserMapper mockMapper;

    setUp(() {
      mockApiClient = MockApiClient();
      mockMapper = MockUserMapper();
      repository = UserRepositoryImpl(
        apiClient: mockApiClient,
        mapper: mockMapper,
      );
    });

    test('getUser returns Right on success', () async {
      // Arrange
      final dto = UserDto(id: '1', fullName: 'John', email: 'john@example.com', createdAt: '2024-01-01T00:00:00Z');
      final user = User(id: '1', name: 'John', email: 'john@example.com', createdAt: DateTime.now());
      
      when(() => mockApiClient.get('/users/1'))
          .thenAnswer((_) async => Response(statusCode: 200, data: dto.toJson()));
      when(() => mockMapper.transform(dto)).thenReturn(user);

      // Act
      final result = await repository.getUser('1');

      // Assert
      expect(result.isRight, true);
      expect(result.right, user);
    });

    test('getUser returns Left on 404', () async {
      // Arrange
      when(() => mockApiClient.get('/users/1'))
          .thenAnswer((_) async => Response(statusCode: 404, data: null));

      // Act
      final result = await repository.getUser('1');

      // Assert
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('not found'));
    });

    test('getUser returns Left on network error', () async {
      // Arrange
      when(() => mockApiClient.get('/users/1'))
          .thenThrow(NetworkException('No connection'));

      // Act
      final result = await repository.getUser('1');

      // Assert
      expect(result.isLeft, true);
      expect(result.left.toString(), contains('internet'));
    });
  });
}
```

### Testing Use Cases

```dart
void main() {
  group('GetUserUseCase', () {
    late GetUserUseCase useCase;
    late MockUserRepository mockRepository;

    setUp(() {
      mockRepository = MockUserRepository();
      useCase = GetUserUseCase(mockRepository);
    });

    test('returns user on success', () async {
      // Arrange
      final user = User(id: '1', name: 'John', email: 'john@example.com', createdAt: DateTime.now());
      when(() => mockRepository.getUser('1'))
          .thenAnswer((_) async => Right(user));

      // Act
      final result = await useCase('1');

      // Assert
      expect(result.isRight, true);
      expect(result.right?.id, '1');
    });

    test('returns Left on repository error', () async {
      // Arrange
      when(() => mockRepository.getUser('1'))
          .thenAnswer((_) async => Left(Exception('Not found')));

      // Act
      final result = await useCase('1');

      // Assert
      expect(result.isLeft, true);
    });
  });
}
```

---

## Examples

### Complete Data Layer Example

See the example application in `example/lib/src/data/` for a complete implementation including:

- Repository interface and implementation
- Mapper patterns (JMapper and IBiMapper)
- Either-based error handling
- Validation pipelines
- ArgumentError handling and recovery
- Integration with use cases

### Key Files

- `example/lib/src/data/repositories/user_repository.dart` - Repository implementation
- `example/lib/src/data/mappers/user_mapper.dart` - Mapper examples
- `example/lib/src/domain/use_cases/get_user_use_case.dart` - Use case with validation
- `test/src/domain/mapper_test.dart` - Mapper tests with ArgumentError examples

---

## Related Documentation

- [MAPPER_READER.md](../doc/MAPPER_READER.md) - Detailed mapper API documentation
- [Error Handling Examples](./examples/error_handling_examples.md) - Error handling patterns
- [Validation Examples](./examples/validation_examples.md) - Validation patterns
- [REPOSITORY_ANALYSIS.md](./REPOSITORY_ANALYSIS.md) - Section 7: Database & Data Layer
- [Security Guide](./SECURITY_GUIDE.md) - Security best practices

---

## Summary

The data layer is crucial for building maintainable applications. Key takeaways:

1. **Use Repository Pattern** to abstract data sources
2. **Use Mappers** (`JMapper`, `IBiMapper`) to transform data
3. **Use Either** for explicit, type-safe error handling
4. **Validate at Boundaries** using `UseCaseInputValidator`
5. **Handle ArgumentError** from mappers gracefully
6. **Test Thoroughly** including error paths and edge cases

Following these patterns ensures your data layer is:
- ✅ Testable
- ✅ Maintainable
- ✅ Type-safe
- ✅ Error-resilient
- ✅ Easy to mock and test

---

**Version History:**
- v1.0 (2025-10-15): Initial release as part of Phase 2 DB deliverables
