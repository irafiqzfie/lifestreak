import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/habit_provider.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  SharedPreferences? _prefs;
  Map<String, double> _intensityCache = {};
  String _selectedTimeframe = 'Quarter';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _intensityCache = {}; // Force recalculation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while prefs are loading
    if (_prefs == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAF7),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3f6a4a)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF9FAF7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeframeSelector(),
                    _buildTitle(),
                    _buildDateRange(),
                    _buildHeatmap(),
                    _buildLegend(),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIconButton(Icons.arrow_back, () => Navigator.pop(context)),
            Text(
              'Your Lifestreak',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            _buildIconButton(Icons.more_horiz, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 24),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            _buildTimeframeOption('Week'),
            _buildTimeframeOption('Month'),
            _buildTimeframeOption('Quarter'),
            _buildTimeframeOption('Year'),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeOption(String label) {
    final isSelected = _selectedTimeframe == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTimeframe = label;
          _intensityCache = {}; // Clear cache when switching views
        }),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _getTitleText(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
            height: 1.2,
          ),
        ),
      ),
    );
  }

  String _getTitleText() {
    switch (_selectedTimeframe) {
      case 'Week':
        return 'Weekly Activity';
      case 'Month':
        final now = DateTime.now();
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        return '${months[now.month - 1]} Activity';
      case 'Year':
        return 'Yearly Activity';
      default:
        return 'Last 90 Days';
    }
  }

  Widget _buildDateRange() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Text(
        _getDateRangeText(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  String _getDateRangeText() {
    final now = DateTime.now();
    DateTime start;

    switch (_selectedTimeframe) {
      case 'Week':
        start = now.subtract(const Duration(days: 7));
        break;
      case 'Month':
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        return '${months[now.month - 1]} 1 - ${months[now.month - 1]} $daysInMonth';
      case 'Year':
        return 'Jan 1 - Dec 31';
      default:
        start = now.subtract(const Duration(days: 90));
    }

    return '${_formatDate(start)} - ${_formatDate(now)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildHeatmap() {
    if (_selectedTimeframe == 'Week') {
      return _buildWeeklyBars();
    }

    if (_selectedTimeframe == 'Month') {
      return _buildMonthlyCalendar();
    }

    if (_selectedTimeframe == 'Year') {
      return _buildYearlyHeatmap();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildMonthLabels(),
          const SizedBox(height: 8),
          _buildHeatmapGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day labels
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday - 1 + daysInMonth,
            itemBuilder: (context, index) {
              // Empty cells before the 1st
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }

              final day = index - firstWeekday + 2;
              final intensity = _getMonthDayIntensity(day);

              return Container(
                decoration: BoxDecoration(
                  color: _getColorForIntensity(intensity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: intensity == 0.0
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0a160f),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _getMonthDayIntensity(int day) {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, day);

    // Only calculate intensity for valid dates in current month
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (day < 1 || day > daysInMonth) return 0.0;

    // Don't calculate for future dates
    if (date.isAfter(now)) return 0.0;

    return _calculateIntensityForDate(date);
  }

  Widget _buildWeeklyBars() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dates = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(7, (index) {
              final date = dates[index];
              final isToday =
                  date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;
              final intensity = _getBarIntensity(index);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == 6 ? 0 : 6,
                  ),
                  child: Column(
                    children: [
                      Text(
                        days[index],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: _getColorForIntensity(intensity),
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(
                                  color: const Color(0xFF3f6a4a),
                                  width: 2,
                                )
                              : null,
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3f6a4a,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? const Color(0xFF3f6a4a)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  double _getBarIntensity(int dayIndex) {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - dayIndex));
    return _calculateIntensityForDate(date);
  }

  Widget _buildMonthLabels() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Calculate which months to show based on 90 days back
    final start = now.subtract(const Duration(days: 90));
    final month1 = months[start.month - 1];
    final month2 = months[(start.month % 12)];
    final month3 = months[now.month - 1];

    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            month1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          Text(
            month2,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          Text(
            month3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final days = _getDaysCount();

    const rows = 7;
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final weeks = (days / rows).ceil();
        final totalGaps = (weeks - 1) * gap;
        final cellSize =
            (constraints.maxWidth - totalGaps - 32 - 8) /
            weeks; // subtract day labels width + spacer
        final gridHeight = rows * cellSize + (rows - 1) * gap;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: gridHeight, width: 32, child: _buildDayLabels()),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: gridHeight,
                child: Column(
                  children: List.generate(rows, (row) {
                    return Padding(
                      padding: EdgeInsets.only(top: row == 0 ? 0 : gap),
                      child: Row(
                        children: List.generate(weeks, (col) {
                          final cellIndex = col * rows + row;
                          return Padding(
                            padding: EdgeInsets.only(left: col == 0 ? 0 : gap),
                            child: SizedBox(
                              width: cellSize,
                              height: cellSize,
                              child: _buildHeatmapCellManual(cellIndex, days),
                            ),
                          );
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearlyHeatmap() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // First half: Jan - Jun
          _buildYearlyHeatmapSection(
            months: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
            startDay: 0,
            totalDays: 181, // Approximate first half of year
          ),
          const SizedBox(height: 32),
          // Second half: Jul - Dec
          _buildYearlyHeatmapSection(
            months: ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
            startDay: 181,
            totalDays: 184, // Approximate second half of year
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyHeatmapSection({
    required List<String> months,
    required int startDay,
    required int totalDays,
  }) {
    const rows = 7;
    const gap = 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final weeks = (totalDays / rows).ceil();
        final totalGaps = (weeks - 1) * gap;
        final cellSize = (constraints.maxWidth - totalGaps - 32 - 8) / weeks;
        final gridHeight = rows * cellSize + (rows - 1) * gap;

        return Column(
          children: [
            // Month labels
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: months.map((month) {
                  return SizedBox(
                    width: 32,
                    child: Text(
                      month,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Heatmap grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: gridHeight,
                  width: 32,
                  child: _buildDayLabels(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: gridHeight,
                    child: Column(
                      children: List.generate(rows, (row) {
                        return Padding(
                          padding: EdgeInsets.only(top: row == 0 ? 0 : gap),
                          child: Row(
                            children: List.generate(weeks, (col) {
                              final cellIndex = col * rows + row;
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: col == 0 ? 0 : gap,
                                ),
                                child: SizedBox(
                                  width: cellSize,
                                  height: cellSize,
                                  child: _buildYearlyHeatmapCell(
                                    startDay + cellIndex,
                                    365,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearlyHeatmapCell(int index, int totalDays) {
    if (index >= totalDays) {
      return const SizedBox();
    }

    final now = DateTime.now();
    final daysBack = totalDays - 1 - index;
    final date = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysBack));
    final intensity = _calculateIntensityForDate(date);

    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);
    final isToday = dateOnly.isAtSameMomentAs(todayOnly);

    return Container(
      decoration: BoxDecoration(
        color: _getColorForIntensity(intensity),
        borderRadius: BorderRadius.circular(2),
        border: isToday
            ? Border.all(color: const Color(0xFF3f6a4a), width: 2)
            : null,
      ),
    );
  }

  int _getDaysCount() {
    switch (_selectedTimeframe) {
      case 'Week':
        return 7;
      case 'Month':
        return 30;
      case 'Year':
        return 365;
      default:
        return 90;
    }
  }

  Widget _buildDayLabels() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mon',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          'Wed',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          'Fri',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          'Sun',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapCellManual(
    int index,
    int totalDays, {
    double? overrideIntensity,
  }) {
    // For Quarter/Year views, calculate date directly
    if (_selectedTimeframe == 'Quarter' || _selectedTimeframe == 'Year') {
      if (index >= totalDays) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
        );
      }

      final now = DateTime.now();
      final daysBack = totalDays - 1 - index;
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysBack));
      final intensity = _calculateIntensityForDate(date);

      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      final isToday = dateOnly.isAtSameMomentAs(todayOnly);

      return Container(
        decoration: BoxDecoration(
          color: _getColorForIntensity(intensity),
          borderRadius: BorderRadius.circular(4),
          border: isToday
              ? Border.all(color: const Color(0xFF3f6a4a), width: 2)
              : null,
        ),
      );
    }

    // Original logic for other views
    final intensity =
        overrideIntensity ??
        (index >= totalDays ? -1 : _getCellIntensity(index, totalDays));

    return Container(
      decoration: BoxDecoration(
        color: _getColorForIntensity(intensity),
        borderRadius: BorderRadius.circular(4),
        border: intensity == -1
            ? Border.all(color: const Color(0xFFCBD5E1), width: 1)
            : intensity == -2
            ? Border.all(color: const Color(0xFF3f6a4a), width: 2)
            : null,
      ),
    );
  }

  double _getCellIntensity(int index, int totalDays) {
    final date = _getDateForIndex(index);
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Future cells
    if (dateOnly.isAfter(todayOnly)) {
      return -1; // Future
    }

    // Today cell (highlighted)
    if (dateOnly.isAtSameMomentAs(todayOnly)) {
      return -2; // Today
    }

    // Check cache
    final dateKey = _formatDateKey(date);
    if (_intensityCache.containsKey(dateKey)) {
      return _intensityCache[dateKey]!;
    }

    // Calculate intensity from real data
    final intensity = _calculateIntensityForDate(date);
    _intensityCache[dateKey] = intensity;
    return intensity;
  }

  DateTime _getDateForIndex(int index) {
    final now = DateTime.now();
    int daysToSubtract;

    switch (_selectedTimeframe) {
      case 'Week':
        daysToSubtract = 6 - index; // 0 = 6 days ago, 6 = today
        break;
      case 'Month':
        daysToSubtract = 29 - index;
        break;
      case 'Year':
        daysToSubtract = 364 - index;
        break;
      default: // Quarter
        daysToSubtract = 89 - index;
    }

    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double _calculateIntensityForDate(DateTime date) {
    if (_prefs == null) return 0.0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0.0;

    final dateKey = _formatDateKey(date);
    int completedCount = 0;

    // Count completed habits for this date
    for (final habit in habits) {
      final logKey = 'habit_log_${habit.id}_$dateKey';
      if (_prefs!.getBool(logKey) == true) {
        completedCount++;
      }
    }

    // Intensity = completed / total (PRD formula)
    return habits.isEmpty ? 0.0 : completedCount / habits.length;
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == -1) return Colors.transparent; // Future cell
    if (intensity == -2) return Colors.transparent; // Today cell
    if (intensity == 0.0) return const Color(0xFFF1F5F9);

    // Muted forest green scale - consistent with app-wide design
    // Base: #3f6a4a (muted forest green from sign-in screen)
    const baseGreen = Color(0xFF3f6a4a);

    if (intensity < 0.25) {
      return baseGreen.withOpacity(0.2);
    } else if (intensity < 0.5) {
      return baseGreen.withOpacity(0.4);
    } else if (intensity < 0.75) {
      return baseGreen.withOpacity(0.6);
    } else if (intensity < 1.0) {
      return baseGreen.withOpacity(0.8);
    } else {
      return baseGreen; // Perfect day - solid but not glowing
    }
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Less',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          _buildLegendBox(const Color(0xFFF1F5F9)),
          const SizedBox(width: 4),
          _buildLegendBox(const Color(0xFF3f6a4a).withOpacity(0.3)),
          const SizedBox(width: 4),
          _buildLegendBox(const Color(0xFF3f6a4a).withOpacity(0.6)),
          const SizedBox(width: 4),
          _buildLegendBox(const Color(0xFF3f6a4a)),
          const SizedBox(width: 8),
          Text(
            'More',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildStatsCards() {
    const targetCardWidth = 120.0;
    const gap = 28.0;
    const targetGroupWidth = targetCardWidth * 3 + gap * 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep the row centered as a single unit, but ensure there is always
          // breathing room from screen edges.
          final available = math.max(0.0, constraints.maxWidth - 32);
          final groupWidth = math.min(targetGroupWidth, available);

          // If we have to shrink, shrink the card widths equally (still fixed
          // and identical within the row).
          final cardWidth = (groupWidth - gap * 2) / 3;

          return Center(
            child: SizedBox(
              width: groupWidth,
              child: Row(
                children: [
                  SizedBox(width: cardWidth, child: _buildStreakCard()),
                  const SizedBox(width: gap),
                  SizedBox(width: cardWidth, child: _buildConsistencyCard()),
                  const SizedBox(width: gap),
                  SizedBox(
                    width: cardWidth,
                    child: _buildPerfectDaysCard(count: ''),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard() {
    final streakDays = _calculateCurrentStreak();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                streakDays.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.local_fire_department,
                  color: const Color(0xFFEA580C),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current Streak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  int _calculateCurrentStreak() {
    if (_prefs == null) return 0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0;

    final today = DateTime.now();
    int streak = 0;

    // Check backwards from today
    for (int i = 0; i < 365; i++) {
      final checkDate = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final dateKey = _formatDateKey(checkDate);
      int completedCount = 0;

      for (final habit in habits) {
        final logKey = 'habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      // Active day = at least 1 habit completed (PRD)
      if (completedCount >= 1) {
        streak++;
      } else {
        break; // Streak broken
      }
    }

    return streak;
  }

  Widget _buildConsistencyCard() {
    final consistency = _calculateConsistency();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${consistency.toStringAsFixed(0)}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.donut_large,
                  color: const Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Consistency',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  double _calculateConsistency() {
    if (_prefs == null) return 0.0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0.0;

    final today = DateTime.now();
    final windowDays = 90; // Rolling 90 days (PRD)
    int activeDays = 0;

    for (int i = 0; i < windowDays; i++) {
      final checkDate = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final dateKey = _formatDateKey(checkDate);
      int completedCount = 0;

      for (final habit in habits) {
        final logKey = 'habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      // Active day = at least 1 habit completed
      if (completedCount >= 1) {
        activeDays++;
      }
    }

    return (activeDays / windowDays) * 100;
  }

  Widget _buildPerfectDaysCard({required String count}) {
    final perfectDays = _calculatePerfectDays();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                perfectDays.toString(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.verified,
                  color: const Color(0xFF3f6a4a),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Perfect Days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  int _calculatePerfectDays() {
    if (_prefs == null) return 0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0;

    final today = DateTime.now();
    int daysToCheck;

    switch (_selectedTimeframe) {
      case 'Week':
        daysToCheck = 7;
        break;
      case 'Month':
        daysToCheck = 30;
        break;
      case 'Year':
        daysToCheck = 365;
        break;
      default: // Quarter
        daysToCheck = 90;
    }

    int perfectCount = 0;

    for (int i = 0; i < daysToCheck; i++) {
      final checkDate = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final dateKey = _formatDateKey(checkDate);
      int completedCount = 0;

      for (final habit in habits) {
        final logKey = 'habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      // Perfect Day = completed ALL habits (PRD formula)
      if (completedCount == habits.length && habits.isNotEmpty) {
        perfectCount++;
      }
    }

    return perfectCount;
  }
}
