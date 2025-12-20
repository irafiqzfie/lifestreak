import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/session_storage.dart';

class SyncService {
  static const _logPrefix = 'habit_log_';
  static const _syncedSuffix = '_synced_at';

  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  SyncService(this._apiClient, this._sessionStorage);

  Future<void> syncHabitLogs() async {
    final session = await _sessionStorage.read();
    if (session == null) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final logs = <Map<String, dynamic>>[];
    final keysToMark = <String>[];

    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_logPrefix)) continue;
      final tail = key.substring(_logPrefix.length);
      final splitIndex = tail.lastIndexOf('_');
      if (splitIndex <= 0) continue;
      final habitId = tail.substring(0, splitIndex);
      final date = tail.substring(splitIndex + 1);
      logs.add({
        'habitId': habitId,
        'date': date,
        'completed': true,
        'syncedAt': now.toIso8601String(),
      });
      keysToMark.add(key);
    }

    if (logs.isEmpty) return;

    await _apiClient.syncLogs(logs, token: session.token);

    final syncedAtValue = now.toIso8601String();
    for (final key in keysToMark) {
      await prefs.setString('$key$_syncedSuffix', syncedAtValue);
    }
  }
}
