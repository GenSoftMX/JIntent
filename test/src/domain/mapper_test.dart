import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/src/domain/mapper.dart';

// Test models
class UserEntity {
  final int id;
  final String fullName;
  final String email;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
  });
}

class UserDto {
  final int id;
  final String name;
  final String email;

  UserDto({
    required this.id,
    required this.name,
    required this.email,
  });
}

// Test mapper implementation
class UserMapper extends JMapper<UserEntity, UserDto> {
  @override
  UserDto map(UserEntity entity) {
    return UserDto(
      id: entity.id,
      name: entity.fullName,
      email: entity.email,
    );
  }
}

// Test bidirectional mapper
class UserBiMapper implements IBiMapper<UserEntity, UserDto> {
  @override
  UserDto to(UserEntity input) {
    return UserDto(
      id: input.id,
      name: input.fullName,
      email: input.email,
    );
  }

  @override
  UserEntity from(UserDto output) {
    return UserEntity(
      id: output.id,
      fullName: output.name,
      email: output.email,
    );
  }
}

void main() {
  group('JMapper', () {
    late UserMapper mapper;

    setUp(() {
      mapper = UserMapper();
    });

    test('transform should map single entity to DTO', () {
      final entity = UserEntity(
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final dto = mapper.transform(entity);

      expect(dto.id, 1);
      expect(dto.name, 'John Doe');
      expect(dto.email, 'john@example.com');
    });

    test('transformList should map list of entities to list of DTOs', () {
      final entities = [
        UserEntity(id: 1, fullName: 'John Doe', email: 'john@example.com'),
        UserEntity(id: 2, fullName: 'Jane Smith', email: 'jane@example.com'),
      ];

      final dtos = mapper.transformList(entities);

      expect(dtos.length, 2);
      expect(dtos[0].id, 1);
      expect(dtos[0].name, 'John Doe');
      expect(dtos[1].id, 2);
      expect(dtos[1].name, 'Jane Smith');
    });

    test('transformDynamic should handle single entity', () {
      final entity = UserEntity(
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final result = mapper.transformDynamic(entity);

      expect(result, isA<UserDto>());
      expect((result as UserDto).id, 1);
      expect(result.name, 'John Doe');
    });

    test('transformDynamic should handle list of entities', () {
      final entities = [
        UserEntity(id: 1, fullName: 'John Doe', email: 'john@example.com'),
        UserEntity(id: 2, fullName: 'Jane Smith', email: 'jane@example.com'),
      ];

      final result = mapper.transformDynamic(entities);

      expect(result, isA<List<UserDto>>());
      expect((result as List<UserDto>).length, 2);
      expect(result[0].id, 1);
      expect(result[1].id, 2);
    });

    test('transformDynamic should throw ArgumentError for unsupported type', () {
      expect(
        () => mapper.transformDynamic('invalid string'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('transformDynamic should throw ArgumentError for null', () {
      expect(
        () => mapper.transformDynamic(null),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('transformDynamic should throw ArgumentError for wrong type', () {
      expect(
        () => mapper.transformDynamic(123),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('transformDynamic ArgumentError can be caught and recovered', () {
      dynamic input = 'invalid input';
      UserDto? result;
      String? errorMessage;

      try {
        result = mapper.transformDynamic(input);
      } on ArgumentError catch (e) {
        errorMessage = e.message?.toString();
        // Recovery: provide default value
        result = UserDto(
          id: -1,
          name: 'Unknown',
          email: 'unknown@example.com',
        );
      }

      expect(errorMessage, 'Unsupported type');
      expect(result, isNotNull);
      expect(result!.id, -1);
      expect(result.name, 'Unknown');
    });
  });

  group('MapWithExtension', () {
    test('mapWith should transform list using mapper', () {
      final mapper = UserMapper();
      final entities = [
        UserEntity(id: 1, fullName: 'John Doe', email: 'john@example.com'),
        UserEntity(id: 2, fullName: 'Jane Smith', email: 'jane@example.com'),
      ];

      final dtos = entities.mapWith(mapper);

      expect(dtos.length, 2);
      expect(dtos[0].id, 1);
      expect(dtos[0].name, 'John Doe');
      expect(dtos[1].id, 2);
      expect(dtos[1].name, 'Jane Smith');
    });

    test('mapWith should handle empty list', () {
      final mapper = UserMapper();
      final entities = <UserEntity>[];

      final dtos = entities.mapWith(mapper);

      expect(dtos, isEmpty);
    });
  });

  group('IBiMapper', () {
    late UserBiMapper biMapper;

    setUp(() {
      biMapper = UserBiMapper();
    });

    test('to should map from entity to DTO', () {
      final entity = UserEntity(
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final dto = biMapper.to(entity);

      expect(dto.id, 1);
      expect(dto.name, 'John Doe');
      expect(dto.email, 'john@example.com');
    });

    test('from should map from DTO back to entity', () {
      final dto = UserDto(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
      );

      final entity = biMapper.from(dto);

      expect(entity.id, 1);
      expect(entity.fullName, 'John Doe');
      expect(entity.email, 'john@example.com');
    });

    test('bidirectional mapping should be reversible', () {
      final originalEntity = UserEntity(
        id: 1,
        fullName: 'John Doe',
        email: 'john@example.com',
      );

      final dto = biMapper.to(originalEntity);
      final reconstructedEntity = biMapper.from(dto);

      expect(reconstructedEntity.id, originalEntity.id);
      expect(reconstructedEntity.fullName, originalEntity.fullName);
      expect(reconstructedEntity.email, originalEntity.email);
    });
  });
}
