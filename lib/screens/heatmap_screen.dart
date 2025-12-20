import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key});

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  String _selectedTimeframe = 'Quarter';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    _buildShareButton(),
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
        onTap: () => setState(() => _selectedTimeframe = label),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _getTitleText(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF13EC6A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Color(0xFF13EC6A),
                ),
                const SizedBox(width: 4),
                Text(
                  _selectedTimeframe == 'Year' ? '+24%' : '+12%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF13EC6A),
                  ),
                ),
              ],
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
        const months = ['January', 'February', 'March', 'April', 'May', 'June',
                       'July', 'August', 'September', 'October', 'November', 'December'];
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
        const months = ['January', 'February', 'March', 'April', 'May', 'June',
                       'July', 'August', 'September', 'October', 'November', 'December'];
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
                .map((day) => Expanded(
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
                    ))
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
    // Generate varied intensities for monthly calendar
    final hash = (day * 13 + 7) % 100;
    if (hash < 10) return 0.0; // Empty
    if (hash < 20) return 0.2;
    if (hash < 35) return 0.4;
    if (hash < 50) return 0.6;
    if (hash < 70) return 0.8;
    return 1.0;
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
              final isToday = date.day == now.day && 
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
                                  color: const Color(0xFF13EC6A),
                                  width: 2,
                                )
                              : null,
                          boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF13EC6A).withOpacity(0.3),
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
                              ? const Color(0xFF13EC6A)
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
    // Generate varied intensities for the weekly bars
    const intensities = [0.4, 0.8, 1.0, 0.2, 0.0, 0.6, 0.9];
    return intensities[dayIndex % 7];
  }

  Widget _buildMonthLabels() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
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
        final cellSize = (constraints.maxWidth - totalGaps - 32 - 8) / weeks; // subtract day labels width + spacer
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
                                padding: EdgeInsets.only(left: col == 0 ? 0 : gap),
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

    final intensity = _getCellIntensity(index, totalDays);
    return Container(
      decoration: BoxDecoration(
        color: _getColorForIntensity(intensity),
        borderRadius: BorderRadius.circular(2),
        border: intensity == -1
            ? Border.all(color: const Color(0xFFCBD5E1), width: 1)
            : intensity == -2
                ? Border.all(color: const Color(0xFF13EC6A), width: 2)
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

  Widget _buildHeatmapCell(int index, int totalDays) {
    final intensity = _getCellIntensity(index, totalDays);
    return _buildHeatmapCellManual(index, totalDays, overrideIntensity: intensity);
  }

  Widget _buildHeatmapCellManual(int index, int totalDays, {double? overrideIntensity}) {
    final intensity = overrideIntensity ??
        (index >= totalDays ? -1 : _getCellIntensity(index, totalDays));

    return Container(
      decoration: BoxDecoration(
        color: _getColorForIntensity(intensity),
        borderRadius: BorderRadius.circular(4),
        border: intensity == -1
            ? Border.all(color: const Color(0xFFCBD5E1), width: 1)
            : intensity == -2
                ? Border.all(color: const Color(0xFF13EC6A), width: 2)
                : null,
      ),
    );
  }

  double _getCellIntensity(int index, int totalDays) {
    // Last 4 cells are future (empty with border)
    if (index >= totalDays - 4) {
      return -1; // Empty future cell
    }

    // Second to last is today (highlighted)
    if (index == totalDays - 5) {
      return -2; // Today cell
    }

    // Generate varied intensities based on position
    final hash = (index * 17 + 23) % 100;
    if (hash < 5) return 0.0; // Empty
    if (hash < 20) return 0.2;
    if (hash < 40) return 0.4;
    if (hash < 60) return 0.6;
    if (hash < 80) return 0.8;
    return 1.0;
  }

  Color _getColorForIntensity(double intensity) {
    if (intensity == -1) return Colors.transparent; // Future cell
    if (intensity == -2) return Colors.transparent; // Today cell
    if (intensity == 0.0) return const Color(0xFFF1F5F9);

    const primary = Color(0xFF13EC6A);
    return primary.withOpacity(intensity);
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
          _buildLegendBox(const Color(0xFF13EC6A).withOpacity(0.3)),
          const SizedBox(width: 4),
          _buildLegendBox(const Color(0xFF13EC6A).withOpacity(0.6)),
          const SizedBox(width: 4),
          _buildLegendBox(const Color(0xFF13EC6A)),
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
    if (_selectedTimeframe == 'Week') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStreakCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildConsistencyCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildWeeklyHabitsCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildPerfectDaysCard(count: '3')),
              ],
            ),
          ],
        ),
      );
    }
    
    if (_selectedTimeframe == 'Month') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStreakCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildConsistencyCard(subtitle: 'High performance')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTotalHabitsCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildPerfectDaysCard(count: '18')),
              ],
            ),
          ],
        ),
      );
    }
    
    if (_selectedTimeframe == 'Year') {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildStreakCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildConsistencyCard(subtitle: 'High performance')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTotalCompletionsCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildPerfectDaysCard(count: '156')),
              ],
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStreakCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildConsistencyCard(subtitle: 'High performance')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTotalCompletionsCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildPerfectDaysCard(count: '45')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyHabitsCard() {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'WEEKLY HABITS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '34',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final days = _selectedTimeframe == 'Year' ? '45' : '24';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFF13EC6A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Streak',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$days Days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+2 from last week',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF13EC6A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsistencyCard({String subtitle = 'Excellent week!'}) {
    String percentage;
    String defaultSubtitle;
    
    if (_selectedTimeframe == 'Year') {
      percentage = '85%';
      defaultSubtitle = 'High performance';
    } else if (_selectedTimeframe == 'Quarter') {
      percentage = '85%';
      defaultSubtitle = subtitle;
    } else {
      percentage = '92%';
      defaultSubtitle = subtitle;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large, color: Color(0xFF60A5FA), size: 20),
              const SizedBox(width: 8),
              Text(
                'Consistency',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            percentage,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            defaultSubtitle,
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

  Widget _buildTotalCompletionsCard() {
    final count = _selectedTimeframe == 'Year' ? '1,248' : '312';
    
    return Container(
      height: 112,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL COMPLETIONS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfectDaysCard({required String count}) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERFECT DAYS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.verified, color: Color(0xFF13EC6A), size: 16),
            ],
          ),
          Text(
            count,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    String buttonText;
    switch (_selectedTimeframe) {
      case 'Week':
        buttonText = 'Share Weekly Report';
        break;
      case 'Month':
        buttonText = 'Share Monthly Report';
        break;
      case 'Year':
        buttonText = 'Share Yearly Report';
        break;
      default:
        buttonText = 'Share Streak';
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.ios_share, size: 20),
              const SizedBox(width: 8),
              Text(
                buttonText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalHabitsCard() {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TOTAL HABITS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          Text(
            '142',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
