import 'package:flutter_test/flutter_test.dart';
import 'package:lifestreak/utils/scoring_logic.dart';

void main() {
  group('calculateDailyScore', () {
    test('returns 0 when no habits exist', () {
      expect(
        calculateDailyScore(completedHabits: 0, totalHabits: 0),
        equals(0),
      );
    });

    test('returns 0 when no habits completed', () {
      expect(
        calculateDailyScore(completedHabits: 0, totalHabits: 5),
        equals(0),
      );
    });

    test('returns 3 when all habits completed', () {
      expect(
        calculateDailyScore(completedHabits: 5, totalHabits: 5),
        equals(3),
      );
      expect(
        calculateDailyScore(completedHabits: 1, totalHabits: 1),
        equals(3),
      );
      expect(
        calculateDailyScore(completedHabits: 10, totalHabits: 10),
        equals(3),
      );
    });

    test('returns 2 when more than half completed', () {
      // 3/5 = 0.6 > 0.5
      expect(
        calculateDailyScore(completedHabits: 3, totalHabits: 5),
        equals(2),
      );
      // 4/5 = 0.8 > 0.5
      expect(
        calculateDailyScore(completedHabits: 4, totalHabits: 5),
        equals(2),
      );
      // 6/10 = 0.6 > 0.5
      expect(
        calculateDailyScore(completedHabits: 6, totalHabits: 10),
        equals(2),
      );
    });

    test('returns 1 when less than half completed', () {
      // 1/5 = 0.2 < 0.5
      expect(
        calculateDailyScore(completedHabits: 1, totalHabits: 5),
        equals(1),
      );
      // 2/5 = 0.4 < 0.5
      expect(
        calculateDailyScore(completedHabits: 2, totalHabits: 5),
        equals(1),
      );
      // 4/10 = 0.4 < 0.5
      expect(
        calculateDailyScore(completedHabits: 4, totalHabits: 10),
        equals(1),
      );
    });

    test('returns 1 when exactly half completed', () {
      // 5/10 = 0.5 (not > 0.5)
      expect(
        calculateDailyScore(completedHabits: 5, totalHabits: 10),
        equals(1),
      );
      // 1/2 = 0.5
      expect(
        calculateDailyScore(completedHabits: 1, totalHabits: 2),
        equals(1),
      );
    });

    test('is deterministic', () {
      for (int i = 0; i < 100; i++) {
        expect(
          calculateDailyScore(completedHabits: 3, totalHabits: 5),
          equals(2),
        );
      }
    });
  });

  group('aggregateScores', () {
    test('returns 0/0 for empty list', () {
      final result = aggregateScores([]);
      expect(result.score, equals(0));
      expect(result.maxScore, equals(0));
    });

    test('correctly sums daily scores', () {
      final result = aggregateScores([3, 2, 1, 0, 3, 2, 1]);
      expect(result.score, equals(12));
      expect(result.maxScore, equals(21)); // 7 days × 3
    });

    test('calculates max score for week', () {
      final result = aggregateScores([3, 3, 3, 3, 3, 3, 3]);
      expect(result.score, equals(21));
      expect(result.maxScore, equals(21));
    });

    test('calculates max score for month', () {
      final monthScores = List.filled(30, 3);
      final result = aggregateScores(monthScores);
      expect(result.score, equals(90));
      expect(result.maxScore, equals(90)); // 30 days × 3
    });

    test('handles mixed scores', () {
      final result = aggregateScores([0, 0, 1, 1, 2, 2, 3]);
      expect(result.score, equals(9));
      expect(result.maxScore, equals(21));
    });
  });

  group('maxScoreForDays', () {
    test('calculates correctly', () {
      expect(maxScoreForDays(7), equals(21));
      expect(maxScoreForDays(30), equals(90));
      expect(maxScoreForDays(90), equals(270));
      expect(maxScoreForDays(365), equals(1095));
    });

    test('returns 0 for 0 days', () {
      expect(maxScoreForDays(0), equals(0));
    });
  });

  group('getIntensityFromScore', () {
    test('maps scores to intensity correctly', () {
      expect(getIntensityFromScore(0), equals(0));
      expect(getIntensityFromScore(1), equals(1));
      expect(getIntensityFromScore(2), equals(2));
      expect(getIntensityFromScore(3), equals(3));
    });
  });

  group('scoring consistency', () {
    test('score never exceeds 3', () {
      for (int total = 1; total <= 20; total++) {
        for (int completed = 0; completed <= total; completed++) {
          final score = calculateDailyScore(
            completedHabits: completed,
            totalHabits: total,
          );
          expect(score, lessThanOrEqualTo(3));
          expect(score, greaterThanOrEqualTo(0));
        }
      }
    });

    test('score always between 0 and 3', () {
      final testCases = [
        (0, 0),
        (0, 1),
        (1, 1),
        (1, 10),
        (5, 10),
        (6, 10),
        (10, 10),
        (50, 100),
        (99, 100),
        (100, 100),
      ];

      for (final (completed, total) in testCases) {
        final score = calculateDailyScore(
          completedHabits: completed,
          totalHabits: total,
        );
        expect(score, greaterThanOrEqualTo(0), reason: 'Score $score < 0');
        expect(score, lessThanOrEqualTo(3), reason: 'Score $score > 3');
      }
    });
  });
}
