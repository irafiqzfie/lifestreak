import 'package:flutter_test/flutter_test.dart';
import 'package:lifestreak/providers/habit_provider.dart';
import 'package:lifestreak/logic/heatmap_logic.dart';

void main() {
  group('computeHeatmapDays', () {
    test('generates exactly 90 days', () {
      final today = DateTime(2025, 12, 20);
      final habits = [const Habit(id: 'h1', name: 'Habit 1')];
      final logs = <String, bool>{};

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      expect(result.length, 90);
    });

    test('last day equals today (date only, no time)', () {
      final today = DateTime(2025, 12, 20, 14, 30, 45);
      final habits = [const Habit(id: 'h1', name: 'Habit 1')];
      final logs = <String, bool>{};

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      final lastDay = result.last;
      expect(lastDay.date.year, 2025);
      expect(lastDay.date.month, 12);
      expect(lastDay.date.day, 20);
      expect(lastDay.date.hour, 0);
      expect(lastDay.date.minute, 0);
      expect(lastDay.date.second, 0);
    });

    test('days with no completions have intensity 0', () {
      final today = DateTime(2025, 12, 20);
      final habits = [
        const Habit(id: 'h1', name: 'Habit 1'),
        const Habit(id: 'h2', name: 'Habit 2'),
      ];
      final logs = <String, bool>{};

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      for (final day in result) {
        expect(day.intensity, 0);
      }
    });

    test('one habit completed has score 3 (all habits done)', () {
      final today = DateTime(2025, 12, 20);
      final habits = [const Habit(id: 'h1', name: 'Habit 1')];
      final logs = <String, bool>{'habit_log_h1_2025-12-20': true};

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      final todayResult = result.last;
      expect(todayResult.score, 3); // 1/1 = 100% = score 3
      expect(todayResult.completedHabits, 1);
      expect(todayResult.totalHabits, 1);
    });

    test('multiple habits same day with intensity capped at 3', () {
      final today = DateTime(2025, 12, 20);
      final habits = [
        const Habit(id: 'h1', name: 'Habit 1'),
        const Habit(id: 'h2', name: 'Habit 2'),
        const Habit(id: 'h3', name: 'Habit 3'),
        const Habit(id: 'h4', name: 'Habit 4'),
        const Habit(id: 'h5', name: 'Habit 5'),
      ];
      final logs = <String, bool>{
        'habit_log_h1_2025-12-20': true,
        'habit_log_h2_2025-12-20': true,
        'habit_log_h3_2025-12-20': true,
        'habit_log_h4_2025-12-20': true,
        'habit_log_h5_2025-12-20': true,
      };

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      final todayResult = result.last;
      expect(todayResult.intensity, 3);
    });

    test('habits completed outside range are ignored', () {
      final today = DateTime(2025, 12, 20);
      final habits = [const Habit(id: 'h1', name: 'Habit 1')];
      final logs = <String, bool>{
        'habit_log_h1_2025-09-20': true,
        'habit_log_h1_2025-09-19': true,
      };

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      for (final day in result) {
        expect(day.intensity, 0);
      }
    });

    test('missing days in logs do not break ordering', () {
      final today = DateTime(2025, 12, 20);
      final habits = [const Habit(id: 'h1', name: 'Habit 1')];
      final logs = <String, bool>{
        'habit_log_h1_2025-12-15': true,
        'habit_log_h1_2025-12-10': true,
      };

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      expect(result.length, 90);
      expect(result.first.date.isBefore(result.last.date), true);

      for (int i = 0; i < result.length - 1; i++) {
        final current = result[i].date;
        final next = result[i + 1].date;
        expect(next.difference(current).inDays, 1);
      }
    });

    test('empty habits list produces all zeros', () {
      final today = DateTime(2025, 12, 20);
      final habits = <Habit>[];
      final logs = <String, bool>{};

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      expect(result.length, 90);
      for (final day in result) {
        expect(day.intensity, 0);
      }
    });

    test('two habits same day has score 3 (all habits done)', () {
      final today = DateTime(2025, 12, 20);
      final habits = [
        const Habit(id: 'h1', name: 'Habit 1'),
        const Habit(id: 'h2', name: 'Habit 2'),
      ];
      final logs = <String, bool>{
        'habit_log_h1_2025-12-20': true,
        'habit_log_h2_2025-12-20': true,
      };

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      final todayResult = result.last;
      expect(todayResult.score, 3); // 2/2 = 100% = score 3
      expect(todayResult.completedHabits, 2);
      expect(todayResult.totalHabits, 2);
    });

    test('first day equals today minus 89 days', () {
      final today = DateTime(2025, 12, 20);
      final habits = [const Habit(id: 'h1', name: 'Habit 1')];
      final logs = <String, bool>{};

      final result = computeHeatmapDays(
        today: today,
        days: 90,
        habits: habits,
        habitLogs: logs,
      );

      final expectedFirst = DateTime(2025, 9, 22);
      expect(result.first.date.year, expectedFirst.year);
      expect(result.first.date.month, expectedFirst.month);
      expect(result.first.date.day, expectedFirst.day);
    });

    test(
      'completions on various days within range have correct scores',
      () {
        final today = DateTime(2025, 12, 20);
        final habits = [
          const Habit(id: 'h1', name: 'Habit 1'),
          const Habit(id: 'h2', name: 'Habit 2'),
          const Habit(id: 'h3', name: 'Habit 3'),
        ];
        final logs = <String, bool>{
          'habit_log_h1_2025-12-15': true,
          'habit_log_h2_2025-12-15': true,
          'habit_log_h1_2025-10-01': true,
          'habit_log_h1_2025-11-20': true,
          'habit_log_h2_2025-11-20': true,
          'habit_log_h3_2025-11-20': true,
        };

        final result = computeHeatmapDays(
          today: today,
          days: 90,
          habits: habits,
          habitLogs: logs,
        );

        final dec15 = result.firstWhere(
          (d) => d.date.month == 12 && d.date.day == 15,
        );
        expect(dec15.score, 2); // 2/3 = 66% > 50% = score 2
        expect(dec15.completedHabits, 2);
        expect(dec15.totalHabits, 3);

        final oct1 = result.firstWhere(
          (d) => d.date.month == 10 && d.date.day == 1,
        );
        expect(oct1.score, 1); // 1/3 = 33% < 50% = score 1
        expect(oct1.completedHabits, 1);
        expect(oct1.totalHabits, 3);

        final nov20 = result.firstWhere(
          (d) => d.date.month == 11 && d.date.day == 20,
        );
        expect(nov20.score, 3); // 3/3 = 100% = score 3
        expect(nov20.completedHabits, 3);
        expect(nov20.totalHabits, 3);
      },
    );
  });
}
