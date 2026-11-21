import 'package:web/web.dart' as web;

import 'storage_backend.dart';

Future<StorageBackend> create() async => LocalStorageBackend();

/// Browser localStorage. Writes are synchronous and atomic per key.
class LocalStorageBackend implements StorageBackend {
  static const _prefix = 'harfblok.';

  @override
  Future<String?> read(String name) async => web.window.localStorage.getItem('$_prefix$name');

  @override
  Future<void> write(String name, String value) async => web.window.localStorage.setItem('$_prefix$name', value);

  @override
  Future<void> delete(String name) async => web.window.localStorage.removeItem('$_prefix$name');
}
