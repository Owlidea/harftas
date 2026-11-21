/// Every balance value lives here. Loaded from `assets/config/balance.json`
/// at runtime (Aşama 1e); [BalanceConfig.defaults] mirrors the spec.
class BalanceConfig {
  const BalanceConfig({
    required this.minWordLength,
    required this.maxWordLength,
    required this.letterScores,
    required this.letterWeights,
    required this.lengthMultiplierX10,
    required this.streakStepX10,
    required this.streakCapX10,
    required this.placementPointsPerCell,
    required this.clearBoardBonus,
    required this.handSize,
    required this.sizeTiers,
    required this.vowelMinRatio,
    required this.vowelMaxRatio,
    required this.minVowelsPerHand,
    required this.noDuplicateScoreThreshold,
    required this.rareLetters,
    required this.maxRarePerHand,
    required this.easingMaxAttempts,
    required this.dailyHandLimit,
    required this.initialPowerups,
  });

  /// MIN_WORD_LEN (spec 2.5). Default 3.
  final int minWordLength;
  final int maxWordLength;

  /// Letter -> points (spec 5).
  final Map<String, int> letterScores;

  /// Letter -> relative weight for random generation (spec 4).
  final Map<String, int> letterWeights;

  /// Word length -> multiplier x10 (x1.5 is stored as 15).
  final Map<int, int> lengthMultiplierX10;

  /// Streak: +step per consecutive word move, capped (x10 scale).
  final int streakStepX10;
  final int streakCapX10;

  final int placementPointsPerCell;
  final int clearBoardBonus;

  final int handSize;

  /// Piece-size weights by score (difficulty curve). Sorted by minScore.
  final List<SizeTier> sizeTiers;

  final double vowelMinRatio;
  final double vowelMaxRatio;
  final int minVowelsPerHand;

  /// Letters scoring >= this may appear at most once per hand.
  final int noDuplicateScoreThreshold;

  final Set<String> rareLetters;
  final int maxRarePerHand;

  /// Classic-mode easing rule: attempts to find a hand that can form a
  /// common word on the current grid.
  final int easingMaxAttempts;

  /// Daily puzzle: number of hands dealt (karar 6).
  final int dailyHandLimit;

  /// Classic: starting count for each powerup (refresh, joker, hammer).
  final int initialPowerups;

  int scoreOf(String letter) => letterScores[letter] ?? 0;

  List<int> sizeWeightsFor(int score) {
    var weights = sizeTiers.first.weights;
    for (final t in sizeTiers) {
      if (score >= t.minScore) weights = t.weights;
    }
    return weights;
  }

  static const BalanceConfig defaults = BalanceConfig(
    minWordLength: 3,
    maxWordLength: 8,
    letterScores: {
      'A': 1,
      'E': 1,
      'İ': 1,
      'K': 1,
      'L': 1,
      'N': 1,
      'R': 1,
      'T': 1,
      'I': 2,
      'M': 2,
      'O': 2,
      'S': 2,
      'U': 2,
      'B': 3,
      'D': 3,
      'Ü': 3,
      'Y': 3,
      'C': 4,
      'Ç': 4,
      'Ş': 4,
      'Z': 4,
      'G': 5,
      'H': 5,
      'P': 5,
      'F': 7,
      'Ö': 7,
      'V': 7,
      'Ğ': 8,
      'J': 10,
    },
    // VARSAYIM: Starting weights follow the spec's three frequency groups;
    // tuned in Aşama 2 with the simulator.
    letterWeights: {
      'A': 110,
      'E': 95,
      'İ': 85,
      'N': 70,
      'R': 68,
      'L': 62,
      'K': 52,
      'D': 46,
      'M': 42,
      'T': 40,
      'I': 38,
      'U': 33,
      'S': 32,
      'Y': 30,
      'O': 26,
      'B': 25,
      'Ü': 18,
      'Ş': 17,
      'Z': 15,
      'G': 12,
      'Ç': 11,
      'H': 10,
      'C': 9,
      'P': 8,
      'V': 7,
      'Ö': 7,
      'Ğ': 6,
      'F': 4,
      'J': 1,
    },
    lengthMultiplierX10: {3: 10, 4: 15, 5: 20, 6: 30, 7: 40, 8: 60},
    streakStepX10: 1,
    streakCapX10: 20,
    placementPointsPerCell: 1,
    clearBoardBonus: 100,
    handSize: 3,
    // Tuned in Aşama 2 (docs/denge_raporu.md).
    sizeTiers: [
      SizeTier(minScore: 0, weights: [15, 35, 35, 15]),
      SizeTier(minScore: 300, weights: [12, 33, 37, 18]),
      SizeTier(minScore: 700, weights: [9, 29, 39, 23]),
      SizeTier(minScore: 1200, weights: [6, 25, 41, 28]),
    ],
    vowelMinRatio: 0.4,
    vowelMaxRatio: 0.6,
    minVowelsPerHand: 1,
    noDuplicateScoreThreshold: 5,
    rareLetters: {'G', 'Ç', 'H', 'C', 'P', 'V', 'Ö', 'F', 'Ğ', 'J'},
    maxRarePerHand: 2,
    easingMaxAttempts: 20,
    dailyHandLimit: 20,
    initialPowerups: 1,
  );

  BalanceConfig copyWith({
    int? minWordLength,
    int? easingMaxAttempts,
    int? dailyHandLimit,
    List<SizeTier>? sizeTiers,
    Map<String, int>? letterWeights,
  }) => BalanceConfig(
    minWordLength: minWordLength ?? this.minWordLength,
    maxWordLength: maxWordLength,
    letterScores: letterScores,
    letterWeights: letterWeights ?? this.letterWeights,
    lengthMultiplierX10: lengthMultiplierX10,
    streakStepX10: streakStepX10,
    streakCapX10: streakCapX10,
    placementPointsPerCell: placementPointsPerCell,
    clearBoardBonus: clearBoardBonus,
    handSize: handSize,
    sizeTiers: sizeTiers ?? this.sizeTiers,
    vowelMinRatio: vowelMinRatio,
    vowelMaxRatio: vowelMaxRatio,
    minVowelsPerHand: minVowelsPerHand,
    noDuplicateScoreThreshold: noDuplicateScoreThreshold,
    rareLetters: rareLetters,
    maxRarePerHand: maxRarePerHand,
    easingMaxAttempts: easingMaxAttempts ?? this.easingMaxAttempts,
    dailyHandLimit: dailyHandLimit ?? this.dailyHandLimit,
    initialPowerups: initialPowerups,
  );

  factory BalanceConfig.fromJson(Map<String, dynamic> j) {
    const d = BalanceConfig.defaults;
    Map<String, int> strIntMap(Object? o, Map<String, int> fallback) =>
        o == null ? fallback : (o as Map).map((k, v) => MapEntry(k as String, (v as num).toInt()));
    return BalanceConfig(
      minWordLength: (j['minWordLength'] as num?)?.toInt() ?? d.minWordLength,
      maxWordLength: (j['maxWordLength'] as num?)?.toInt() ?? d.maxWordLength,
      letterScores: strIntMap(j['letterScores'], d.letterScores),
      letterWeights: strIntMap(j['letterWeights'], d.letterWeights),
      lengthMultiplierX10: j['lengthMultiplierX10'] == null
          ? d.lengthMultiplierX10
          : (j['lengthMultiplierX10'] as Map).map((k, v) => MapEntry(int.parse(k as String), (v as num).toInt())),
      streakStepX10: (j['streakStepX10'] as num?)?.toInt() ?? d.streakStepX10,
      streakCapX10: (j['streakCapX10'] as num?)?.toInt() ?? d.streakCapX10,
      placementPointsPerCell: (j['placementPointsPerCell'] as num?)?.toInt() ?? d.placementPointsPerCell,
      clearBoardBonus: (j['clearBoardBonus'] as num?)?.toInt() ?? d.clearBoardBonus,
      handSize: (j['handSize'] as num?)?.toInt() ?? d.handSize,
      sizeTiers: j['sizeTiers'] == null
          ? d.sizeTiers
          : [for (final t in j['sizeTiers'] as List) SizeTier.fromJson(t as Map<String, dynamic>)],
      vowelMinRatio: (j['vowelMinRatio'] as num?)?.toDouble() ?? d.vowelMinRatio,
      vowelMaxRatio: (j['vowelMaxRatio'] as num?)?.toDouble() ?? d.vowelMaxRatio,
      minVowelsPerHand: (j['minVowelsPerHand'] as num?)?.toInt() ?? d.minVowelsPerHand,
      noDuplicateScoreThreshold: (j['noDuplicateScoreThreshold'] as num?)?.toInt() ?? d.noDuplicateScoreThreshold,
      rareLetters: j['rareLetters'] == null ? d.rareLetters : {for (final l in j['rareLetters'] as List) l as String},
      maxRarePerHand: (j['maxRarePerHand'] as num?)?.toInt() ?? d.maxRarePerHand,
      easingMaxAttempts: (j['easingMaxAttempts'] as num?)?.toInt() ?? d.easingMaxAttempts,
      dailyHandLimit: (j['dailyHandLimit'] as num?)?.toInt() ?? d.dailyHandLimit,
      initialPowerups: (j['initialPowerups'] as num?)?.toInt() ?? d.initialPowerups,
    );
  }

  Map<String, dynamic> toJson() => {
    'minWordLength': minWordLength,
    'maxWordLength': maxWordLength,
    'letterScores': letterScores,
    'letterWeights': letterWeights,
    'lengthMultiplierX10': lengthMultiplierX10.map((k, v) => MapEntry('$k', v)),
    'streakStepX10': streakStepX10,
    'streakCapX10': streakCapX10,
    'placementPointsPerCell': placementPointsPerCell,
    'clearBoardBonus': clearBoardBonus,
    'handSize': handSize,
    'sizeTiers': [for (final t in sizeTiers) t.toJson()],
    'vowelMinRatio': vowelMinRatio,
    'vowelMaxRatio': vowelMaxRatio,
    'minVowelsPerHand': minVowelsPerHand,
    'noDuplicateScoreThreshold': noDuplicateScoreThreshold,
    'rareLetters': rareLetters.toList(),
    'maxRarePerHand': maxRarePerHand,
    'easingMaxAttempts': easingMaxAttempts,
    'dailyHandLimit': dailyHandLimit,
    'initialPowerups': initialPowerups,
  };
}

class SizeTier {
  const SizeTier({required this.minScore, required this.weights});

  factory SizeTier.fromJson(Map<String, dynamic> j) => SizeTier(
    minScore: (j['minScore'] as num).toInt(),
    weights: [for (final w in j['weights'] as List) (w as num).toInt()],
  );

  final int minScore;

  /// Weights for piece sizes 1, 2, 3, 4.
  final List<int> weights;

  Map<String, dynamic> toJson() => {'minScore': minScore, 'weights': weights};
}
