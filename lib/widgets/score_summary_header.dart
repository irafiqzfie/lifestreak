import 'package:flutter/material.dart';

class ScoreSummaryHeader extends StatelessWidget {
  const ScoreSummaryHeader({super.key});

  // Mock score values
  static const int dailyScore = 3;
  static const int weeklyScore = 18;
  static const int monthlyScore = 72;
  static const int yearlyScore = 890;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreItem(label: 'Daily', value: dailyScore),
          _ScoreItem(label: 'Weekly', value: weeklyScore),
          _ScoreItem(label: 'Monthly', value: monthlyScore),
          _ScoreItem(label: 'Yearly', value: yearlyScore),
        ],
      ),
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
