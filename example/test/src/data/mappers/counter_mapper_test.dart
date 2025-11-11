import 'package:flutter_test/flutter_test.dart';
import 'package:counter/src/data/mappers/counter_mapper.dart';
import 'package:counter/src/data/models/counter_dto.dart';
import 'package:counter/src/data/models/counter_entity.dart';

void main() {
  group('CounterBiMapper', () {
    late CounterBiMapper mapper;

    setUp(() {
      mapper = CounterBiMapper();
    });

    group('to (Entity → DTO)', () {
      test('should convert entity to DTO', () {
        final entity = CounterEntity(
          value: 5,
          lastUpdated: DateTime(2024, 1, 1),
        );

        final dto = mapper.to(entity);

        expect(dto.value, 5);
        expect(dto.lastUpdated, '2024-01-01T00:00:00.000');
      });

      test('should handle zero value', () {
        final entity = CounterEntity(value: 0, lastUpdated: DateTime.now());

        final dto = mapper.to(entity);

        expect(dto.value, 0);
        expect(dto.lastUpdated, isNotNull);
      });

      test('should handle negative value', () {
        final entity = CounterEntity(value: -5, lastUpdated: DateTime.now());

        final dto = mapper.to(entity);

        expect(dto.value, -5);
      });
    });

    group('from (DTO → Entity)', () {
      test('should convert DTO to entity', () {
        final dto = CounterDto(
          value: 5,
          lastUpdated: '2024-01-01T00:00:00.000',
        );

        final entity = mapper.from(dto);

        expect(entity.value, 5);
        expect(entity.lastUpdated, DateTime(2024, 1, 1));
      });

      test('should use current time when lastUpdated is null', () {
        final now = DateTime.now();
        final dto = CounterDto(value: 5, lastUpdated: null);

        final entity = mapper.from(dto);

        expect(entity.value, 5);
        expect(entity.lastUpdated.difference(now).inSeconds, lessThan(2));
      });

      test('should throw ArgumentError for value out of bounds (positive)', () {
        final dto = CounterDto(
          value: 15, // Above max
          lastUpdated: '2024-01-01T00:00:00.000',
        );

        expect(
          () => mapper.from(dto),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('out of bounds'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for value out of bounds (negative)', () {
        final dto = CounterDto(
          value: -15, // Below min
          lastUpdated: '2024-01-01T00:00:00.000',
        );

        expect(
          () => mapper.from(dto),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('out of bounds'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for invalid date format', () {
        final dto = CounterDto(value: 5, lastUpdated: 'invalid-date');

        expect(
          () => mapper.from(dto),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid date format'),
            ),
          ),
        );
      });

      test('ArgumentError can be caught and handled', () {
        final dto = CounterDto(
          value: 99,
          lastUpdated: '2024-01-01T00:00:00.000',
        );
        CounterEntity? entity;
        String? errorMessage;

        try {
          entity = mapper.from(dto);
        } on ArgumentError catch (e) {
          errorMessage = e.message?.toString();
          // Recovery: create default entity
          entity = CounterEntity(value: 0, lastUpdated: DateTime.now());
        }

        expect(errorMessage, contains('out of bounds'));
        expect(entity, isNotNull);
        expect(entity.value, 0);
      });
    });

    group('bidirectional transformation', () {
      test('should be reversible for valid values', () {
        final originalEntity = CounterEntity(
          value: 7,
          lastUpdated: DateTime(2024, 1, 1),
        );

        final dto = mapper.to(originalEntity);
        final reconstructedEntity = mapper.from(dto);

        expect(reconstructedEntity.value, originalEntity.value);
        expect(reconstructedEntity.lastUpdated, originalEntity.lastUpdated);
      });
    });
  });

  group('CounterMapper (JMapper)', () {
    late CounterMapper mapper;

    setUp(() {
      mapper = CounterMapper();
    });

    test('transform should convert DTO to entity', () {
      final dto = CounterDto(value: 5, lastUpdated: '2024-01-01T00:00:00.000');

      final entity = mapper.transform(dto);

      expect(entity.value, 5);
      expect(entity.lastUpdated, DateTime(2024, 1, 1));
    });

    test('transformList should convert list of DTOs', () {
      final dtos = [
        CounterDto(value: 1, lastUpdated: '2024-01-01T00:00:00.000'),
        CounterDto(value: 2, lastUpdated: '2024-01-02T00:00:00.000'),
        CounterDto(value: 3, lastUpdated: '2024-01-03T00:00:00.000'),
      ];

      final entities = mapper.transformList(dtos);

      expect(entities.length, 3);
      expect(entities[0].value, 1);
      expect(entities[1].value, 2);
      expect(entities[2].value, 3);
    });

    test('transformDynamic should handle single DTO', () {
      final dto = CounterDto(value: 5, lastUpdated: '2024-01-01T00:00:00.000');

      final result = mapper.transformDynamic(dto);

      expect(result, isA<CounterEntity>());
      expect((result as CounterEntity).value, 5);
    });

    test('transformDynamic should handle list of DTOs', () {
      final dtos = [
        CounterDto(value: 1, lastUpdated: '2024-01-01T00:00:00.000'),
        CounterDto(value: 2, lastUpdated: '2024-01-02T00:00:00.000'),
      ];

      final result = mapper.transformDynamic(dtos);

      expect(result, isA<List<CounterEntity>>());
      expect((result as List<CounterEntity>).length, 2);
    });

    test(
      'transformDynamic should throw ArgumentError for unsupported type',
      () {
        expect(
          () => mapper.transformDynamic('invalid'),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('should throw ArgumentError for value out of range', () {
      final dto = CounterDto(value: 99, lastUpdated: '2024-01-01T00:00:00.000');

      expect(
        () => mapper.transform(dto),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('out of valid range'),
          ),
        ),
      );
    });

    test('should handle null lastUpdated with current time', () {
      final now = DateTime.now();
      final dto = CounterDto(value: 5, lastUpdated: null);

      final entity = mapper.transform(dto);

      expect(entity.value, 5);
      expect(entity.lastUpdated.difference(now).inSeconds, lessThan(2));
    });

    test('ArgumentError recovery example', () {
      final dto = CounterDto(
        value: 100,
        lastUpdated: '2024-01-01T00:00:00.000',
      );
      CounterEntity? result;
      bool hadError = false;

      try {
        result = mapper.transform(dto);
      } on ArgumentError catch (_) {
        hadError = true;
        // Recovery: use default value
        result = CounterEntity(value: 0, lastUpdated: DateTime.now());
      }

      expect(hadError, true);
      expect(result, isNotNull);
      expect(result.value, 0);
    });
  });
}
