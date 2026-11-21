/// Seeded deterministic PRNG: xoshiro128** (32-bit state words).
///
/// All 32x32-bit multiplications go through [mul32], which stays below 2^53,
/// so the native VM and the web produce bit-identical sequences.
///
/// Every hand gets its own stream: `Rng.stream(seed, handCounter)`. That
/// makes daily hands depend only on (date, hand number) — karar 5 — and lets
/// a game be replayed from seed + actions.
class Rng {
  Rng.fromSeed(int seed) {
    var sm = seed & _m;
    int next() {
      sm = (sm + 0x9E3779B9) & _m;
      return fmix32(sm);
    }

    _s0 = next();
    _s1 = next();
    _s2 = next();
    _s3 = next();
    if ((_s0 | _s1 | _s2 | _s3) == 0) _s0 = 1;
  }

  factory Rng.stream(int seed, int stream) => Rng.fromSeed(mix(seed, stream));

  static const int _m = 0xFFFFFFFF;

  late int _s0;
  late int _s1;
  late int _s2;
  late int _s3;

  static int _rotl(int x, int k) => ((x << k) & _m | (x >> (32 - k))) & _m;

  /// (a * b) mod 2^32 without exceeding 2^53 in intermediate results.
  static int mul32(int a, int b) {
    final aLo = a & 0xFFFF;
    final aHi = (a >> 16) & 0xFFFF;
    final b32 = b & _m;
    return (aLo * b32 + ((aHi * b32) & 0xFFFF) * 0x10000) & _m;
  }

  /// murmur3 finalizer.
  static int fmix32(int h) {
    var x = h & _m;
    x ^= x >> 16;
    x = mul32(x, 0x85EBCA6B);
    x ^= x >> 13;
    x = mul32(x, 0xC2B2AE35);
    x ^= x >> 16;
    return x;
  }

  /// Combines two integers into a well-distributed 32-bit seed.
  static int mix(int a, int b) => fmix32((fmix32(a) ^ ((mul32(b, 0x9E3779B1) + 0x7F4A7C15) & _m)) & _m);

  /// Daily seed from a calendar date (Europe/Istanbul date supplied by caller).
  static int dailySeed(int year, int month, int day) => mix(0x48424C4B, year * 10000 + month * 100 + day);

  int nextUint32() {
    final result = mul32(_rotl(mul32(_s1, 5), 7), 9);
    final t = (_s1 << 9) & _m;
    _s2 ^= _s0;
    _s3 ^= _s1;
    _s1 ^= _s2;
    _s0 ^= _s3;
    _s2 ^= t;
    _s3 = _rotl(_s3, 11);
    return result;
  }

  /// Uniform integer in [0, max). Unbiased (rejection sampling).
  int nextInt(int max) {
    if (max <= 0) throw ArgumentError.value(max, 'max');
    const range = 0x100000000;
    final limit = range - (range % max);
    while (true) {
      final r = nextUint32();
      if (r < limit) return r % max;
    }
  }

  /// Index chosen proportionally to [weights] (non-negative, sum > 0).
  int weighted(List<int> weights) {
    var total = 0;
    for (final w in weights) {
      total += w;
    }
    if (total <= 0) throw StateError('weights sum to zero');
    var r = nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      r -= weights[i];
      if (r < 0) return i;
    }
    return weights.length - 1;
  }

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
