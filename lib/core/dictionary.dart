import 'text/word_key.dart';

/// Word lookup used by the core. Implementations live in the data layer;
/// [SetWordDictionary] is a simple in-memory version (also used in tests).
abstract interface class WordDictionary {
  bool containsKey(int key);
  Iterable<int> get keys;
  int get size;
  bool get isEmpty;
}

class SetWordDictionary implements WordDictionary {
  SetWordDictionary(Set<int> keys) : _keys = keys;

  factory SetWordDictionary.fromWords(Iterable<String> words) {
    final keys = <int>{};
    for (final w in words) {
      final k = WordKey.fromWord(w);
      if (k != null) keys.add(k);
    }
    return SetWordDictionary(keys);
  }

  static final SetWordDictionary empty = SetWordDictionary(<int>{});

  final Set<int> _keys;

  @override
  bool containsKey(int key) => _keys.contains(key);

  @override
  Iterable<int> get keys => _keys;

  @override
  int get size => _keys.length;

  @override
  bool get isEmpty => _keys.isEmpty;
}
