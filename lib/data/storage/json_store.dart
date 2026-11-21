import 'dart:convert';

import '../../services/crash_reporter.dart';
import 'storage_backend.dart';

/// Versioned JSON documents (spec 14) on a platform backend:
/// files in the app documents directory (iOS/Android), localStorage (web).
///
/// - File writes are atomic (temp file + rename).
/// - A document that fails to parse or decode is set aside as
///   `<name>.corrupt` and treated as missing (safe reset); the crash reporter
///   is told.
class JsonStore {
  JsonStore(this.backend, {required this.crash});

  final StorageBackend backend;
  final CrashReporter crash;

  Future<T?> read<T>(String name, T Function(Map<String, dynamic>) decode) async {
    final raw = await backend.read(name);
    if (raw == null) return null;
    try {
      return decode(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e, st) {
      crash.record(e, st, reason: 'corrupt save "$name" — reset');
      await backend.write('$name.corrupt', raw);
      await backend.delete(name);
      return null;
    }
  }

  Future<void> write(String name, Map<String, dynamic> json) => backend.write(name, jsonEncode(json));

  Future<void> delete(String name) => backend.delete(name);
}
