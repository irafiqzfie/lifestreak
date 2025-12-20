import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifestreak/screens/heatmap_screen.dart';

void main() {
  group('HeatmapScreen', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HeatmapScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HeatmapScreen), findsOneWidget);
      expect(find.text('Heatmap'), findsOneWidget);
    });
  });
}
