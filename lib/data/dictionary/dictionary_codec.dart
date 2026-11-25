import 'dart:typed_data';

/// Packed dictionary format (shared by tool/build_dictionary.dart and the app):
///
///   "HBD3" | uint32 LE count | count x 6-byte LE word keys, ascending
///
/// Word keys come from `WordKey` (base-64 digits, <= 8 letters = 48 bits;
/// HBD2 held base-32 keys in 5 bytes and is no longer read).
/// One pair of files per word language: `assets/dict/{words,common}_<code>.bin`.
/// Not compressed: app bundles and web servers compress assets anyway, and
/// this keeps decoding pure Dart (works on the web).
abstract final class DictionaryCodec {
  static const List<int> magic = [0x48, 0x42, 0x44, 0x33]; // "HBD3"
  static const int keyBytes = 6;

  static Uint8List encode(Iterable<int> keys) {
    final sorted = keys.toSet().toList()..sort();
    final raw = Uint8List(8 + sorted.length * keyBytes);
    raw.setRange(0, 4, magic);
    ByteData.sublistView(raw).setUint32(4, sorted.length, Endian.little);
    var o = 8;
    for (final k in sorted) {
      var rest = k;
      for (var b = 0; b < keyBytes; b++) {
        raw[o++] = rest % 256;
        rest ~/= 256;
      }
    }
    return raw;
  }

  /// Throws [FormatException] for corrupt input.
  static Set<int> decode(List<int> raw) {
    if (raw.length < 8) throw const FormatException('dictionary: too short');
    for (var i = 0; i < 4; i++) {
      if (raw[i] != magic[i]) throw const FormatException('dictionary: bad magic');
    }
    final bytes = raw is Uint8List ? raw : Uint8List.fromList(raw);
    final count = ByteData.sublistView(bytes).getUint32(4, Endian.little);
    if (bytes.length != 8 + count * keyBytes) {
      throw const FormatException('dictionary: length mismatch');
    }
    final out = <int>{};
    var o = 8;
    for (var i = 0; i < count; i++) {
      // Arithmetic (not shifts) so 48-bit keys decode correctly on the web.
      var k = 0;
      var scale = 1;
      for (var b = 0; b < keyBytes; b++) {
        k += bytes[o++] * scale;
        scale *= 256;
      }
      out.add(k);
    }
    return out;
  }
}
