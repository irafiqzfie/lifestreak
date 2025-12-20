import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifestreak/screens/habit_logger_screen.dart';

void main() {
  group('HabitLoggerScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders empty state message when no habits', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HabitLoggerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No habits yet. Tap + to create one.'), findsOneWidget);
    });

    testWidgets('renders habit list when habits exist', (tester) async {
      SharedPreferences.setMockInitialValues({
        'habit_list': '[{"id":"h1","name":"Morning stretch"}]',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HabitLoggerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Morning stretch'), findsOneWidget);
      expect(find.text('No habits yet. Tap + to create one.'), findsNothing);
    });

    testWidgets('displays FloatingActionButton', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HabitLoggerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders without crash when habit list has items', (tester) async {
      SharedPreferences.setMockInitialValues({
        'habit_list': '[{"id":"h1","name":"Habit 1"},{"id":"h2","name":"Habit 2"}]',
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HabitLoggerScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Habit 1'), findsOneWidget);
      expect(find.text('Habit 2'), findsOneWidget);
    });
  });
}
