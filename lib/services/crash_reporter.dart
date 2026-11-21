import 'package:flutter/foundation.dart';

/// Error / crash reporting (spec 14). v1 writes to the console; a real
/// backend (e.g. Crashlytics) can implement the same interface.
abstract interface class CrashReporter {
  void record(Object error, StackTrace? stack, {String? reason, bool fatal = false});
  void log(String message);
}

class ConsoleCrashReporter implements CrashReporter {
  const ConsoleCrashReporter();

  @override
  void record(Object error, StackTrace? stack, {String? reason, bool fatal = false}) {
    debugPrint('[crash${fatal ? ':fatal' : ''}] ${reason ?? ''} $error');
    if (stack != null) debugPrint(stack.toString());
  }

  @override
  void log(String message) => debugPrint('[log] $message');
}
