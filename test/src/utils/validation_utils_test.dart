import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/utils.dart';

void main() {
  group('intOrDefault', () {
    test('returns ints and parses numeric strings', () {
      expect(JValidationUtils.intOrDefault(7), 7);
      expect(JValidationUtils.intOrDefault('42'), 42);
    });

    test('falls back for invalid strings and other types', () {
      expect(JValidationUtils.intOrDefault('x', defaultValue: 3), 3);
      expect(JValidationUtils.intOrDefault(1.5, defaultValue: 9), 9);
      expect(JValidationUtils.intOrDefault(null), 0);
    });
  });

  group('doubleOrDefault', () {
    test('accepts doubles, ints and numeric strings', () {
      expect(JValidationUtils.doubleOrDefault(1.5), 1.5);
      expect(JValidationUtils.doubleOrDefault(2), 2.0);
      expect(JValidationUtils.doubleOrDefault('3.25'), 3.25);
    });

    test('falls back for invalid values', () {
      expect(JValidationUtils.doubleOrDefault('x', defaultValue: 1.0), 1.0);
      expect(JValidationUtils.doubleOrDefault(true, defaultValue: 2.0), 2.0);
    });
  });

  group('stringOrDefault', () {
    test('keeps non-blank strings untouched', () {
      expect(JValidationUtils.stringOrDefault(' a '), ' a ');
    });

    test('falls back for null, empty and blank strings', () {
      expect(JValidationUtils.stringOrDefault(null, defaultValue: 'd'), 'd');
      expect(JValidationUtils.stringOrDefault('', defaultValue: 'd'), 'd');
      expect(JValidationUtils.stringOrDefault('   ', defaultValue: 'd'), 'd');
    });
  });

  group('boolOrDefault', () {
    test('accepts bools, text flags and numbers', () {
      expect(JValidationUtils.boolOrDefault(true), isTrue);
      expect(JValidationUtils.boolOrDefault('TRUE'), isTrue);
      expect(JValidationUtils.boolOrDefault('1'), isTrue);
      expect(
        JValidationUtils.boolOrDefault('false', defaultValue: true),
        false,
      );
      expect(JValidationUtils.boolOrDefault('0', defaultValue: true), false);
      expect(JValidationUtils.boolOrDefault(2), isTrue);
      expect(JValidationUtils.boolOrDefault(0, defaultValue: true), isFalse);
    });

    test('falls back for unknown text and other types', () {
      expect(JValidationUtils.boolOrDefault('maybe', defaultValue: true), true);
      expect(JValidationUtils.boolOrDefault(null, defaultValue: true), true);
    });
  });

  group('dateOrDefault', () {
    final fallback = DateTime(2020, 1, 2);

    test('returns dates and parses ISO strings and epoch milliseconds', () {
      final now = DateTime(2024, 5, 6);
      expect(JValidationUtils.dateOrDefault(now), now);
      expect(
        JValidationUtils.dateOrDefault('2024-05-06T00:00:00.000'),
        DateTime(2024, 5, 6),
      );
      expect(
        JValidationUtils.dateOrDefault(1000),
        DateTime.fromMillisecondsSinceEpoch(1000),
      );
    });

    test(
      'falls back for invalid strings, out-of-range ints and other types',
      () {
        expect(
          JValidationUtils.dateOrDefault('nope', defaultValue: fallback),
          fallback,
        );
        expect(JValidationUtils.dateOrDefault('nope'), DateTime(1970));
        expect(
          JValidationUtils.dateOrDefault(1 << 62, defaultValue: fallback),
          fallback,
        );
        expect(JValidationUtils.dateOrDefault(1 << 62), DateTime(1970));
        expect(JValidationUtils.dateOrDefault(1.5), DateTime(1970));
        expect(
          JValidationUtils.dateOrDefault(null, defaultValue: fallback),
          fallback,
        );
      },
    );
  });

  group('parseIntInRange', () {
    test('clamps parsed values to the range', () {
      expect(JValidationUtils.parseIntInRange('50'), 50);
      expect(JValidationUtils.parseIntInRange('500'), 100);
      expect(JValidationUtils.parseIntInRange('-5', min: -2, max: 2), -2);
    });

    test('uses the default when parsing fails', () {
      expect(JValidationUtils.parseIntInRange('x', defaultValue: 4), 4);
      expect(JValidationUtils.parseIntInRange(null, defaultValue: 5), 5);
    });
  });

  group('isTextLengthInRange', () {
    test('checks inclusive bounds', () {
      expect(JValidationUtils.isTextLengthInRange('a'), isTrue);
      expect(JValidationUtils.isTextLengthInRange('abc', max: 3), isTrue);
      expect(JValidationUtils.isTextLengthInRange('abcd', max: 3), isFalse);
    });

    test('treats null as empty', () {
      expect(JValidationUtils.isTextLengthInRange(null), isFalse);
      expect(JValidationUtils.isTextLengthInRange(null, min: 0), isTrue);
    });
  });
}
