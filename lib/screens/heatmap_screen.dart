import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/score_summary_header.dart';
import '../logic/heatmap_logic.dart';
import '../providers/habit_provider.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  List<HeatmapDay>? _heatmapDays;

  static const int weeks = 13;
  static const int days = 7;
  static const int totalCells = 90;

  @override
  void initState() {
    super.initState();
    _loadHeatmapData();
  }

  Future<void> _loadHeatmapData() async {
    final prefs = await SharedPreferences.getInstance();
    final habitLogs = <String, bool>{};
    
    for (final key in prefs.getKeys()) {
      if (key.startsWith('habit_log_')) {
        final value = prefs.getBool(key);
        if (value != null) {
          habitLogs[key] = value;
        }
      }
    }

    final habits = ref.read(habitListProvider);
    final result = computeHeatmapDays(
      today: DateTime.now(),
      days: 90,
      habits: habits,
      habitLogs: habitLogs,
    );

    if (mounted) {
      setState(() {
        _heatmapDays = result;
      });
    }
  }

  Future<void> _toggleToday(DateTime cellDate) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _formatDate(cellDate);
    final habits = ref.read(habitListProvider);
    
    bool hasAnyCompleted = false;
    for (final habit in habits) {
      final key = 'habit_log_${habit.id}_$dateStr';
      if (prefs.getBool(key) == true) {
        hasAnyCompleted = true;
        break;
      }
    }
    
    for (final habit in habits) {
      final key = 'habit_log_${habit.id}_$dateStr';
      if (hasAnyCompleted) {
        await prefs.remove(key);
      } else {
        await prefs.setBool(key, true);
      }
    }
    
    await _loadHeatmapData();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Color _colorForIntensity(int intensity, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (intensity == 0) {
      return isDark
          ? Colors.grey.shade800
          : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(0xEE);
    }
    if (intensity == 1) {
      return isDark ? Colors.green.shade800 : Colors.green.shade200;
    }
    if (intensity == 2) {
      return isDark ? Colors.green.shade600 : Colors.green.shade400;
    }
    return isDark ? Colors.green.shade400 : Colors.green.shade700;
  }

  Widget _buildMobileTransposedGrid(BoxConstraints constraints, List<HeatmapDay> heatmapDays, List<String> dayLabels) {
    final padding = 32.0; // left+right
    final gap = 6.0;
    final cellWidth = (constraints.maxWidth - padding - (7 - 1) * gap) / 7;
    final cellSize = cellWidth < 44.0 ? 44.0 : cellWidth;

    final weeksList = <List<HeatmapDay>>[];
    for (int i = 0; i < totalCells; i += 7) {
      final end = (i + 7 <= totalCells) ? i + 7 : totalCells;
      weeksList.add(heatmapDays.sublist(i, end));
    }
    final displayWeeks = weeksList.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: cellSize,
          child: Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(dayLabels[i], style: Theme.of(context).textTheme.bodySmall),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: displayWeeks.length,
            itemBuilder: (ctx, wi) {
              final week = displayWeeks[wi];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: List.generate(7, (d) {
                    if (d >= week.length) {
                      return SizedBox(width: cellSize, height: cellSize);
                    }
                    final day = week[d];
                    final intensity = day.intensity;
                    final isToday = _isToday(day.date);
                    final cell = Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(right: d == 6 ? 0 : gap),
                      decoration: BoxDecoration(
                        color: _colorForIntensity(intensity, context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                    return isToday
                        ? GestureDetector(onTap: () => _toggleToday(day.date), child: cell)
                        : cell;
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHorizontalGrid(BoxConstraints constraints, List<HeatmapDay> heatmapDays, List<String> dayLabels) {
    final labelWidth = 48.0;
    final gap = 6.0;
    final availableWidth = constraints.maxWidth - labelWidth - 8.0;
    final cellSize = (availableWidth - (weeks - 1) * gap) / weeks;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    final day = heatmapDays[index];
                    final intensity = day.intensity;
                    final isToday = _isToday(day.date);

                    final cell = Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: _colorForIntensity(intensity, context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );

                    return Padding(
                      padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
                      child: isToday
                          ? GestureDetector(onTap: () => _toggleToday(day.date), child: cell)
                          : cell,
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final heatmapDays = _heatmapDays;
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    if (heatmapDays == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Heatmap')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                      final isMobile = constraints.maxWidth < 600;
                      return isMobile
                          ? _buildMobileTransposedGrid(constraints, heatmapDays, dayLabels)
                          : _buildDesktopHorizontalGrid(constraints, heatmapDays, dayLabels);
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
