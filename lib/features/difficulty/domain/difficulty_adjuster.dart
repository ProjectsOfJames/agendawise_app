import 'challenge_attempt.dart';

const minDifficulty = 1;
const maxDifficulty = 5;

/// The adaptive difficulty rule.
///
/// Looks at the most recent attempts of one challenge type (newest first, at
/// most [window]). With at least [minimumAttempts]:
/// - 40% or more failures, or a latest time over 150% of the historical
///   average, lowers the level by one;
/// - no failures and a recent average below 70% of the historical average
///   raises it by one.
/// The level stays between 1 and 5.
class DifficultyAdjuster {
  const DifficultyAdjuster({this.window = 10, this.minimumAttempts = 3});

  final int window;
  final int minimumAttempts;

  int adjust({
    required int current,
    required List<ChallengeAttempt> recentNewestFirst,
    required Duration historicalAverage,
  }) {
    final level = current.clamp(minDifficulty, maxDifficulty);
    final attempts = recentNewestFirst.take(window).toList();
    if (attempts.length < minimumAttempts) return level;

    final averageAllMs = historicalAverage.inMilliseconds;
    final failures = attempts.where((a) => !a.success).length;
    final failRate = failures / attempts.length;
    final recentAverageMs = attempts
            .map((a) => a.duration.inMilliseconds)
            .reduce((a, b) => a + b) /
        attempts.length;
    final latestMs = attempts.first.duration.inMilliseconds;

    if (failRate >= 0.4 || (averageAllMs > 0 && latestMs > 1.5 * averageAllMs)) {
      return (level - 1).clamp(minDifficulty, maxDifficulty);
    }
    if (failures == 0 && recentAverageMs < 0.7 * averageAllMs) {
      return (level + 1).clamp(minDifficulty, maxDifficulty);
    }
    return level;
  }
}
