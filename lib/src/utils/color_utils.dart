import 'package:flutter/material.dart';

/// A utility class for performing color manipulations.
///
/// The `ColorUtils` class provides static methods for common color
/// transformations, such as shifting brightness, parsing hexadecimal color
/// strings, and blending two colors.
///
/// ### Example Usage
/// ```dart
/// final color = ColorUtils.shiftHsl(Colors.blue, 0.2); // Lighten the color.
/// final parsedColor = ColorUtils.parseHex("#FF5733"); // Parse a hex color string.
/// final blendedColor = ColorUtils.blend(Colors.red, Colors.blue, 0.5); // Blend red and blue.
/// ```
class JColorUtils {
  /// Shifts the lightness of a color in the HSL color space.
  ///
  /// This method adjusts the lightness of the given [Color] by a specified amount.
  /// The [amt] parameter specifies the amount to shift the lightness, where
  /// positive values lighten the color and negative values darken it.
  ///
  /// ### Parameters
  /// - `c`: The original [Color] to be adjusted.
  /// - `amt`: The amount to shift the lightness. Default is `0`.
  ///
  /// ### Returns
  /// A new [Color] with the adjusted lightness.
  ///
  /// ### Example
  /// ```dart
  /// final lighterColor = ColorUtils.shiftHsl(Colors.green, 0.1); // Lighten by 10%.
  /// final darkerColor = ColorUtils.shiftHsl(Colors.green, -0.1); // Darken by 10%.
  /// ```
  static Color shiftHsl(Color c, [double amt = 0]) {
    var hslc = HSLColor.fromColor(c);
    return hslc.withLightness((hslc.lightness + amt).clamp(0.0, 1.0)).toColor();
  }

  /// Parses a hexadecimal color string into a [Color].
  ///
  /// This method converts a string representing a hexadecimal color (e.g., `#RRGGBB`)
  /// into a [Color] object. The string must start with `#` and contain six hexadecimal digits.
  ///
  /// ### Parameters
  /// - `value`: The hexadecimal color string to parse.
  ///
  /// ### Returns
  /// A [Color] corresponding to the given hexadecimal string.
  ///
  /// ### Example
  /// ```dart
  /// final color = ColorUtils.parseHex("#3498DB"); // Converts to Color(0xFF3498DB).
  /// ```
  static Color parseHex(String value) =>
      Color(int.parse(value.substring(1, 7), radix: 16) + 0xFF000000);

  /// Blends two colors with a specified opacity.
  ///
  /// This method creates a new [Color] by blending the destination [dst] color
  /// with the source [src] color. The [opacity] parameter determines the
  /// influence of the source color, where `0.0` means no influence (returns
  /// the destination color) and `1.0` means full influence (returns the source color).
  ///
  /// ### Parameters
  /// - `dst`: The destination [Color] (background).
  /// - `src`: The source [Color] (foreground).
  /// - `opacity`: The opacity of the source color in the blend. Must be between `0.0` and `1.0`.
  ///
  /// ### Returns
  /// A new [Color] representing the blend of the two colors.
  ///
  /// ### Example
  /// ```dart
  /// final blended = ColorUtils.blend(Colors.red, Colors.blue, 0.5); // Purple blend.
  /// ```
  static Color blend(Color dst, Color src, double opacity) {
    return Color.fromARGB(
      255,
      (dst.r.toDouble() * (1.0 - opacity) + src.r.toDouble() * opacity).toInt(),
      (dst.g.toDouble() * (1.0 - opacity) + src.g.toDouble() * opacity).toInt(),
      (dst.b.toDouble() * (1.0 - opacity) + src.b.toDouble() * opacity).toInt(),
    );
  }
}
