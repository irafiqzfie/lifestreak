import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth_gate.dart';
import 'screens/friends_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/habit_logger_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lifestreak',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AuthGate(),
      routes: {
        '/friends': (context) => const FriendsScreen(),
        '/heatmap': (context) => const HeatmapScreen(),
        '/habits': (context) => const HabitLoggerScreen(),
      },
    );
  }
}
