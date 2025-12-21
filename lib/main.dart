import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth_gate.dart';
import 'screens/friends_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/habit_logger_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lifestreak',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3f6a4a),
          primary: const Color(0xFF3f6a4a),
          surface: Colors.white,
          background: const Color(0xFFF9FAF7),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF9FAF7),
      ),
      home: const AuthGate(),
      routes: {
        '/friends': (context) => const FriendsScreen(),
        '/heatmap': (context) => const HeatmapScreen(),
        '/habits': (context) => const HabitLoggerScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
