import 'dart:developer' as developer;

class AppLogger {
  static void log(String message, {String? name}) {
    developer.log(
      message,
      name: name ?? 'AppLogger',
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'AppLogger',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void info(String message) {
    developer.log(
      message,
      name: 'AppLogger',
    );
  }

  static void warning(String message) {
    developer.log(
      message,
      name: 'AppLogger',
    );
  }
}
