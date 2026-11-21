import 'storage_backend_io.dart' if (dart.library.js_interop) 'storage_backend_web.dart' as impl;

/// String documents by name. One implementation per platform.
abstract interface class StorageBackend {
  Future<String?> read(String name);
  Future<void> write(String name, String value);
  Future<void> delete(String name);
}

/// Files on iOS/Android/desktop, localStorage on the web.
Future<StorageBackend> createStorageBackend() => impl.create();

/// In-memory backend (tests).
class MemoryBackend implements StorageBackend {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String name) async => data[name];
  @override
  Future<void> write(String name, String value) async => data[name] = value;
  @override
  Future<void> delete(String name) async => data.remove(name);
}
