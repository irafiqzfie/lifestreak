// Core scoring logic for Lifestreak
//
// All scoring must use these functions to ensure consistency across the app.

/// Calculates the daily score based on habit completion ratio.
///
/// Returns:
/// - 0 if no habits exist or no habits completed
/// - 1 if less than half completed
/// - 2 if more than half completed
/// - 3 if all habits completed
int calculateDailyScore({
  required int completedHabits,
  required int totalHabits,
}) {
  if (totalHabits == 0) return 0;
  if (completedHabits == 0) return 0;

  final ratio = completedHabits / totalHabits;

  if (ratio >= 1.0) return 3;
  if (ratio > 0.5) return 2;
  return 1;
}

/// Aggregates daily scores for a given date range.
///
/// Returns the sum of all daily scores and the maximum possible score.
({int score, int maxScore}) aggregateScores(List<int> dailyScores) {
  final score = dailyScores.fold<int>(0, (sum, score) => sum + score);
  final maxScore = dailyScores.length * 3;
  return (score: score, maxScore: maxScore);
}

/// Calculates maximum possible score for a given number of days.
int maxScoreForDays(int days) => days * 3;

/// Returns the color intensity level (0-3) for a given daily score.
/// Used for heatmap visualization.
int getIntensityFromScore(int score) => score;
