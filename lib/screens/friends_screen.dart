import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/heatmap_logic.dart';
import '../providers/auth_provider.dart';
import '../services/friend_sync_service.dart';

const _friendSummaryPrefix = 'friend_summary_';

enum FriendRelationship {
  none,
  pendingSent,
  pendingReceived,
  accepted,
  blocked,
}

class FriendSummary {
  final String userId;
  final String displayName;
  final Map<String, int> heatmap;
  final int currentStreak;
  final String? lastSyncedAt;
  final FriendRelationship relationship;

  const FriendSummary({
    required this.userId,
    required this.displayName,
    required this.heatmap,
    required this.currentStreak,
    this.lastSyncedAt,
    this.relationship = FriendRelationship.accepted,
  });

  factory FriendSummary.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'];
    final displayName = json['displayName'];
    if (userId is! String || displayName is! String) {
      throw FormatException('Missing friend identity');
    }

    final heatmapRaw = json['heatmap'];
    final heatmap = <String, int>{};
    if (heatmapRaw is Map) {
      heatmapRaw.forEach((key, value) {
        if (key is String && value is num) {
          heatmap[key] = value.toInt();
        }
      });
    }

    final streakValue = json['currentStreak'];
    final currentStreak = streakValue is num ? streakValue.toInt() : 0;

    final relationshipStr = json['relationship'] as String?;
    final relationship = switch (relationshipStr) {
      'pending_sent' => FriendRelationship.pendingSent,
      'pending_received' => FriendRelationship.pendingReceived,
      'accepted' => FriendRelationship.accepted,
      'blocked' => FriendRelationship.blocked,
      _ => FriendRelationship.none,
    };

    return FriendSummary(
      userId: userId,
      displayName: displayName,
      heatmap: heatmap,
      currentStreak: currentStreak,
      lastSyncedAt: json['lastSyncedAt'] as String?,
      relationship: relationship,
    );
  }
}

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  late final Future<List<FriendSummary>> _friendsFuture;
  final _emailController = TextEditingController();
  String? _requestError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _loadFriends();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<List<FriendSummary>> _loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (key) => key.startsWith(_friendSummaryPrefix),
    );
    final summaries = <FriendSummary>[];

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          summaries.add(FriendSummary.fromJson(parsed));
        }
      } catch (_) {
        // ignore corrupt entries
      }
    }

    summaries.sort((a, b) => a.displayName.compareTo(b.displayName));
    return summaries;
  }

  Future<void> _sendFriendRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _sending = true;
      _requestError = null;
    });

    try {
      final session = ref.read(authProvider).session;
      if (session == null) {
        setState(() => _requestError = 'Not authenticated');
        return;
      }

      final apiClient = ref.read(apiClientProvider);
      await apiClient.sendFriendRequest(email, token: session.token);

      if (mounted) {
        setState(() {
          _emailController.clear();
          _requestError = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _requestError = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _acceptFriend(String userId) async {
    try {
      final session = ref.read(authProvider).session;
      if (session == null) return;

      final apiClient = ref.read(apiClientProvider);
      await apiClient.acceptFriendRequest(userId, token: session.token);

      final friendSyncService = ref.read(friendSyncServiceProvider);
      await friendSyncService.syncFriendSummaries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted')),
        );
        setState(() {
          _friendsFuture = _loadFriends();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
      }
    }
  }

  Future<void> _rejectFriend(String userId) async {
    try {
      final session = ref.read(authProvider).session;
      if (session == null) return;

      final apiClient = ref.read(apiClientProvider);
      await apiClient.rejectFriendRequest(userId, token: session.token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_friendSummaryPrefix}$userId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request rejected')),
        );
        setState(() {
          _friendsFuture = _loadFriends();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to reject: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Friend email',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_sending,
                        onSubmitted: (_) => _sendFriendRequest(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending ? null : _sendFriendRequest,
                      child: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
                if (_requestError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _requestError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<FriendSummary>>(
              future: _friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load friends',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check your connection or try signing out and back in.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final friends = snapshot.data ?? [];
                if (friends.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No friends yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add friends to compare streak progress.\nYour habit data stays private—friends only see summaries.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: friends.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _buildFriendTile(friend);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(FriendSummary friend) {
    final relationshipLabel = switch (friend.relationship) {
      FriendRelationship.pendingSent => 'Pending (sent)',
      FriendRelationship.pendingReceived => 'Pending (received)',
      FriendRelationship.blocked => 'Blocked',
      _ => null,
    };

    return ListTile(
      title: Row(
        children: [
          Text(
            friend.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (relationshipLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                relationshipLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text('${friend.currentStreak} day streak'),
      trailing: friend.relationship == FriendRelationship.pendingReceived
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _rejectFriend(friend.userId),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => _acceptFriend(friend.userId),
                  child: const Text('Accept'),
                ),
              ],
            )
          : (friend.relationship == FriendRelationship.accepted
                ? const Icon(Icons.chevron_right)
                : null),
      onTap: friend.relationship == FriendRelationship.accepted
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FriendComparisonScreen(friend: friend),
              ),
            )
          : null,
    );
  }
}

class FriendComparisonScreen extends StatefulWidget {
  final FriendSummary friend;

  const FriendComparisonScreen({required this.friend, super.key});

  @override
  State<FriendComparisonScreen> createState() => _FriendComparisonScreenState();
}

class _FriendComparisonScreenState extends State<FriendComparisonScreen> {
  late List<HeatmapDay> _heatmapDays;
  String _selectedRange = '90D';
  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    _heatmapDays = _buildHeatmapDays();
  }

  int get _daysToShow {
    if (_selectedRange == 'Month') {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      return lastDayOfMonth.difference(firstDayOfMonth).inDays + 1;
    }
    if (_selectedRange == 'Year') {
      return 365;
    }
    return 90;
  }

  int get weeks => (_daysToShow / 7).ceil();
  int get days => 7;
  int get totalCells => _daysToShow;

  List<HeatmapDay> _buildHeatmapDays() {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final startDate = todayNormalized.subtract(Duration(days: _daysToShow - 1));

    final result = <HeatmapDay>[];
    for (int i = 0; i < _daysToShow; i++) {
      final cellDate = startDate.add(Duration(days: i));
      final dateKey = _formatDate(cellDate);
      final count = widget.friend.heatmap[dateKey] ?? 0;
      final intensity = count > 3 ? 3 : count;
      result.add(HeatmapDay(date: cellDate, intensity: intensity));
    }

    return result;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _colorForIntensity(int intensity, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (intensity == 0) {
      return isDark
          ? Colors.grey.shade800
          : Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(0xEE);
    }
    if (intensity == 1) {
      return isDark ? Colors.green.shade800 : Colors.green.shade200;
    }
    if (intensity == 2) {
      return isDark ? Colors.green.shade600 : Colors.green.shade400;
    }
    return isDark ? Colors.green.shade400 : Colors.green.shade700;
  }

  String? _formatSyncedAt() {
    final iso = widget.friend.lastSyncedAt;
    if (iso == null) return null;
    try {
      final parsed = DateTime.parse(iso).toLocal();
      final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
      final minute = parsed.minute.toString().padLeft(2, '0');
      final period = parsed.hour >= 12 ? 'PM' : 'AM';
      final month = parsed.month.toString().padLeft(2, '0');
      final day = parsed.day.toString().padLeft(2, '0');
      return '$month/$day/${parsed.year} $hour:$minute $period';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildMobileGrid(
    BoxConstraints constraints,
    List<HeatmapDay> heatmapDays,
  ) {
    final padding = 32.0;
    final gap = 4.0;
    final cellWidth = (constraints.maxWidth - padding - (7 - 1) * gap) / 7;
    final cellSize = cellWidth < 40.0 ? 40.0 : cellWidth;

    final weeksList = <List<HeatmapDay>>[];
    for (int i = 0; i < totalCells; i += 7) {
      final end = (i + 7 <= totalCells) ? i + 7 : totalCells;
      weeksList.add(heatmapDays.sublist(i, end));
    }
    final displayWeeks = weeksList.reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: cellSize,
          child: Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    _dayLabels[i],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: displayWeeks.length,
            itemBuilder: (ctx, wi) {
              final week = displayWeeks[wi];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: List.generate(7, (d) {
                    if (d >= week.length) {
                      return SizedBox(width: cellSize, height: cellSize);
                    }
                    final day = week[d];
                    final intensity = day.intensity;
                    final cell = Container(
                      width: cellSize,
                      height: cellSize,
                      margin: EdgeInsets.only(right: d == 6 ? 0 : gap),
                      decoration: BoxDecoration(
                        color: _colorForIntensity(intensity, context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                    return cell;
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrid(
    BoxConstraints constraints,
    List<HeatmapDay> heatmapDays,
  ) {
    final labelWidth = 48.0;
    final gap = _selectedRange == 'Year' ? 3.0 : 4.0;
    final availableWidth = constraints.maxWidth - labelWidth - 8.0;
    final cellSize = (availableWidth - (weeks - 1) * gap) / weeks;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(days, (r) {
                return SizedBox(
                  height: cellSize,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _dayLabels[r],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: availableWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(days, (r) {
                return SizedBox(
                  height: cellSize,
                  child: Row(
                    children: List.generate(weeks, (w) {
                      final index = w * days + r;
                      if (index >= totalCells) {
                        return SizedBox(width: cellSize, height: cellSize);
                      }
                      final day = heatmapDays[index];
                      final intensity = day.intensity;

                      return Padding(
                        padding: EdgeInsets.only(
                          right: w == weeks - 1 ? 0 : gap,
                        ),
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: _colorForIntensity(intensity, context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasHeatmapData = widget.friend.heatmap.isNotEmpty;
    final syncedLabel = _formatSyncedAt();
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.onSurface.withAlpha(179);
    final String rangeLabel;
    if (_selectedRange == 'Month') {
      rangeLabel = 'This month';
    } else if (_selectedRange == 'Year') {
      rangeLabel = 'Last 365 days';
    } else {
      rangeLabel = 'Last 90 days';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.friend.displayName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'View only - your data stays private',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current streak: ${widget.friend.currentStreak}',
                  style: theme.textTheme.titleMedium,
                ),
                if (syncedLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Last synced $syncedLabel',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rangeLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onSurfaceColor,
                  ),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '90D', label: Text('90D')),
                    ButtonSegment(value: 'Month', label: Text('Month')),
                    ButtonSegment(value: 'Year', label: Text('Year')),
                  ],
                  selected: {_selectedRange},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedRange = selection.first;
                      _heatmapDays = _buildHeatmapDays();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: hasHeatmapData
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return isMobile
                          ? _buildMobileGrid(constraints, _heatmapDays)
                          : _buildDesktopGrid(constraints, _heatmapDays);
                    },
                  )
                : Center(
                    child: Text(
                      'No data yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
