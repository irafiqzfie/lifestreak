import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/session_storage.dart';

const _friendSummaryPrefix = 'friend_summary_';

class FriendSyncService {
  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  FriendSyncService(this._apiClient, this._sessionStorage);

  Future<void> syncFriendSummaries() async {
    final session = await _sessionStorage.read();
    if (session == null) return;

    try {
      final summaries = await _apiClient.fetchFriendSummaries(
        token: session.token,
      );
      final prefs = await SharedPreferences.getInstance();

      final currentFriendIds = summaries
          .map((s) => s['userId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      final existingKeys = prefs
          .getKeys()
          .where((key) => key.startsWith(_friendSummaryPrefix))
          .toList();

      for (final key in existingKeys) {
        final userId = key.substring(_friendSummaryPrefix.length);
        if (!currentFriendIds.contains(userId)) {
          await prefs.remove(key);
        }
      }

      for (final summary in summaries) {
        final userId = summary['userId'] as String?;
        if (userId == null) continue;
        final key = '$_friendSummaryPrefix$userId';
        await prefs.setString(key, jsonEncode(summary));
      }

      debugPrint(
        'Friend sync: ${summaries.length} friends cached, ${existingKeys.length - currentFriendIds.length} evicted',
      );
    } catch (error, stack) {
      debugPrint('Friend sync failed: $error');
      debugPrint(stack.toString());
    }
  }
}
