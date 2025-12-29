import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/habit_provider.dart';
import '../utils/app_colors.dart';
import '../utils/scoring_logic.dart';

class FriendDetailScreen extends ConsumerStatefulWidget {
  final String friendName;
  final String friendId;

  const FriendDetailScreen({
    super.key,
    required this.friendName,
    required this.friendId,
  });

  @override
  ConsumerState<FriendDetailScreen> createState() =>
      _FriendDetailScreenState();
}

class _FriendDetailScreenState extends ConsumerState<FriendDetailScreen> {
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
        _intensityCache = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3f6a4a)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.95)),
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
              "${widget.friendName}'s Lifestreak",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 40), // Spacer for alignment
          ],
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
        child: Icon(icon, color: isDark ? AppColors.textPrimary : const Color(0xFF0F172A), size: 24),
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
          _intensityCache = {};
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
        return 'Last 90 Days';
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
              final intensity = _calculateIntensityForDate(date);

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

  Widget _buildMonthlyCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
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
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }

              final day = index - firstWeekday + 2;
              final date = DateTime(now.year, now.month, day);
              final intensity = _calculateIntensityForDate(date);

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
    const days = 90;
    const rows = 7;
    const gap = 6.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final weeks = (days / rows).ceil();
        final totalGaps = (weeks - 1) * gap;
        final cellSize = (constraints.maxWidth - totalGaps - 32 - 8) / weeks;
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
                              child: _buildHeatmapCell(cellIndex, days),
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
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildYearlyHeatmapSection(
            title: 'Jan - Jun',
            startMonth: 1,
            endMonth: 6,
          ),
          const SizedBox(height: 24),
          _buildYearlyHeatmapSection(
            title: 'Jul - Dec',
            startMonth: 7,
            endMonth: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyHeatmapSection({
    required String title,
    required int startMonth,
    required int endMonth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    const rows = 7;
    const gap = 4.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondary : const Color(0xFF64748B),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final monthsToShow = endMonth - startMonth + 1;
            int totalDays = 0;
            for (int m = startMonth; m <= endMonth; m++) {
              totalDays += DateTime(now.year, m + 1, 0).day;
            }

            final weeks = (totalDays / rows).ceil();
            final totalGaps = (weeks - 1) * gap;
            final cellSize =
                (constraints.maxWidth - totalGaps - 32 - 8) / weeks;
            final gridHeight = rows * cellSize + (rows - 1) * gap;

            return Row(
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
                                padding:
                                    EdgeInsets.only(left: col == 0 ? 0 : gap),
                                child: SizedBox(
                                  width: cellSize,
                                  height: cellSize,
                                  child: _buildYearlyHeatmapCell(
                                    cellIndex,
                                    totalDays,
                                    startMonth,
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
        ),
      ],
    );
  }

  Widget _buildYearlyHeatmapCell(
    int index,
    int totalDays,
    int startMonth,
  ) {
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
    final firstDay = DateTime(now.year, startMonth, 1);
    final date = firstDay.add(Duration(days: index));

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

  Widget _buildHeatmapCell(int index, int totalDays) {
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
    final date = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysBack));

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

  Widget _buildDayLabels() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textSecondary : const Color(0xFF94A3B8);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
          .map(
            (day) => Text(
              day,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: labelColor,
              ),
            ),
          )
          .toList(),
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double _calculateIntensityForDate(DateTime date) {
    if (_prefs == null) return 0.0;

    // Mock data for friend - in real implementation, this would fetch friend's data
    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0.0;

    final dateKey = _formatDateKey(date);
    
    // Simulate friend completion data (using same storage prefix with friend ID)
    int completedCount = 0;
    for (final habit in habits) {
      final logKey = 'friend_${widget.friendId}_habit_log_${habit.id}_$dateKey';
      if (_prefs!.getBool(logKey) == true) {
        completedCount++;
      }
    }

    final score = calculateDailyScore(
      completedHabits: completedCount,
      totalHabits: habits.length,
    );

    return score / 3.0;
  }

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
      default:
        days = 90;
        startDate = now.subtract(const Duration(days: 89));
    }

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      if (date.isAfter(now)) break;

      final dateKey = _formatDateKey(date);
      int completedCount = 0;

      for (final habit in habits) {
        final logKey =
            'friend_${widget.friendId}_habit_log_${habit.id}_$dateKey';
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
          final available = math.max(0.0, constraints.maxWidth - 32);
          final groupWidth = math.min(targetGroupWidth, available);
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
                  SizedBox(width: cardWidth, child: _buildPerfectDaysCard()),
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

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      ),
    );
  }

  Widget _buildConsistencyCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final consistency = _calculateConsistency();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      ),
    );
  }

  Widget _buildPerfectDaysCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final perfectDays = _calculatePerfectDays();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
      ),
    );
  }

  int _calculateCurrentStreak() {
    if (_prefs == null) return 0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);

      int completedCount = 0;
      for (final habit in habits) {
        final logKey =
            'friend_${widget.friendId}_habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      final score = calculateDailyScore(
        completedHabits: completedCount,
        totalHabits: habits.length,
      );

      if (score > 0) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateConsistency() {
    if (_prefs == null) return 0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    int daysWithActivity = 0;

    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);

      int completedCount = 0;
      for (final habit in habits) {
        final logKey =
            'friend_${widget.friendId}_habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      if (completedCount > 0) {
        daysWithActivity++;
      }
    }

    return ((daysWithActivity / 90) * 100).round();
  }

  int _calculatePerfectDays() {
    if (_prefs == null) return 0;

    final habits = ref.read(habitListProvider);
    if (habits.isEmpty) return 0;

    final now = DateTime.now();
    int perfectDays = 0;

    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDateKey(date);

      int completedCount = 0;
      for (final habit in habits) {
        final logKey =
            'friend_${widget.friendId}_habit_log_${habit.id}_$dateKey';
        if (_prefs!.getBool(logKey) == true) {
          completedCount++;
        }
      }

      final score = calculateDailyScore(
        completedHabits: completedCount,
        totalHabits: habits.length,
      );

      if (score == 3) {
        perfectDays++;
      }
    }

    return perfectDays;
  }
}
