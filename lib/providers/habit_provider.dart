import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: This is an in-memory UI-only StateNotifier. Replace with persistent
// state / backend integration when wiring full app.

class Habit {
  final String id;
  final String name;
  final bool completed;

  const Habit({required this.id, required this.name, this.completed = false});

  Habit copyWith({String? id, String? name, bool? completed}) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      completed: completed ?? this.completed,
    );
  }
}

class HabitListNotifier extends StateNotifier<List<Habit>> {
  HabitListNotifier()
      : super(const [
          Habit(id: 'h1', name: 'Morning stretch'),
          Habit(id: 'h2', name: 'Read 15 minutes'),
          Habit(id: 'h3', name: 'Drink water'),
        ]);

  void toggle(String id) {
    state = state
        .map((h) => h.id == id ? h.copyWith(completed: !h.completed) : h)
        .toList(growable: false);
    // TODO: Emit analytics or persist change when integrating backend.
  }
}

final habitListProvider = StateNotifierProvider<HabitListNotifier, List<Habit>>(
  (ref) => HabitListNotifier(),
);
