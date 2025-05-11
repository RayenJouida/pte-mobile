import 'package:flutter/material.dart';
import 'package:pte_mobile/screens/assistant/assistant_dashboard_screen.dart';
import 'package:pte_mobile/screens/chat/chat_screen.dart';
import 'package:pte_mobile/screens/schedule_screen.dart';
import 'package:pte_mobile/screens/settings_screen.dart';
import 'package:pte_mobile/screens/signup_screen.dart';
import 'package:pte_mobile/screens/login_screen.dart';
import 'package:pte_mobile/screens/admin_screen.dart';
import 'package:pte_mobile/screens/profile_screen.dart';
import 'package:pte_mobile/screens/validate_code_screen.dart';
import 'package:pte_mobile/screens/update_password.dart'; // Updated import
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:provider/provider.dart';
import 'package:pte_mobile/providers/theme_provider.dart';
import 'package:pte_mobile/providers/notification_provider.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:pte_mobile/screens/admin/users_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);

    return MaterialApp(
      title: 'PTE Mobile',
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: themeProvider.themeMode,
      routes: {
        '/': (context) => LoginScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/admin': (context) => AdminScreen(),
        '/users': (context) => UsersScreen(),
        '/schedule': (context) => ScheduleScreen(),
        '/settings': (context) => SettingsScreen(),
        '/profile': (context) => ProfileScreen(),
        '/validate-code': (context) => ValidateCodeScreen(),
        '/update-password': (context) => const UpdatePasswordScreen(), // New route
        '/chat': (context) => ChatScreen(),
        '/feed': (context) => const FeedScreen(),
      },
      initialRoute: '/',
    );
  }
}