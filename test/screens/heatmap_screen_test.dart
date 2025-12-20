import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lifestreak/screens/heatmap_screen.dart';

void main() {
  group('HeatmapScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders without crash', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HeatmapScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(HeatmapScreen), findsOneWidget);
      expect(find.text('Heatmap'), findsOneWidget);
    });
  });
}
