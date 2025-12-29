import 'package:lifestreak/providers/habit_provider.dart';
import '../utils/scoring_logic.dart';

class HeatmapDay {
  final DateTime date;
  final int score;
  final int completedHabits;
  final int totalHabits;

  const HeatmapDay({
    required this.date,
    required this.score,
    required this.completedHabits,
    required this.totalHabits,
  });

  /// Legacy intensity getter for backwards compatibility
  int get intensity => score;
}

List<HeatmapDay> computeHeatmapDays({
  required DateTime today,
  required int days,
  required List<Habit> habits,
  required Map<String, bool> habitLogs,
}) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final startDate = todayDate.subtract(Duration(days: days - 1));

  final result = <HeatmapDay>[];

  for (int i = 0; i < days; i++) {
    final currentDate = startDate.add(Duration(days: i));
    final dateStr = _formatDate(currentDate);

    int completed = 0;
    for (final habit in habits) {
      final key = 'habit_log_${habit.id}_$dateStr';
      if (habitLogs[key] == true) {
        completed++;
      }
    }

    final totalHabits = habits.length;
    final score = calculateDailyScore(
      completedHabits: completed,
      totalHabits: totalHabits,
    );

    result.add(HeatmapDay(
      date: currentDate,
      score: score,
      completedHabits: completed,
      totalHabits: totalHabits,
    ));
  }

  return result;
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
