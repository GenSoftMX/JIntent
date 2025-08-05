class JValidationUtils {
  /// Returns the [value] as [int] if valid, otherwise returns [defaultValue].
  static int intOrDefault(dynamic value, {int defaultValue = 0}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Returns the [value] as [double] if valid, otherwise returns [defaultValue].
  static double doubleOrDefault(dynamic value, {double defaultValue = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Returns the [value] as non-empty string, otherwise returns [defaultValue].
  static String stringOrDefault(String? value, {String defaultValue = ''}) {
    if (value == null || value.trim().isEmpty) return defaultValue;
    return value;
  }

  /// Returns the [value] as [bool] if valid, otherwise returns [defaultValue].
  static bool boolOrDefault(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    if (value is num) return value != 0;
    return defaultValue;
  }

  /// Returns the [value] as [DateTime] if valid, otherwise returns [defaultValue] or Epoch.
  static DateTime dateOrDefault(dynamic value, {DateTime? defaultValue}) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return defaultValue ?? DateTime(1970);
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return defaultValue ?? DateTime(1970);
      }
    }
    return defaultValue ?? DateTime(1970);
  }

  /// Parses a string to int and clamps it between [min] and [max]. Returns [defaultValue] if parsing fails.
  static int parseIntInRange(
    String? value, {
    int min = 0,
    int max = 100,
    int defaultValue = 0,
  }) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null) return defaultValue;
    return parsed.clamp(min, max);
  }

  /// Returns true if the string length is within [min] and [max] bounds.
  static bool isTextLengthInRange(String? value, {int min = 1, int max = 255}) {
    final length = value?.length ?? 0;
    return length >= min && length <= max;
  }
}
