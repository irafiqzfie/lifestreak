import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
import '../utils/mock_friends.dart';

class HabitLoggerScreen extends ConsumerStatefulWidget {
  const HabitLoggerScreen({super.key});

  @override
  ConsumerState<HabitLoggerScreen> createState() => _HabitLoggerScreenState();
}

class _HabitLoggerScreenState extends ConsumerState<HabitLoggerScreen> {
  int _selectedNavIndex = 0;

  IconData _getHabitIcon(String habitName) {
    final nameLower = habitName.toLowerCase();
    if (nameLower.contains('water') || nameLower.contains('drink'))
      return Icons.water_drop;
    if (nameLower.contains('read') || nameLower.contains('book'))
      return Icons.menu_book;
    if (nameLower.contains('gym') ||
        nameLower.contains('workout') ||
        nameLower.contains('exercise'))
      return Icons.fitness_center;
    if (nameLower.contains('meditate') || nameLower.contains('meditation'))
      return Icons.self_improvement;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitListProvider);
    final authState = ref.watch(authProvider);
    final username = authState.session?.username ?? 'User';
    final completedCount = habits.where((h) => h.completed).length;
    final totalCount = habits.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    ref.listen<List<Habit>>(habitListProvider, (previous, next) {
      if (previous != next) ref.read(syncServiceProvider).syncHabitLogs();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(username),
            if (kDebugMode) _buildSyncStatusIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildDailyScoreCard(completedCount, totalCount, progress),
                    const SizedBox(height: 24),
                    _buildHabitsSection(habits),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
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
        onTap: () => _showCreateHabitSheet(context),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    ),
  );

  Widget _buildHeader(String username) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    final dateStr = _formatDate(now);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: const Color(0xFF3f6a4a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$greeting, $username',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() => GestureDetector(
    onTap: () => _showProfileMenu(context),
    child: Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF3f6a4a).withOpacity(0.3),
              width: 2,
            ),
            color: const Color(0xFF3f6a4a).withOpacity(0.1),
          ),
          child: const Icon(Icons.person, color: Color(0xFF3f6a4a), size: 24),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF3f6a4a),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    ),
  );

  String _formatDate(DateTime d) =>
      '${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1]}, ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.day}';

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('Seed Mock Friends'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await seedMockFriends();
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mock friends added')),
                    );
                },
              ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Friends'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/friends');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Heatmap'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/heatmap');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    final syncService = ref.read(syncServiceProvider);
    return ValueListenableBuilder<SyncStatus>(
      valueListenable: syncService.statusNotifier,
      builder: (context, status, _) {
        final color = status == SyncStatus.error
            ? const Color(0xFFEF4444)
            : const Color(0xFF3f6a4a);
        final label = switch (status) {
          SyncStatus.syncing => 'Syncing...',
          SyncStatus.success => 'Synced',
          SyncStatus.error => 'Changes saved locally',
          _ => 'Offline',
        };
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          color: color.withOpacity(0.08),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyScoreCard(int completed, int total, double progress) {
    final isPerfectDay = completed > 0 && completed == total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F3F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Completed ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      '$completed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        height: 1,
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'habits',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            if (isPerfectDay)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3f6a4a).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3f6a4a).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF3f6a4a),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Perfect Day',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3f6a4a),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsSection(List<Habit> habits) {
    if (habits.isEmpty)
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create your first habit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Habits',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Edit List',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3f6a4a),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            habits.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHabitCard(habits[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final isCompleted = habit.completed;
    final hash = habit.name.hashCode.abs();
    final streakPattern = List.generate(5, (i) => (hash >> i) & 1 == 1);
    final streakDays = isCompleted ? (hash % 15) + 1 : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF3f6a4a).withOpacity(0.3)
              : const Color(0xFFF1F3F2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF3f6a4a).withOpacity(0.1)
                  : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getHabitIcon(habit.name),
              color: isCompleted
                  ? const Color(0xFF3f6a4a)
                  : const Color(0xFF9CA3AF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1F2937),
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    decorationColor: const Color(0xFFD1D5DB),
                    decorationThickness: 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: streakPattern[i]
                              ? const Color(0xFF3f6a4a)
                              : const Color(0xFFD1D5DB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    if (streakDays > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$streakDays DAY STREAK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: const Color(0xFF3f6a4a),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(habitListProvider.notifier).toggle(habit.id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF3f6a4a)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isCompleted
                    ? null
                    : Border.all(color: const Color(0xFFE5E7EB), width: 2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() => Container(
    height: 80,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      border: const Border(top: BorderSide(color: Color(0xFFF1F3F2), width: 1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavItem(Icons.home, 'Home', 0, null),
        _buildNavItem(Icons.bar_chart, 'Stats', 1, '/heatmap'),
        _buildNavItem(Icons.groups, 'Social', 2, '/friends'),
        _buildNavItem(Icons.settings, 'Settings', 3, '/settings'),
      ],
    ),
  );

  Widget _buildNavItem(IconData icon, String label, int index, String? route) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (route != null && !isSelected)
          Navigator.pushNamed(context, route);
        else
          setState(() => _selectedNavIndex = index);
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
                  : const Color(0xFF9CA3AF),
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
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateHabitSheet(BuildContext context) {
    final controller = TextEditingController();
    bool isValid = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Habit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Habit name',
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF6B7280),
                  ),
                  hintText: 'e.g., Meditate 10 mins',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3f6a4a),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => isValid = v.trim().isNotEmpty),
                onSubmitted: (v) {
                  if (v.trim().isEmpty) return;
                  ref.read(habitListProvider.notifier).addHabit(v.trim());
                  Navigator.pop(context);
                },
              ),
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
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isValid
                        ? () {
                            if (controller.text.trim().isEmpty) return;
                            ref
                                .read(habitListProvider.notifier)
                                .addHabit(controller.text.trim());
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3f6a4a),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E7EB),
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
                      'Add Habit',
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
        ),
      ),
    );
  }
}
