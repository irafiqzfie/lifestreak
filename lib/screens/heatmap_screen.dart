import 'package:flutter/material.dart';
import '../widgets/score_summary_header.dart';

class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  static const int weeks = 13; // columns
  static const int days = 7; // rows (Mon-Sun)
  static const int totalCells = 90;

  List<double> _mockPercentages() {
    // Generate 90 mock percentage values between 0.0 and 1.0
    final List<double> values = List.generate(
      totalCells,
      (i) => (i % 5) / 4.0, // cycles through 0.0,0.25,0.5,0.75,1.0
    );
    return values;
  }

  Color _colorForPercentage(double p, BuildContext context) {
    if (p <= 0.0) return Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(0xEE);
    if (p <= 0.33) return Colors.green.shade200;
    if (p <= 0.66) return Colors.green.shade400;
    if (p < 1.0) return Colors.green.shade700;
    return Colors.green.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final percentages = _mockPercentages();
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap')),
      body: Column(
        children: [
          const ScoreSummaryHeader(),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last 90 days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      final labelWidth = 48.0;
                      final gap = 6.0;
                      final availableWidth = constraints.maxWidth - labelWidth - 8.0;
                      final cellSize = (availableWidth - (weeks - 1) * gap) / weeks;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day labels column
                          SizedBox(
                            width: labelWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: List.generate(days, (r) {
                                return SizedBox(
                                  height: cellSize,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(dayLabels[r], style: Theme.of(context).textTheme.bodySmall),
                                  ),
                                );
                              }),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Grid area
                          SizedBox(
                            width: availableWidth,
                            child: Column(
                              children: List.generate(days, (r) {
                                return SizedBox(
                                  height: cellSize,
                                  child: Row(
                                    children: List.generate(weeks, (w) {
                                      final index = w * days + r;
                                      if (index >= totalCells) {
                                        return SizedBox(width: cellSize, height: cellSize);
                                      }
                                      final p = percentages[index];
                                      return Padding(
                                        padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
                                        child: Container(
                                          width: cellSize,
                                          height: cellSize,
                                          decoration: BoxDecoration(
                                            color: _colorForPercentage(p, context),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
