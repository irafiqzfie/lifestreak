import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TODO: This is a local-persistence StateNotifier using SharedPreferences.
// Replace with backend integration when wiring full app.

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
          loaded = decoded.map((m) {
            final id = m['id'] as String? ?? '';
            final name = m['name'] as String? ?? '';
            final completed = _prefs?.getBool(_storageKey(id, today)) ?? false;
            return Habit(id: id, name: name, completed: completed);
          }).toList(growable: false);
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
            })
        .toList(growable: false);
    try {
      final s = const JsonEncoder().convert(simple);
      await _prefs!.setString('habit_list', s);
    } catch (_) {}
  }

  void addHabit(String name) {
    final id = 'h_${DateTime.now().millisecondsSinceEpoch}';
    final newHabit = Habit(id: id, name: name.trim(), completed: false);
    state = [...state, newHabit];
    _saveHabitList();
  }
}

final habitListProvider = StateNotifierProvider<HabitListNotifier, List<Habit>>(
  (ref) => HabitListNotifier(),
);
