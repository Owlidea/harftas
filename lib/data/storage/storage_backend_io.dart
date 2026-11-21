import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'storage_backend.dart';

Future<StorageBackend> create() async {
  final dir = await getApplicationDocumentsDirectory();
  return FileBackend(Directory('${dir.path}/harfblok')..createSync(recursive: true));
}

class FileBackend implements StorageBackend {
  FileBackend(this.directory);
  final Directory directory;

  File _file(String name) => File('${directory.path}/$name.json');

  @override
  Future<String?> read(String name) async {
    final f = _file(name);
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String name, String value) async {
    final f = _file(name);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(value, flush: true);
    await tmp.rename(f.path);
  }

  @override
  Future<void> delete(String name) async {
    final f = _file(name);
    if (await f.exists()) await f.delete();
  }
}
