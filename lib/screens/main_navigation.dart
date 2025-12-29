import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import 'friends_screen.dart';
import 'habit_logger_screen.dart';
import 'heatmap_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;
  VoidCallback? _onAddHabitPressed;

  List<Widget> get _screens => [
    HabitLoggerScreen(onRegisterAddCallback: (callback) {
      setState(() => _onAddHabitPressed = callback);
    }),
    const HeatmapScreen(),
    const FriendsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: _selectedIndex == 0 ? _buildFAB() : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildFAB() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      color: const Color(0xFF3f6a4a),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF3f6a4a).withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          _onAddHabitPressed?.call();
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    ),
  );

  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
    height: 80,
    decoration: BoxDecoration(
      color: isDark 
          ? AppColors.darkCard.withOpacity(0.95)
          : Colors.white.withOpacity(0.9),
      border: Border(top: BorderSide(
        color: isDark ? AppColors.darkDivider : const Color(0xFFF1F3F2), 
        width: 1
      )),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(Icons.home, 'Home', 0),
        _buildNavItem(Icons.bar_chart, 'Stats', 1),
        _buildNavItem(Icons.groups, 'Friends', 2),
        _buildNavItem(Icons.settings, 'Settings', 3),
      ],
    ),
  );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF3f6a4a)
                  : (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF3f6a4a)
                    : (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
