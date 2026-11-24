import 'levels.dart';
import 'missions.dart';

/// The single "one more game" nudge shown on the game-over sheet: whichever
/// goal the player is closest to. Pure, so it can be unit-tested.
sealed class NextGoal {
  const NextGoal(this.fraction);

  /// Progress towards the goal, 0..1.
  final double fraction;

  /// [best] is the best score *before* being raised by this game when the
  /// game was not a record, i.e. the value still to beat.
  static NextGoal pick({required int score, required int best, required List<Mission> missions, required int totalXp}) {
    // A record within reach beats everything else.
    if (best > 0 && score < best && score * 10 >= best * 6) {
      return RecordGoal(pointsLeft: best - score, fraction: score / best);
    }
    Mission? closest;
    for (final m in missions) {
      if (m.done || m.fraction < 0.5) continue;
      if (closest == null || m.fraction > closest.fraction) closest = m;
    }
    if (closest != null) return MissionGoal(closest);
    final lv = Levels.fromTotalXp(totalXp);
    return LevelGoal(nextLevel: lv.level + 1, xpLeft: lv.needed - lv.intoLevel, fraction: lv.intoLevel / lv.needed);
  }
}

class RecordGoal extends NextGoal {
  const RecordGoal({required this.pointsLeft, required double fraction}) : super(fraction);
  final int pointsLeft;
}

class MissionGoal extends NextGoal {
  MissionGoal(this.mission) : super(mission.fraction);
  final Mission mission;
}

class LevelGoal extends NextGoal {
  const LevelGoal({required this.nextLevel, required this.xpLeft, required double fraction}) : super(fraction);
  final int nextLevel;
  final int xpLeft;
}
