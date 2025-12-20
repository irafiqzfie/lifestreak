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

  Future<void> _backfillDay(DateTime cellDate) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark day as completed?'),
        content: Text('Toggle completion for ${_formatDate(cellDate)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  int _calculateCurrentStreak(List<HeatmapDay> heatmapDays) {
    final sortedDays = heatmapDays.toList()..sort((a, b) => b.date.compareTo(a.date));
    int streak = 0;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    
    for (final day in sortedDays) {
      final dayNormalized = DateTime(day.date.year, day.date.month, day.date.day);
      final expectedDate = todayNormalized.subtract(Duration(days: streak));
      
      if (dayNormalized.isAtSameMomentAs(expectedDate)) {
        if (day.intensity > 0) {
          streak++;
        } else {
          break;
        }
      }
    }
    
    return streak;
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
                        : GestureDetector(onLongPress: () => _backfillDay(day.date), child: cell);
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

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
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
                            : GestureDetector(onLongPress: () => _backfillDay(day.date), child: cell),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    ),
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

    final todayData = heatmapDays.firstWhere(
      (day) => _isToday(day.date),
      orElse: () => HeatmapDay(date: DateTime.now(), intensity: 0),
    );
    final habits = ref.watch(habitListProvider);
    final completedCount = todayData.intensity > 0 ? todayData.intensity : 0;
    final currentStreak = _calculateCurrentStreak(heatmapDays);

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
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Today',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$completedCount / ${habits.length}',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Streak',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$currentStreak',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: currentStreak > 0 ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _colorForIntensity(todayData.intensity, context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                completedCount == habits.length && habits.isNotEmpty
                                    ? 'Perfect!'
                                    : completedCount > 0
                                        ? 'In Progress'
                                        : 'Not Started',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: todayData.intensity >= 2
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
