import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:serralheria_pro/data/app_data.dart';

import 'core/app_theme.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppData.init();
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
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const MainScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
