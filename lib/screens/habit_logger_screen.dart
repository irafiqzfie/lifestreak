import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/sync_provider.dart';
import '../services/sync_service.dart';
import '../utils/app_colors.dart';
import '../utils/scoring_logic.dart';

class HabitLoggerScreen extends ConsumerStatefulWidget {
  final Function(VoidCallback)? onRegisterAddCallback;
  
  const HabitLoggerScreen({super.key, this.onRegisterAddCallback});

  @override
  ConsumerState<HabitLoggerScreen> createState() => _HabitLoggerScreenState();
  
  static _HabitLoggerScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_HabitLoggerScreenState>();
  }
}

class _HabitLoggerScreenState extends ConsumerState<HabitLoggerScreen> {
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Register the callback with the parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterAddCallback?.call(showCreateHabitSheet);
    });
  }

  void showCreateHabitSheet() {
    _showCreateHabitSheet(context);
  }

  IconData _getHabitIcon(String habitName) {
    final nameLower = habitName.toLowerCase();
    if (nameLower.contains('water') || nameLower.contains('drink')) {
      return Icons.water_drop;
    }
    if (nameLower.contains('read') || nameLower.contains('book')) {
      return Icons.menu_book;
    }
    if (nameLower.contains('gym') ||
        nameLower.contains('workout') ||
        nameLower.contains('exercise')) {
      return Icons.fitness_center;
    }
    if (nameLower.contains('meditate') || nameLower.contains('meditation')) {
      return Icons.self_improvement;
    }
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

    return Column(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    color: isDark ? AppColors.textPrimary : const Color(0xFF111827),
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

  Widget _buildAvatar() => Stack(
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
  );

  String _formatDate(DateTime d) =>
      '${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][d.weekday - 1]}, ${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]} ${d.day}';

  // Popup menu removed: actions are available via header/navigation.

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyScore = calculateDailyScore(
      completedHabits: completed,
      totalHabits: total,
    );
    final isPerfectDay = completed > 0 && completed == total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkDivider : const Color(0xFFF1F3F2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  'Score: $dailyScore / 3',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3f6a4a),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$completed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF111827),
                        height: 1,
                      ),
                    ),
                    Text(
                      ' / $total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'habits completed',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                if (isPerfectDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
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
                          size: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsSection(List<Habit> habits) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (habits.isEmpty) {
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
    }
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
                  color: isDark ? AppColors.textPrimary : const Color(0xFF111827),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
                child: Text(
                  _isEditMode ? 'Done' : 'Edit List',
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
              child: _buildHabitCard(habits[i], isEditMode: _isEditMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, {bool isEditMode = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = habit.completed;
    final hash = habit.name.hashCode.abs();
    final streakPattern = List.generate(5, (i) => (hash >> i) & 1 == 1);
    final streakDays = isCompleted ? (hash % 15) + 1 : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF3f6a4a).withOpacity(0.3)
              : (isDark ? AppColors.darkDivider : const Color(0xFFF1F3F2)),
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
          GestureDetector(
            onTap: isEditMode
                ? () => _showIconPicker(context, (icon) {
                      ref.read(habitListProvider.notifier).updateIcon(habit.id, icon.codePoint);
                    })
                : null,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: isCompleted
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF3f6a4a).withOpacity(0.15),
                          const Color(0xFF3f6a4a).withOpacity(0.08),
                        ],
                      )
                    : null,
                color: !isCompleted ? (isDark ? AppColors.darkBackground : const Color(0xFFF8F9FA)) : null,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: isEditMode
                      ? const Color(0xFF3f6a4a)
                      : (isCompleted
                          ? const Color(0xFF3f6a4a).withOpacity(0.3)
                          : (isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB))),
                  width: isEditMode ? 2 : 1.5,
                ),
                boxShadow: isCompleted ? [
                  BoxShadow(
                    color: const Color(0xFF3f6a4a).withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      habit.iconCodePoint != null 
                          ? IconData(habit.iconCodePoint!, fontFamily: 'MaterialIcons')
                          : _getHabitIcon(habit.name),
                      color: isCompleted
                          ? const Color(0xFF3f6a4a)
                          : (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF)),
                      size: 28,
                    ),
                  ),
                  if (isEditMode)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3f6a4a),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 8,
                        ),
                      ),
                    ),
                ],
              ),
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
                        ? (isDark ? AppColors.textMuted : const Color(0xFF9CA3AF))
                        : (isDark ? AppColors.textPrimary : const Color(0xFF1F2937)),
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
                              : (isDark ? AppColors.darkDivider : const Color(0xFFD1D5DB)),
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
          if (isEditMode) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showRenameDialog(habit),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3f6a4a).withOpacity(0.1),
                  border: Border.all(
                    color: const Color(0xFF3f6a4a),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFF3f6a4a),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          'Delete Habit',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to delete "${habit.name}"? This will remove all completion history.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(habitListProvider.notifier).deleteHabit(habit.id);
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text(
                              'Delete',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.remove,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
          ] else
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

  void _showCreateHabitSheet(BuildContext context) {
    final controller = TextEditingController();
    IconData selectedIcon = Icons.check_circle_outline;
    String? errorMessage;
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
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
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Habit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _showIconPicker(context, (icon) {
                      setState(() => selectedIcon = icon);
                    }),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF3f6a4a).withOpacity(0.12),
                            const Color(0xFF3f6a4a).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3f6a4a).withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3f6a4a).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              selectedIcon,
                              color: const Color(0xFF3f6a4a),
                              size: 28,
                            ),
                          ),
                          Positioned(
                            right: 3,
                            bottom: 3,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3f6a4a),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        maxLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Habit name',
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                          ),
                          floatingLabelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondary : const Color(0xFF3f6a4a),
                          ),
                          hintText: 'e.g., Meditate 10 mins',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: isDark ? AppColors.textMuted : const Color(0xFF9CA3AF),
                          ),
                          errorText: errorMessage,
                          errorStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFFEF4444),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF3f6a4a),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 1.5,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            errorMessage = null;
                          });
                        },
                        onSubmitted: (v) {
                          if (v.trim().isEmpty) {
                            setState(() => errorMessage = 'Please enter a habit name.');
                            return;
                          }
                          ref.read(habitListProvider.notifier).addHabit(v.trim(), iconCodePoint: selectedIcon.codePoint);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
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
                        color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) {
                        setState(() => errorMessage = 'Please enter a habit name.');
                        return;
                      }
                      ref
                          .read(habitListProvider.notifier)
                          .addHabit(controller.text.trim(), iconCodePoint: selectedIcon.codePoint);
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
          );
          },
        ),
      ),
    );
  }

  void _showIconPicker(BuildContext context, Function(IconData) onIconSelected) {
    final icons = [
      Icons.check_circle_outline,
      Icons.fitness_center,
      Icons.self_improvement,
      Icons.menu_book,
      Icons.water_drop,
      Icons.local_drink,
      Icons.restaurant,
      Icons.bedtime,
      Icons.wb_sunny,
      Icons.directions_run,
      Icons.directions_walk,
      Icons.directions_bike,
      Icons.pool,
      Icons.spa,
      Icons.favorite_border,
      Icons.healing,
      Icons.psychology,
      Icons.music_note,
      Icons.brush,
      Icons.edit_note,
      Icons.laptop,
      Icons.school,
      Icons.work_outline,
      Icons.home,
      Icons.cleaning_services,
      Icons.shopping_cart,
      Icons.coffee,
      Icons.local_cafe,
      Icons.phone,
      Icons.savings,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an Icon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  final icon = icons[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onIconSelected(icon);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      splashColor: const Color(0xFF3f6a4a).withOpacity(0.2),
                      highlightColor: const Color(0xFF3f6a4a).withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF3f6a4a).withOpacity(0.12),
                              const Color(0xFF3f6a4a).withOpacity(0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF3f6a4a).withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3f6a4a).withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF3f6a4a),
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(Habit habit) {
    final controller = TextEditingController(text: habit.name);
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Rename Habit',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => TextField(
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
              errorText: errorMessage,
              errorStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFFEF4444),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
            onChanged: (v) {
              setState(() {
                errorMessage = null;
              });
            },
            onSubmitted: (v) {
              if (v.trim().isEmpty) {
                setState(() => errorMessage = 'Please enter a habit name.');
                return;
              }
              ref.read(habitListProvider.notifier).renameHabit(habit.id, v.trim());
              Navigator.pop(ctx);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                return;
              }
              ref.read(habitListProvider.notifier).renameHabit(habit.id, controller.text.trim());
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF3f6a4a),
            ),
            child: Text(
              'Rename',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
