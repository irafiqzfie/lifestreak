import 'package:lifestreak/providers/habit_provider.dart';

class HeatmapDay {
  final DateTime date;
  final int intensity;

  const HeatmapDay({required this.date, required this.intensity});
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
    
    final intensity = completed > 3 ? 3 : completed;
    result.add(HeatmapDay(date: currentDate, intensity: intensity));
  }
  
  return result;
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
