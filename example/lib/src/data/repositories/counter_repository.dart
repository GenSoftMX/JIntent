import 'package:jintent/jintent.dart';
import '../mappers/counter_mapper.dart';
import '../models/counter_dto.dart';
import '../models/counter_entity.dart';

/// Repository interface for counter data operations
///
/// Demonstrates:
/// - Repository pattern with clean interface
/// - Either-based error handling
/// - Separation of data access from business logic
abstract class CounterRepository {
  /// Loads the current counter value
  Future<Either<Exception, CounterEntity>> loadCounter();

  /// Saves the counter value
  Future<Either<Exception, CounterEntity>> saveCounter(int value);

  /// Deletes the stored counter value
  Future<Either<Exception, void>> deleteCounter();
}

/// In-memory implementation of CounterRepository
///
/// Demonstrates:
/// - Repository implementation
/// - Mapper usage for DTO → Entity transformation
/// - Either-based error handling
/// - ArgumentError handling from mappers
/// - Validation at repository level
class InMemoryCounterRepository implements CounterRepository {
  final CounterBiMapper _mapper;
  CounterDto? _storage;

  InMemoryCounterRepository({CounterBiMapper? mapper})
    : _mapper = mapper ?? CounterBiMapper();

  @override
  Future<Either<Exception, CounterEntity>> loadCounter() async {
    try {
      // Simulate async delay (like network/disk I/O)
      await Future.delayed(const Duration(milliseconds: 100));

      if (_storage == null) {
        return Left(Exception('No counter data found'));
      }

      // Transform DTO to Entity using mapper
      try {
        final entity = _mapper.from(_storage!);
        return Right(entity);
      } on ArgumentError catch (e) {
        // Handle mapper validation errors
        return Left(Exception('Invalid counter data: ${e.message}'));
      }
    } catch (e) {
      return Left(Exception('Failed to load counter: $e'));
    }
  }

  @override
  Future<Either<Exception, CounterEntity>> saveCounter(int value) async {
    try {
      // Validate at repository level
      if (value < -10) {
        return Left(Exception('Counter value cannot be less than -10'));
      }

      if (value > 10) {
        return Left(Exception('Counter value cannot be greater than 10'));
      }

      // Simulate async delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Create DTO with current timestamp
      final dto = CounterDto(
        value: value,
        lastUpdated: DateTime.now().toIso8601String(),
      );

      // Save to storage
      _storage = dto;

      // Transform and return
      try {
        final entity = _mapper.from(dto);
        return Right(entity);
      } on ArgumentError catch (e) {
        return Left(Exception('Invalid counter value: ${e.message}'));
      }
    } catch (e) {
      return Left(Exception('Failed to save counter: $e'));
    }
  }

  @override
  Future<Either<Exception, void>> deleteCounter() async {
    try {
      // Simulate async delay
      await Future.delayed(const Duration(milliseconds: 100));

      if (_storage == null) {
        return Left(Exception('No counter data to delete'));
      }

      _storage = null;
      return Right(null);
    } catch (e) {
      return Left(Exception('Failed to delete counter: $e'));
    }
  }
}

/// Mock repository that simulates API/network errors
///
/// Demonstrates:
/// - Error simulation for testing
/// - Different error scenarios
/// - Proper Either usage
class MockFailingCounterRepository implements CounterRepository {
  final String errorMessage;

  MockFailingCounterRepository({this.errorMessage = 'Network error'});

  @override
  Future<Either<Exception, CounterEntity>> loadCounter() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Left(Exception(errorMessage));
  }

  @override
  Future<Either<Exception, CounterEntity>> saveCounter(int value) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Left(Exception(errorMessage));
  }

  @override
  Future<Either<Exception, void>> deleteCounter() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Left(Exception(errorMessage));
  }
}

/// Repository with caching layer
///
/// Demonstrates:
/// - Cache pattern
/// - Fallback strategies
/// - Composition of repositories
class CachedCounterRepository implements CounterRepository {
  final CounterRepository _remoteRepository;
  CounterEntity? _cachedEntity;
  DateTime? _cacheTime;
  final Duration _cacheDuration;

  CachedCounterRepository({
    required CounterRepository remoteRepository,
    Duration cacheDuration = const Duration(minutes: 5),
  }) : _remoteRepository = remoteRepository,
       _cacheDuration = cacheDuration;

  bool get _isCacheValid {
    if (_cachedEntity == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }

  @override
  Future<Either<Exception, CounterEntity>> loadCounter() async {
    // Try cache first
    if (_isCacheValid) {
      return Right(_cachedEntity!);
    }

    // Cache miss or expired, fetch from remote
    final result = await _remoteRepository.loadCounter();

    // Update cache on success
    if (result.isRight) {
      _cachedEntity = result.right;
      _cacheTime = DateTime.now();
    }

    return result;
  }

  @override
  Future<Either<Exception, CounterEntity>> saveCounter(int value) async {
    final result = await _remoteRepository.saveCounter(value);

    // Update cache on success
    if (result.isRight) {
      _cachedEntity = result.right;
      _cacheTime = DateTime.now();
    }

    return result;
  }

  @override
  Future<Either<Exception, void>> deleteCounter() async {
    final result = await _remoteRepository.deleteCounter();

    // Clear cache on success
    if (result.isRight) {
      _cachedEntity = null;
      _cacheTime = null;
    }

    return result;
  }
}
