import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class Logger {
  final LogLevel minLevel;

  Logger({this.minLevel = LogLevel.debug});

  void _log(LogLevel level, String message) {
    if (level.index >= minLevel.index) {
      final now = DateTime.now().toIso8601String();
      final levelStr = level.toString().split('.').last.toUpperCase();
      debugPrint('[$now] [$levelStr] $message');
    }
  }

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warning(String message) => _log(LogLevel.warning, message);

  void error(String message) => _log(LogLevel.error, message);
}