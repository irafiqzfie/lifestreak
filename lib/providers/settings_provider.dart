import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  SettingsNotifier() : super({'startOfWeek': 'Mon'}) {
    _loadSettings();
  }

  static const _startOfWeekKey = 'start_of_week';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final startOfWeek = prefs.getString(_startOfWeekKey) ?? 'Mon';
    state = {'startOfWeek': startOfWeek};
  }

  Future<void> setStartOfWeek(String day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startOfWeekKey, day);
    state = {...state, 'startOfWeek': day};
  }

  String get startOfWeek => state['startOfWeek'] as String;
  
  // Returns the day of week offset (0 for Monday, 1 for Sunday)
  int get weekStartOffset => state['startOfWeek'] == 'Sun' ? 1 : 0;
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>(
  (ref) => SettingsNotifier(),
);
