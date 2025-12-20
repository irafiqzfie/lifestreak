import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifestreak/providers/habit_provider.dart';

void main() {
  group('HabitListNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('addHabit creates habit with timestamp ID and correct name', () async {
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.addHabit('Morning run');

      expect(notifier.state.length, 1);
      expect(notifier.state[0].name, 'Morning run');
      expect(notifier.state[0].id, startsWith('h_'));
    });

    test('addHabit appends habit to state list', () async {
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.addHabit('First habit');
      notifier.addHabit('Second habit');

      expect(notifier.state.length, 2);
      expect(notifier.state[0].name, 'First habit');
      expect(notifier.state[1].name, 'Second habit');
    });

    test('addHabit persists habit_list to SharedPreferences as JSON', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.addHabit('Test habit');
      await Future.delayed(const Duration(milliseconds: 50));

      final stored = prefs.getString('habit_list');
      expect(stored, isNotNull);
      expect(stored, contains('Test habit'));
      expect(stored, contains('"name":"Test habit"'));
    });

    test('toggle flips completion state for matching habit ID', () async {
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.addHabit('Test habit');
      final habitId = notifier.state[0].id;
      expect(notifier.state[0].completed, false);

      notifier.toggle(habitId);

      expect(notifier.state[0].completed, true);

      notifier.toggle(habitId);

      expect(notifier.state[0].completed, false);
    });

    test('toggle persists true to habit_log key when completing', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.addHabit('Test habit');
      final habitId = notifier.state[0].id;
      final today = _getTodayString();

      notifier.toggle(habitId);
      await Future.delayed(const Duration(milliseconds: 10));

      final key = 'habit_log_${habitId}_$today';
      expect(prefs.getBool(key), true);
    });

    test('toggle removes habit_log key when uncompleting', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      notifier.addHabit('Test habit');
      final habitId = notifier.state[0].id;
      final today = _getTodayString();

      notifier.toggle(habitId);
      await Future.delayed(const Duration(milliseconds: 10));

      final key = 'habit_log_${habitId}_$today';
      expect(prefs.getBool(key), true);

      notifier.toggle(habitId);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(prefs.getBool(key), isNull);
    });

    test('_initialize loads empty list when habit_list key absent', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state, isEmpty);
    });

    test('_initialize loads habit_list JSON and creates Habit objects', () async {
      SharedPreferences.setMockInitialValues({
        'habit_list': '[{"id":"h1","name":"Morning stretch"}]',
      });
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.length, 1);
      expect(notifier.state[0].id, 'h1');
      expect(notifier.state[0].name, 'Morning stretch');
      expect(notifier.state[0].completed, false);
    });

    test('_initialize merges today\'s completions from habit_log keys', () async {
      final today = _getTodayString();
      SharedPreferences.setMockInitialValues({
        'habit_list': '[{"id":"h1","name":"Morning stretch"}]',
        'habit_log_h1_$today': true,
      });
      final notifier = HabitListNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.length, 1);
      expect(notifier.state[0].completed, true);
    });
  });
}

String _getTodayString() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
