import 'package:flutter_test/flutter_test.dart';
import 'package:harfblok/progress/levels.dart';
import 'package:harfblok/progress/missions.dart';
import 'package:harfblok/progress/next_goal.dart';

Mission _m(int progress, int target) =>
    Mission(type: MissionType.wordsOfLength, tier: MissionTier.easy, target: target, length: 4, progress: progress);

void main() {
  test('a record within reach wins', () {
    final g = NextGoal.pick(score: 600, best: 640, missions: [_m(4, 5)], totalXp: 0);
    expect(g, isA<RecordGoal>());
    expect((g as RecordGoal).pointsLeft, 40);
    expect(g.fraction, closeTo(600 / 640, 1e-9));
  });

  test('a far-away record is not dangled; the closest mission is', () {
    final g = NextGoal.pick(score: 100, best: 640, missions: [_m(2, 5), _m(4, 5), _m(5, 5)], totalXp: 0);
    expect(g, isA<MissionGoal>());
    expect((g as MissionGoal).mission.progress, 4); // done and <50% missions are skipped
  });

  test('falls back to the next level', () {
    final g = NextGoal.pick(score: 700, best: 700, missions: [_m(1, 5)], totalXp: 120);
    expect(g, isA<LevelGoal>());
    g as LevelGoal;
    expect(g.nextLevel, 2);
    expect(g.xpLeft, Levels.xpToNext(1) - 120);
    expect(g.fraction, closeTo(120 / Levels.xpToNext(1), 1e-9));
  });

  test('first game ever (no best yet) shows the level goal', () {
    expect(NextGoal.pick(score: 50, best: 0, missions: const [], totalXp: 0), isA<LevelGoal>());
  });
}
