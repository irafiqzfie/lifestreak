import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: This is a local-persistence StateNotifier using SharedPreferences.
// Replace with backend integration when wiring full app.

class Habit {
  final String id;
  final String name;
  final bool completed;
  final int? iconCodePoint;

  const Habit({required this.id, required this.name, this.completed = false, this.iconCodePoint});

  Habit copyWith({String? id, String? name, bool? completed, int? iconCodePoint}) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      completed: completed ?? this.completed,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
    );
  }
}

class HabitListNotifier extends StateNotifier<List<Habit>> {
  SharedPreferences? _prefs;

  HabitListNotifier() : super([]) {
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    // Load persisted habit list (metadata) if present
    final habitJson = _prefs?.getString('habit_list');
    List<Habit> loaded = [];
    try {
      if (habitJson != null && habitJson.isNotEmpty) {
        // decode with dart:convert
        final decoded = _tryDecodeJsonList(habitJson);
        if (decoded != null) {
          loaded = decoded
              .map((m) {
                final id = m['id'] as String? ?? '';
                final name = m['name'] as String? ?? '';
                final iconCodePoint = m['iconCodePoint'] as int?;
                final completed =
                    _prefs?.getBool(_storageKey(id, today)) ?? false;
                return Habit(id: id, name: name, completed: completed, iconCodePoint: iconCodePoint);
              })
              .toList(growable: false);
        }
      }
    } catch (_) {
      loaded = [];
    }

    // If nothing persisted, start empty (empty state shown)
    state = loaded;
  }

  String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _storageKey(String habitId, String date) {
    return 'habit_log_${habitId}_$date';
  }

  void toggle(String id) {
    final today = _getTodayString();

    state = state
        .map((h) {
          if (h.id == id) {
            final newCompleted = !h.completed;
            // Persist immediately
            if (_prefs != null) {
              if (newCompleted) {
                _prefs!.setBool(_storageKey(id, today), true);
              } else {
                _prefs!.remove(_storageKey(id, today));
              }
            }
            return h.copyWith(completed: newCompleted);
          }
          return h;
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>>? _tryDecodeJsonList(String s) {
    try {
      // local importless decode
      final dynamic dec = const JsonDecoder().convert(s);
      if (dec is List) {
        return dec.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveHabitList() async {
    if (_prefs == null) return;
    final simple = state
        .map((h) => {
          'id': h.id,
          'name': h.name,
          if (h.iconCodePoint != null) 'iconCodePoint': h.iconCodePoint,
        })
        .toList(growable: false);
    try {
      final s = const JsonEncoder().convert(simple);
      await _prefs!.setString('habit_list', s);
    } catch (_) {}
  }

  void addHabit(String name, {int? iconCodePoint}) {
    final id = 'h_${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = Habit(id: id, name: name.trim(), completed: false, iconCodePoint: iconCodePoint);
    state = [...state, newHabit];
    _saveHabitList();
  }

  void deleteHabit(String id) {
    state = state.where((h) => h.id != id).toList(growable: false);
    _saveHabitList();
    // Also remove all completion logs for this habit
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('habit_log_$id')) {
          _prefs!.remove(key);
        }
      }
    }
  }

  void renameHabit(String id, String newName) {
    state = state
        .map((h) => h.id == id ? h.copyWith(name: newName.trim()) : h)
        .toList(growable: false);
    _saveHabitList();
  }

  void updateIcon(String id, int iconCodePoint) {
    state = state
        .map((h) => h.id == id ? h.copyWith(iconCodePoint: iconCodePoint) : h)
        .toList(growable: false);
    _saveHabitList();
  }
}

final habitListProvider = StateNotifierProvider<HabitListNotifier, List<Habit>>(
  (ref) => HabitListNotifier(),
);
