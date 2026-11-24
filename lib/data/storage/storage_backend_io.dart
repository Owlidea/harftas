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

  /// Tail of the pending operations per document. The app saves without
  /// awaiting (after every move, and again when a reward lands in the same
  /// tick); two overlapping writes would share one temp file and could
  /// interleave into a corrupt document, which the store then resets. Running
  /// them one after another per name keeps every save whole and in order.
  final Map<String, Future<void>> _tail = {};

  Future<void> _enqueue(String name, Future<void> Function() op) {
    final previous = _tail[name] ?? Future<void>.value();
    // A failed operation must not block the ones queued behind it.
    final next = previous.then((_) => op(), onError: (_) => op());
    _tail[name] = next;
    return next.whenComplete(() {
      if (identical(_tail[name], next)) _tail.remove(name);
    });
  }

  @override
  Future<void> write(String name, String value) => _enqueue(name, () async {
    final f = _file(name);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(value, flush: true);
    await tmp.rename(f.path);
  });

  @override
  Future<void> delete(String name) => _enqueue(name, () async {
    final f = _file(name);
    if (await f.exists()) await f.delete();
  });
}
