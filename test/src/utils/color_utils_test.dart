import 'package:flutter/painting.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:jintent/utils.dart';

void main() {
  group('shiftHsl', () {
    const base = Color(0xFF3366CC);

    test('lightens and darkens the color', () {
      final lighter = HSLColor.fromColor(JColorUtils.shiftHsl(base, 0.1));
      final darker = HSLColor.fromColor(JColorUtils.shiftHsl(base, -0.1));
      final original = HSLColor.fromColor(base);
      expect(lighter.lightness, greaterThan(original.lightness));
      expect(darker.lightness, lessThan(original.lightness));
    });

    test('clamps lightness to the valid range', () {
      expect(JColorUtils.shiftHsl(base, 2).toARGB32(), 0xFFFFFFFF);
      expect(JColorUtils.shiftHsl(base, -2).toARGB32(), 0xFF000000);
    });

    test('defaults to no shift', () {
      expect(
        HSLColor.fromColor(JColorUtils.shiftHsl(base)).lightness,
        closeTo(HSLColor.fromColor(base).lightness, 0.01),
      );
    });
  });

  test('parseHex reads the six digits after # as an opaque color', () {
    expect(JColorUtils.parseHex('#3498DB').toARGB32(), 0xFF3498DB);
    expect(JColorUtils.parseHex('#000000').toARGB32(), 0xFF000000);
  });

  group('blend', () {
    const red = Color(0xFFFF0000);
    const blue = Color(0xFF0000FF);

    test('zero opacity returns the destination color', () {
      expect(JColorUtils.blend(red, blue, 0).toARGB32(), 0xFFFF0000);
    });

    test('full opacity returns the source color', () {
      expect(JColorUtils.blend(red, blue, 1).toARGB32(), 0xFF0000FF);
    });

    test('half opacity returns the midpoint', () {
      expect(JColorUtils.blend(red, blue, 0.5).toARGB32(), 0xFF800080);
    });

    test('the result is always opaque', () {
      const translucent = Color(0x80FFFFFF);
      expect(JColorUtils.blend(translucent, red, 0.25).a, 1.0);
    });
  });
}
