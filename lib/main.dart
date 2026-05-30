import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(const SerralheriaProApp());
}

class SerralheriaProApp extends StatelessWidget {
  const SerralheriaProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serralheria Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}