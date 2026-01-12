import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/habit_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/app_colors.dart';
import '../utils/scoring_logic.dart';

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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3f6a4a)),
        ),
      );
    }

    return Column(
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
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground
            : Colors.white.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : const Color(0xFFE2E8F0),
            width: 0,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Your Lifestreak',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
        child: Icon(
          icon,
          color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : const Color(0xFFF1F5F9),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedTimeframe == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTimeframe = label;
          _intensityCache = {}; // Clear cache when switching views
        }),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCard : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                    ? (isDark ? AppColors.textPrimary : const Color(0xFF0F172A))
                    : (isDark ? AppColors.textMuted : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aggregated = _calculateAggregatedScore();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _getTitleText(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          Text(
            'Score: ${aggregated.score}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3f6a4a),
            ),
          ),
        ],
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
        final now = DateTime.now();
        final quarter = ((now.month - 1) ~/ 3) + 1;
        return 'Q$quarter Activity';
    }
  }

  Widget _buildDateRange() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Text(
        _getDateRangeText(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
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
        // Quarter view
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        final startDate = DateTime(now.year, startMonth, 1);
        final endDate = DateTime(now.year, endMonth + 1, 0);
        return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
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

    // Get start of week preference
    final startOfWeek = ref.watch(settingsProvider)['startOfWeek'] as String;
    final weekStartsOnSunday = startOfWeek == 'Sun';

    // Adjust the day labels based on start of week
    final dayLabels = weekStartsOnSunday
        ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate offset for empty cells
    // If week starts on Sunday, weekday 7 (Sunday) should be 0
    // If week starts on Monday, weekday 1 (Monday) should be 0
    final offset = weekStartsOnSunday
        ? (firstWeekday == 7 ? 0 : firstWeekday)
        : (firstWeekday - 1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day labels
          Row(
            children: dayLabels
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
            itemCount: offset + daysInMonth,
            itemBuilder: (context, index) {
              // Empty cells before the 1st
              if (index < offset) {
                return const SizedBox();
              }

              final day = index - offset + 1;
              final date = DateTime(now.year, now.month, day);
              final intensity = _getMonthDayIntensity(day);

              final isDark = Theme.of(context).brightness == Brightness.dark;
              return GestureDetector(
                onLongPress: () {
                  _handleLongPress(date);
                },
                child: Container(
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
                            ? (isDark
                                  ? AppColors.textMuted
                                  : const Color(0xFF94A3B8))
                            : (isDark
                                  ? AppColors.textPrimary
                                  : const Color(0xFF0a160f)),
                      ),
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

    // Get start of week preference
    final startOfWeek = ref.watch(settingsProvider)['startOfWeek'] as String;
    final weekStartsOnSunday = startOfWeek == 'Sun';

    final days = weekStartsOnSunday
        ? ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Calculate dates based on week start preference
    final dates = List.generate(7, (i) {
      if (weekStartsOnSunday) {
        // For Sunday start: calculate from Sunday of current week
        final todayWeekday = now.weekday; // 1 = Mon, 7 = Sun
        final daysSinceSunday = todayWeekday == 7 ? 0 : todayWeekday;
        return now.subtract(Duration(days: daysSinceSunday - i));
      } else {
        // For Monday start: calculate from Monday of current week (existing logic)
        return now.subtract(Duration(days: 6 - i));
      }
    });

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
              final intensity = _getBarIntensity(index, weekStartsOnSunday);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 6,
                    right: index == 6 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      _handleLongPress(date);
                    },
                    child: Column(
                      children: [
                        Text(
                          days[index],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSecondary
                                : const Color(0xFF94A3B8),
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
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  double _getBarIntensity(int dayIndex, bool weekStartsOnSunday) {
    final now = DateTime.now();

    DateTime date;
    if (weekStartsOnSunday) {
      // For Sunday start: calculate from Sunday of current week
      final todayWeekday = now.weekday; // 1 = Mon, 7 = Sun
      final daysSinceSunday = todayWeekday == 7 ? 0 : todayWeekday;
      date = now.subtract(Duration(days: daysSinceSunday - dayIndex));
    } else {
      // For Monday start: existing logic
      date = now.subtract(Duration(days: 6 - dayIndex));
    }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // For quarterly view, show the actual quarter months
    if (_selectedTimeframe == 'Quarter') {
      final quarter = ((now.month - 1) ~/ 3) + 1;
      final startMonth = (quarter - 1) * 3 + 1;
      final month1 = months[startMonth - 1];
      final month2 = months[startMonth];
      final month3 = months[startMonth + 1];

      return Padding(
        padding: const EdgeInsets.only(left: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              month1,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondary
                    : const Color(0xFF94A3B8),
              ),
            ),
            Text(
              month2,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondary
                    : const Color(0xFF94A3B8),
              ),
            ),
            Text(
              month3,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondary
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    // Default: Calculate which months to show based on 90 days back
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
              color: isDark ? AppColors.textSecondary : const Color(0xFF94A3B8),
            ),
          ),
          Text(
            month2,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? AppColors.textSecondary : const Color(0xFF94A3B8),
            ),
          ),
          Text(
            month3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? AppColors.textSecondary : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapGrid() {
    final days = _getDaysCount();

    // Get start of week preference
    final startOfWeek = ref.watch(settingsProvider)['startOfWeek'] as String;
    final weekStartsOnSunday = startOfWeek == 'Sun';

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
                          // Adjust cell index based on week start
                          // For Sunday start: row 0 = Sunday, row 1 = Monday, etc.
                          // For Monday start: row 0 = Monday, row 1 = Tuesday, etc.
                          final cellIndex = col * rows + row;
                          return Padding(
                            padding: EdgeInsets.only(left: col == 0 ? 0 : gap),
                            child: GestureDetector(
                              onLongPress: () {
                                final date = _getDateForCellIndex(
                                  cellIndex,
                                  days,
                                  weekStartsOnSunday,
                                );
                                _handleLongPress(date);
                              },
                              child: SizedBox(
                                width: cellSize,
                                height: cellSize,
                                child: _buildHeatmapCellManual(
                                  cellIndex,
                                  days,
                                  weekStartsOnSunday: weekStartsOnSunday,
                                ),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondary
                            : const Color(0xFF94A3B8),
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
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);

    // Get start of week preference
    final startOfWeek = ref.watch(settingsProvider)['startOfWeek'] as String;
    final weekStartsOnSunday = startOfWeek == 'Sun';

    // Calculate which date this grid cell represents
    // Grid is column-major: index = col * 7 + row
    final row = index % 7;
    final col = index ~/ 7;

    // Find the Monday (or Sunday) of the week containing Jan 1
    final startWeekday = startOfYear.weekday; // 1=Mon, 7=Sun
    int daysToSubtract;

    if (weekStartsOnSunday) {
      // Adjust to Sunday start (0=Sun, 1=Mon...6=Sat)
      daysToSubtract = startWeekday == 7 ? 0 : startWeekday;
    } else {
      // Monday start
      daysToSubtract = startWeekday - 1; // Days to go back to Monday
    }

    final firstCellDate = startOfYear.subtract(Duration(days: daysToSubtract));
    final date = firstCellDate.add(Duration(days: col * 7 + row));

    // Check if date is outside the year range
    if (date.year != now.year) {
      return Container(
        decoration: BoxDecoration(
          color: _getColorForIntensity(0),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    // Show future dates with zero intensity color
    if (date.isAfter(now)) {
      return Container(
        decoration: BoxDecoration(
          color: _getColorForIntensity(0),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

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
        // Quarter: calculate days in current quarter
        final now = DateTime.now();
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        final endMonth = quarter * 3;
        int totalDays = 0;
        for (int month = startMonth; month <= endMonth; month++) {
          totalDays += DateTime(now.year, month + 1, 0).day;
        }
        return totalDays;
    }
  }

  Widget _buildDayLabels() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? AppColors.textSecondary
        : const Color(0xFF94A3B8);

    // Get start of week preference
    final startOfWeek = ref.watch(settingsProvider)['startOfWeek'] as String;
    final weekStartsOnSunday = startOfWeek == 'Sun';

    // Labels for Sunday start: Sun, Tue, Thu, Sat
    // Labels for Monday start: Mon, Wed, Fri, Sun
    final labels = weekStartsOnSunday
        ? ['Sun', 'Tue', 'Thu', 'Sat']
        : ['Mon', 'Wed', 'Fri', 'Sun'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: labels
          .map(
            (label) => Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildHeatmapCellManual(
    int index,
    int totalDays, {
    double? overrideIntensity,
    bool weekStartsOnSunday = false,
  }) {
    // For Quarter/Year views, calculate date directly
    if (_selectedTimeframe == 'Quarter' || _selectedTimeframe == 'Year') {
      final now = DateTime.now();
      DateTime startDate;

      if (_selectedTimeframe == 'Quarter') {
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        startDate = DateTime(now.year, startMonth, 1);
      } else {
        startDate = DateTime(now.year, 1, 1);
      }

      // Calculate which date this grid cell represents
      // Grid is column-major: index = col * 7 + row
      // Row 0 = Monday (or Sunday if weekStartsOnSunday)
      final row = index % 7;
      final col = index ~/ 7;

      // Find the Monday (or Sunday) of the week containing startDate
      int startWeekday = startDate.weekday; // 1=Mon, 7=Sun
      int daysToSubtract;

      if (weekStartsOnSunday) {
        // Adjust to Sunday start (0=Sun, 1=Mon...6=Sat)
        daysToSubtract = startWeekday == 7 ? 0 : startWeekday;
      } else {
        // Monday start
        daysToSubtract = startWeekday - 1; // 0=Mon, 1=Tue...6=Sun
      }

      final firstCellDate = startDate.subtract(Duration(days: daysToSubtract));
      final date = firstCellDate.add(Duration(days: col * 7 + row));

      // Check if this date is outside the period range
      final periodEnd = _selectedTimeframe == 'Year'
          ? DateTime(now.year, 12, 31)
          : DateTime(
              now.year,
              ((((now.month - 1) ~/ 3) + 1) * 3),
              DateTime(now.year, ((((now.month - 1) ~/ 3) + 1) * 3) + 1, 0).day,
            );

      if (date.isBefore(startDate) || date.isAfter(periodEnd)) {
        return Container(
          decoration: BoxDecoration(
            color: _getColorForIntensity(0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

      // Show future dates with zero intensity color
      if (date.isAfter(now)) {
        return Container(
          decoration: BoxDecoration(
            color: _getColorForIntensity(0),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }

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
        (index >= totalDays
            ? -1
            : _getCellIntensity(index, totalDays, weekStartsOnSunday));

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

  double _getCellIntensity(int index, int totalDays, bool weekStartsOnSunday) {
    final date = _getDateForIndex(index, weekStartsOnSunday);
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

  DateTime _getDateForIndex(int index, [bool weekStartsOnSunday = false]) {
    final now = DateTime.now();
    int daysToSubtract;

    switch (_selectedTimeframe) {
      case 'Week':
        daysToSubtract = 6 - index; // 0 = 6 days ago, 6 = today

        // Adjust for Sunday week start
        if (weekStartsOnSunday) {
          // In Sunday-start mode, we need to shift the week alignment
          // row 0 should be Sunday, row 6 should be Saturday
          final todayWeekday = now.weekday; // 1 = Mon, 7 = Sun
          final todayPosInWeek = todayWeekday == 7
              ? 0
              : todayWeekday; // Convert to 0 = Sun, 1 = Mon, etc.
          final targetDayOfWeek = index; // 0-6 where 0 = Sunday in our grid

          daysToSubtract = (todayPosInWeek - targetDayOfWeek + 7) % 7;
        }
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

    // Calculate score (0-3) and convert to intensity (0.0-1.0) for coloring
    final score = calculateDailyScore(
      completedHabits: completedCount,
      totalHabits: habits.length,
    );

    // Map score to intensity: 0→0.0, 1→0.33, 2→0.66, 3→1.0
    return score / 3.0;
  }

  /// Calculates aggregated score for the current timeframe
  ({int score, int maxScore}) _calculateAggregatedScore() {
    if (_prefs == null) return (score: 0, maxScore: 0);

    final habits = ref.read(habitListProvider);
    final now = DateTime.now();
    final List<int> dailyScores = [];

    int days;
    DateTime startDate;

    switch (_selectedTimeframe) {
      case 'Week':
        days = 7;
        startDate = now.subtract(const Duration(days: 6));
        break;
      case 'Month':
        days = DateTime(now.year, now.month + 1, 0).day;
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        days = 365;
        startDate = DateTime(now.year, 1, 1);
        break;
      default: // Quarter
        days = 90;
        startDate = now.subtract(const Duration(days: 89));
    }

    // Calculate daily scores for the range
    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));

      // Don't include future dates
      if (date.isAfter(now)) break;

      final dateKey = _formatDateKey(date);
      int completedCount = 0;

      for (final habit in habits) {
        final logKey = 'habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      final score = calculateDailyScore(
        completedHabits: completedCount,
        totalHabits: habits.length,
      );
      dailyScores.add(score);
    }

    return aggregateScores(dailyScores);
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == -1) return Colors.transparent; // Future cell
    if (intensity == -2) return Colors.transparent; // Today cell

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Map intensity to score (0.0, 0.33, 0.66, 1.0 → 0, 1, 2, 3)
    int score;
    if (intensity == 0.0) {
      score = 0;
    } else if (intensity <= 0.33) {
      score = 1;
    } else if (intensity <= 0.66) {
      score = 2;
    } else {
      score = 3;
    }

    return AppColors.heatmapColor(score, isDark);
  }

  Widget _buildLegend() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          _buildLegendBox(AppColors.heatmapColor(0, isDark)),
          const SizedBox(width: 4),
          _buildLegendBox(AppColors.heatmapColor(1, isDark)),
          const SizedBox(width: 4),
          _buildLegendBox(AppColors.heatmapColor(2, isDark)),
          const SizedBox(width: 4),
          _buildLegendBox(AppColors.heatmapColor(3, isDark)),
          const SizedBox(width: 8),
          Text(
            'More',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
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
          final available = math.max(
            0.0,
            constraints.maxWidth - 48,
          ); // Equal outer margins
          final groupWidth = math.min(targetGroupWidth, available);
          final cardWidth = (groupWidth - gap * 2) / 3;

          return Center(
            child: SizedBox(
              width: groupWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: _buildStreakCard()),
                  const SizedBox(width: gap),
                  Expanded(child: _buildConsistencyCard()),
                  const SizedBox(width: gap),
                  Expanded(child: _buildPerfectDaysCard(count: '')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStreakCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streakDays = _calculateCurrentStreak();

    return Column(
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
                color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
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
            color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final consistency = _calculateConsistency();

    return Column(
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
                color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
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
            color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perfectDays = _calculatePerfectDays();

    return Column(
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
                color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
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
            color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
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

  DateTime _getDateForCellIndex(
    int index,
    int totalDays, [
    bool weekStartsOnSunday = false,
  ]) {
    if (_selectedTimeframe == 'Quarter' || _selectedTimeframe == 'Year') {
      final now = DateTime.now();
      DateTime startDate;

      if (_selectedTimeframe == 'Quarter') {
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final startMonth = (quarter - 1) * 3 + 1;
        startDate = DateTime(now.year, startMonth, 1);
      } else {
        startDate = DateTime(now.year, 1, 1);
      }

      // Calculate which date this grid cell represents
      // Grid is column-major: index = col * 7 + row
      final row = index % 7;
      final col = index ~/ 7;

      // Find the Monday (or Sunday) of the week containing startDate
      int startWeekday = startDate.weekday; // 1=Mon, 7=Sun
      int daysToSubtract;

      if (weekStartsOnSunday) {
        // Adjust to Sunday start (0=Sun, 1=Mon...6=Sat)
        daysToSubtract = startWeekday == 7 ? 0 : startWeekday;
      } else {
        // Monday start
        daysToSubtract = startWeekday - 1; // 0=Mon, 1=Tue...6=Sun
      }

      final firstCellDate = startDate.subtract(Duration(days: daysToSubtract));
      final date = firstCellDate.add(Duration(days: col * 7 + row));

      return date;
    }
    return _getDateForIndex(index, weekStartsOnSunday);
  }

  void _handleLongPress(DateTime date) {
    final now = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);

    // Don't allow future dates
    if (dateOnly.isAfter(todayOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can only log past or current days.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF6B7280),
        ),
      );
      return;
    }

    _showPastDateLoggingSheet(date);
  }

  void _showPastDateLoggingSheet(DateTime date) {
    final dateKey = _formatDateKey(date);
    final habits = ref
        .read(habitListProvider.notifier)
        .getHabitsForDate(dateKey);

    // Local state for the sheet
    final habitStates = Map<String, bool>.fromEntries(
      habits.map((h) => MapEntry(h.id, h.completed)),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log habits for ${_formatDisplayDate(date)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 20),
                if (habits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No habits to log for this date',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondary
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  )
                else
                  ...habits.map((habit) {
                    final isCompleted = habitStates[habit.id] ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setModalState(() {
                            habitStates[habit.id] = !isCompleted;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCompleted
                                  ? const Color(0xFF3f6a4a).withOpacity(0.3)
                                  : (isDark
                                        ? AppColors.darkDivider
                                        : const Color(0xFFF1F3F2)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF3f6a4a).withOpacity(0.1)
                                      : (isDark
                                            ? AppColors.darkBackground
                                            : const Color(0xFFF8F9FA)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  habit.iconCodePoint != null
                                      ? IconData(
                                          habit.iconCodePoint!,
                                          fontFamily: 'MaterialIcons',
                                        )
                                      : Icons.check_circle_outline,
                                  color: isCompleted
                                      ? const Color(0xFF3f6a4a)
                                      : (isDark
                                            ? AppColors.textMuted
                                            : const Color(0xFF9CA3AF)),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  habit.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimary
                                        : const Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF3f6a4a)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: isCompleted
                                      ? null
                                      : Border.all(
                                          color: isDark
                                              ? AppColors.darkDivider
                                              : const Color(0xFFE5E7EB),
                                          width: 2,
                                        ),
                                ),
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondary
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Save all changes
                        for (final habit in habits) {
                          final shouldBeCompleted =
                              habitStates[habit.id] ?? false;
                          final currentlyCompleted = habit.completed;

                          if (shouldBeCompleted != currentlyCompleted) {
                            ref
                                .read(habitListProvider.notifier)
                                .toggleForDate(habit.id, dateKey);
                          }
                        }

                        // Refresh heatmap
                        setState(() {
                          _intensityCache = {};
                        });

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3f6a4a),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDisplayDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
