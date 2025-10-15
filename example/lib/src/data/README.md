# Data Layer Example

This directory contains a complete example of the data layer patterns recommended in the [DATA_LAYER_GUIDE.md](../../../../docs/DATA_LAYER_GUIDE.md).

## Structure

```
data/
├── models/           # Data models (DTOs and Entities)
│   ├── counter_dto.dart       # Data Transfer Object from storage/API
│   └── counter_entity.dart    # Domain entity
│
├── mappers/          # Data transformation
│   └── counter_mapper.dart    # JMapper and IBiMapper implementations
│
└── repositories/     # Data access layer
    └── counter_repository.dart # Repository interface and implementations
```

## Key Concepts Demonstrated

### 1. Repository Pattern

- **Interface**: `CounterRepository` - abstract interface for data operations
- **Implementation**: `InMemoryCounterRepository` - concrete implementation
- **Caching**: `CachedCounterRepository` - decorator pattern with caching
- **Testing**: `MockFailingCounterRepository` - mock for error scenarios

### 2. Mapper Patterns

- **One-way**: `CounterMapper extends JMapper` - DTO → Entity
- **Bidirectional**: `CounterBiMapper implements IBiMapper` - Entity ↔ DTO
- **Validation**: Mappers validate data during transformation
- **Error Handling**: `ArgumentError` for invalid data

### 3. Either-Based Error Handling

All repository methods return `Either<Exception, T>`:

```dart
Future<Either<Exception, CounterEntity>> loadCounter();
```

This makes error handling explicit and type-safe:

```dart
final result = await repository.loadCounter();
result.fold(
  (error) => print('Error: $error'),
  (entity) => print('Value: ${entity.value}'),
);
```

### 4. Validation Pipelines

Validation happens at multiple layers:

- **Repository level**: Business rules (e.g., value range)
- **Mapper level**: Data format and structure
- **Use case level**: Input validation (see domain layer)

## Usage Examples

### Basic Repository Usage

```dart
final repository = InMemoryCounterRepository();

// Save a value
final saveResult = await repository.saveCounter(5);
if (saveResult.isRight) {
  print('Saved: ${saveResult.right!.value}');
}

// Load the value
final loadResult = await repository.loadCounter();
loadResult.fold(
  (error) => print('Error: $error'),
  (entity) => print('Loaded: ${entity.value}'),
);

// Delete the value
await repository.deleteCounter();
```

### Using Cached Repository

```dart
final remoteRepository = InMemoryCounterRepository();
final cachedRepository = CachedCounterRepository(
  remoteRepository: remoteRepository,
  cacheDuration: Duration(minutes: 5),
);

// First call fetches from remote
await cachedRepository.loadCounter();

// Second call returns cached value
await cachedRepository.loadCounter();
```

### Mapper Usage

```dart
// Bidirectional mapper
final biMapper = CounterBiMapper();

// Entity → DTO
final dto = biMapper.to(entity);

// DTO → Entity
try {
  final entity = biMapper.from(dto);
} on ArgumentError catch (e) {
  // Handle invalid data
  print('Invalid data: ${e.message}');
}

// One-way mapper with list transformation
final mapper = CounterMapper();
final entities = mapper.transformList(dtoList);
```

### Error Handling

```dart
final result = await repository.saveCounter(15);

// Using fold
result.fold(
  (error) {
    // Handle error
    showSnackbar('Error: $error');
  },
  (entity) {
    // Handle success
    updateUI(entity);
  },
);

// Using isLeft/isRight
if (result.isLeft) {
  print('Error: ${result.left}');
} else {
  print('Success: ${result.right!.value}');
}
```

## Testing

Comprehensive tests are available in `example/test/src/data/`:

- `mappers/counter_mapper_test.dart` - Tests for mapper transformations, ArgumentError handling
- `repositories/counter_repository_test.dart` - Tests for repository operations, Either usage

Run tests with:

```bash
flutter test example/test/src/data/
```

## Related Documentation

- [DATA_LAYER_GUIDE.md](../../../../docs/DATA_LAYER_GUIDE.md) - Complete data layer guidance
- [MAPPER_READER.md](../../../../doc/MAPPER_READER.md) - Mapper API documentation
- [Error Handling Examples](../../../../docs/examples/error_handling_examples.md)
- [Validation Examples](../../../../docs/examples/validation_examples.md)

## Best Practices

1. ✅ Always return `Either<Exception, T>` from repositories
2. ✅ Use mappers for DTO ↔ Entity transformations
3. ✅ Validate at appropriate layers (repository, mapper, use case)
4. ✅ Handle `ArgumentError` from mappers gracefully
5. ✅ Create clear interfaces for repositories
6. ✅ Use caching patterns when appropriate
7. ✅ Write comprehensive tests including error paths
8. ✅ Log errors for debugging, return user-friendly messages

## Integration with Domain Layer

The data layer integrates with the domain layer through use cases:

```dart
class LoadCounterUseCase extends JUseCase<void, CounterEntity> {
  final CounterRepository _repository;

  LoadCounterUseCase(this._repository);

  @override
  Future<Either<Exception, CounterEntity>> run(void input) async {
    return await _repository.loadCounter();
  }
}
```

See the domain layer examples for complete integration patterns.
