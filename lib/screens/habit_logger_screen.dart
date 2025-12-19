import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/habit_provider.dart';

class HabitLoggerScreen extends ConsumerStatefulWidget {
  const HabitLoggerScreen({super.key});

  @override
  ConsumerState<HabitLoggerScreen> createState() => _HabitLoggerScreenState();
}

class _HabitLoggerScreenState extends ConsumerState<HabitLoggerScreen> {
  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitListProvider);
    final total = habits.length;
    final completed = habits.where((h) => h.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lifestreak'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _formattedDate(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('X / Y completed', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text('$completed / $total', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Daily Score', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text('$completed', style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const Divider(),
              const SizedBox(height: 8),

              // Habit list or empty state
              Expanded(
                child: habits.isEmpty
                    ? Center(
                        child: Text(
                          'No habits yet',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.separated(
                      itemCount: habits.length,
                      separatorBuilder: (context, index) => const Divider(height: 0),
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return _HabitListItem(
                            id: habit.id,
                            name: habit.name,
                            completed: habit.completed,
                            onTap: () => ref.read(habitListProvider.notifier).toggle(habit.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate(DateTime d) {
    // TODO: Localize date formatting
    return '${_weekday(d.weekday)}, ${d.month}/${d.day}/${d.year}';
  }

  String _weekday(int w) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(w - 1) % 7];
  }
}

class _HabitListItem extends StatelessWidget {
  final String id;
  final String name;
  final bool completed;
  final VoidCallback onTap;

  const _HabitListItem({required this.id, required this.name, required this.completed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Theme.of(context).colorScheme.primary.withAlpha(31),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              // Visual: checkmark appears when completed
              if (completed)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                const SizedBox(width: 24, height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
