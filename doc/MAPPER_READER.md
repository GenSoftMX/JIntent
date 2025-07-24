# 🧭 Mapper Library for Dart/Flutter

A generic, extensible and reusable way to transform objects between types in Dart or Flutter. Designed to support one-way and two-way mapping for domain models, DTOs, network responses, database entities, and more.

---

## ✨ Features

- ✅ One-to-one transformation via `JMapper`
- ✅ List transformation via `transformList` or `mapWith` extension
- ✅ Dynamic support for mapping a single item or a list
- ✅ Two-way (bidirectional) mapping with `IBiMapper`
- ✅ Simple and testable abstraction layer

---

## 🚀 Getting Started

### 1. Extend `JMapper` to define a one-way transformation

```dart
class UserMapper extends JMapper<UserEntity, UserDto> {
  @override
  UserDto map(UserEntity entity) {
    return UserDto(
      id: entity.id,
      name: entity.fullName,
    );
  }
}
````

### 2. Use the mapper

```dart
final mapper = UserMapper();

// Map a single item
final dto = mapper.transform(user);

// Map a list
final listDto = mapper.transformList(userList);

// Dynamic mapping
final result = mapper.transformDynamic(userOrList);
```

---

## 🧩 `IMapper<INPUT, OUTPUT>`

### Description

`IMapper` is an abstract interface that defines a standard contract for converting one type of data (`INPUT`) into another (`OUTPUT`). This is particularly useful in layered architectures (e.g., domain-to-DTO mapping, model-to-entity transformation).

### Use Cases

* Mapping API response models to domain models.
* Mapping database entities to presentation-layer DTOs.
* Encapsulating transformation logic across layers for better separation of concerns.

### Methods

#### `OUTPUT transform(INPUT entity)`

Transforms a single instance of `INPUT` into an `OUTPUT`.

#### `List<OUTPUT> transformList(List<INPUT> array)`

Transforms a list of `INPUT` objects into a list of `OUTPUT`.

#### `dynamic transformDynamic(dynamic entityOrArray)`

Dynamically transforms either a single `INPUT` or a list of `INPUT` into `OUTPUT` or `List<OUTPUT>`.
Throws `ArgumentError` if input is neither valid.

---

## ⚙️ `JMapper<INPUT, OUTPUT>`

### Description

`JMapper` is a base abstract class that implements `IMapper` and provides default logic for all transformation methods by delegating to a single abstract method: `map()`.

### Responsibilities

* Acts as a utility base class for mappers.
* Reduces boilerplate in concrete implementations.
* Standardizes mapping logic throughout the application.

### Methods

#### `OUTPUT map(INPUT entity)`

Abstract method to be implemented in subclasses.

#### `OUTPUT transform(INPUT entity)`

Delegates to `map()`.

#### `List<OUTPUT> transformList(List<INPUT> array)`

Applies `map()` to each element.

#### `dynamic transformDynamic(dynamic entityOrArray)`

Dispatches mapping based on runtime type. Throws if unsupported.

### Example

```dart
class UserToDtoMapper extends JMapper<User, UserDto> {
  @override
  UserDto map(User user) => UserDto(name: user.name);
}

// Usage
final mapper = UserToDtoMapper();
UserDto dto = mapper.transform(user);
List<UserDto> dtos = mapper.transformList(users);
```

---

## ➕ Extensions

### `mapWith` Extension

```dart
/// Extension on [List] providing a convenient method to map elements
/// with a [JMapper].
extension MapWithExtension<T> on List<T> {
  /// Maps the list elements using the provided [mapper].
  ///
  /// Returns a new list with the mapped elements of type [R].
  List<R> mapWith<R>(JMapper<T, R> mapper) => mapper.transformList(this);
}
```

This allows transforming a list in a fluent and readable way:

```dart
final userDtos = userList.mapWith(UserToDtoMapper());
```

---

## 🔄 `IBiMapper<A, B>`

### Description

`IBiMapper` defines a contract for bidirectional transformation between types `A` and `B`. It's useful when the conversion logic must go both ways, e.g., when syncing DTOs with entities or when preparing data for forms.

### Methods

#### `B to(A input)`

Maps from type A to B.

#### `A from(B output)`

Maps from type B back to A.

### Example

```dart
class UserBiMapper implements IBiMapper<User, UserDto> {
  @override
  UserDto to(User input) => UserDto(name: input.name);

  @override
  User from(UserDto output) => User(name: output.name);
}
```

---

## 🧪 Testing

Because mappers are pure and synchronous, they are very easy to test:

```dart
void main() {
  final mapper = UserMapper();

  test('should map UserEntity to UserDto', () {
    final entity = UserEntity(id: 1, fullName: 'Alice');
    final dto = mapper.transform(entity);

    expect(dto.id, 1);
    expect(dto.name, 'Alice');
  });
}
```

---
## 📌 License

MIT — feel free to use, modify and share.

---

Made with ❤️ for clean architecture in Dart.
