import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

Future<void> seedMockFriends() async {
  final prefs = await SharedPreferences.getInstance();

  final friend1 = {
    'userId': 'mock-friend-1',
    'displayName': 'Alice',
    'currentStreak': 15,
    'relationship': 'accepted',
    'heatmap': {
      '2025-12-20': 3,
      '2025-12-19': 2,
      '2025-12-18': 3,
      '2025-12-17': 1,
      '2025-12-16': 3,
      '2025-12-15': 0,
      '2025-12-14': 2,
      '2025-12-13': 3,
      '2025-12-12': 1,
      '2025-12-11': 3,
      '2025-12-10': 2,
      '2025-12-09': 3,
      '2025-12-08': 1,
      '2025-12-07': 0,
      '2025-12-06': 2,
      '2025-12-05': 3,
      '2025-12-04': 3,
      '2025-12-03': 2,
      '2025-12-02': 1,
      '2025-12-01': 3,
    },
    'lastSyncedAt': '2025-12-20T10:30:00Z',
  };

  final friend2 = {
    'userId': 'mock-friend-2',
    'displayName': 'Bob',
    'currentStreak': 7,
    'relationship': 'pending_sent',
    'heatmap': {
      '2025-12-20': 1,
      '2025-12-19': 2,
      '2025-12-18': 0,
      '2025-12-17': 1,
      '2025-12-16': 2,
      '2025-12-15': 1,
      '2025-12-14': 3,
      '2025-12-13': 0,
      '2025-12-12': 1,
      '2025-12-11': 2,
      '2025-12-10': 0,
      '2025-12-09': 1,
      '2025-12-08': 2,
      '2025-12-07': 1,
    },
    'lastSyncedAt': '2025-12-20T09:15:00Z',
  };

  final friend3 = {
    'userId': 'mock-friend-3',
    'displayName': 'Charlie',
    'currentStreak': 30,
    'relationship': 'pending_received',
    'heatmap': {
      '2025-12-20': 5,
      '2025-12-19': 4,
      '2025-12-18': 5,
      '2025-12-17': 3,
      '2025-12-16': 5,
      '2025-12-15': 4,
      '2025-12-14': 5,
      '2025-12-13': 5,
      '2025-12-12': 3,
      '2025-12-11': 5,
      '2025-12-10': 4,
      '2025-12-09': 5,
      '2025-12-08': 5,
      '2025-12-07': 3,
      '2025-12-06': 5,
      '2025-12-05': 4,
      '2025-12-04': 5,
      '2025-12-03': 5,
      '2025-12-02': 3,
      '2025-12-01': 5,
      '2025-11-30': 4,
      '2025-11-29': 5,
      '2025-11-28': 5,
      '2025-11-27': 3,
      '2025-11-26': 5,
      '2025-11-25': 4,
      '2025-11-24': 5,
      '2025-11-23': 5,
      '2025-11-22': 4,
      '2025-11-21': 5,
    },
    'lastSyncedAt': '2025-12-20T11:45:00Z',
  };

  await prefs.setString('friend_summary_mock-friend-1', jsonEncode(friend1));
  await prefs.setString('friend_summary_mock-friend-2', jsonEncode(friend2));
  await prefs.setString('friend_summary_mock-friend-3', jsonEncode(friend3));

  print(
    '✅ Seeded 3 mock friends: Alice (15d streak), Bob (7d streak), Charlie (30d streak)',
  );
}

Future<void> clearMockFriends() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('friend_summary_mock-friend-1');
  await prefs.remove('friend_summary_mock-friend-2');
  await prefs.remove('friend_summary_mock-friend-3');
  print('🗑️  Cleared mock friends');
}
