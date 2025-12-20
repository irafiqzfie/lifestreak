import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifestreak/widgets/score_summary_header.dart';

void main() {
  group('ScoreSummaryHeader', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ScoreSummaryHeader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScoreSummaryHeader), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
    });
  });
}
