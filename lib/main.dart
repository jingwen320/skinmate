import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/welcome_page.dart';
import 'main_wrapper.dart'; // 👈 Make sure to import this!

import 'package:timezone/data/latest.dart' as tz;
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.init();
  runApp(const SkinMateApp());
}

class SkinMateApp extends StatelessWidget {
  const SkinMateApp({super.key});

  // This function only fetches the data from the phone's storage
  Future<Map<String, dynamic>> _getInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId'),
      'seenWelcome': prefs.getBool('seenWelcome') ?? false,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinMate',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Map<String, dynamic>>(
        future: _getInitialData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final String? userId = snapshot.data?['userId'];
          final bool seenWelcome = snapshot.data?['seenWelcome'] ?? false;

          // 1. Check if logged in -> Go to Wrapper (which has the bottom bar)
          if (userId != null) {
            return MainWrapper(userId: userId); 
          }

          // 2. Check if they've seen the intro -> Go to Login
          if (seenWelcome) {
            return const LoginPage();
          }

          // 3. Brand new user -> Go to Welcome
          return const WelcomePage();
        },
      ),
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}