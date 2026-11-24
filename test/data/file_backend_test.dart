import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/data/storage/storage_backend_io.dart';

void main() {
  late Directory dir;
  late FileBackend backend;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('hb_store');
    backend = FileBackend(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('overlapping writes to one document land whole and in order', () async {
    // Saves are fired without awaiting; payloads of very different sizes
    // would interleave if two writers shared the temp file.
    final writes = <Future<void>>[
      for (var i = 0; i < 40; i++) backend.write('profile', '{"n":$i,"pad":"${'x' * ((i * 7919) % 4000)}"}'),
    ];
    await Future.wait(writes);
    final last = '{"n":39,"pad":"${'x' * ((39 * 7919) % 4000)}"}';
    expect(await backend.read('profile'), last);
    expect(dir.listSync().whereType<File>().where((f) => f.path.endsWith('.tmp')), isEmpty);
  });

  test('a delete queued after a write wins, and a later write brings the file back', () async {
    final a = backend.write('game', 'one');
    final b = backend.delete('game');
    await Future.wait([a, b]);
    expect(await backend.read('game'), isNull);
    await backend.write('game', 'two');
    expect(await backend.read('game'), 'two');
  });

  test('documents do not wait on each other and a failure does not jam the queue', () async {
    final missing = FileBackend(Directory('${dir.path}/gone'));
    await expectLater(missing.write('x', '1'), throwsA(isA<FileSystemException>()));
    Directory('${dir.path}/gone').createSync();
    await missing.write('x', '2');
    expect(await missing.read('x'), '2');
    await Future.wait([backend.write('a', 'A'), backend.write('b', 'B')]);
    expect([await backend.read('a'), await backend.read('b')], ['A', 'B']);
  });
}
