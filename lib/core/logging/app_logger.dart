import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] [KhmerHorror] $message');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO]  [KhmerHorror] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARN]  [KhmerHorror] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] [KhmerHorror] $message');
      if (error != null) {
        debugPrint('Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stack: $stackTrace');
      }
    }
  }
}
