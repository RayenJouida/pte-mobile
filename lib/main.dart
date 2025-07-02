import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:pte_mobile/screens/admin/users_screen.dart';
import 'package:pte_mobile/screens/assistant/assistant_dashboard_screen.dart';
import 'package:pte_mobile/screens/chat/chat_screen.dart';
import 'package:pte_mobile/screens/schedule_screen.dart';
import 'package:pte_mobile/screens/settings_screen.dart';
import 'package:pte_mobile/screens/signup_screen.dart';
import 'package:pte_mobile/screens/login_screen.dart';
import 'package:pte_mobile/screens/admin_screen.dart';
import 'package:pte_mobile/screens/profile_screen.dart';
import 'package:pte_mobile/screens/validate_code_screen.dart';
import 'package:pte_mobile/screens/update_password.dart';
import 'package:pte_mobile/screens/change_password_screen.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:pte_mobile/screens/notifications_screen.dart';

import 'package:pte_mobile/providers/theme_provider.dart';
import 'package:pte_mobile/providers/notification_provider.dart';
import 'package:pte_mobile/theme/theme.dart';

import 'models/chat_message.dart'; // Make sure this path is correct

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'leave_channel',
  'Leave Notifications',
  description: 'Notifications for leave requests and updates',
  importance: Importance.high,
);

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print('Background message: ${message.notification?.title}');
  } catch (e) {
    print('Error in background message handler: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before running the app
  await Hive.initFlutter();
  Hive.registerAdapter(ChatMessageAdapter());
  await Hive.openBox<ChatMessage>('chat_history');

  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/prologic');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await notificationsPlugin.initialize(initializationSettings);

  try {
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    print('Notification channel created');
  } catch (e) {
    print('Error creating notification channel: $e');
  }

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  try {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');
    String? token = await messaging.getToken();
    print('FCM Token: $token');
  } catch (e) {
    print('Error requesting permissions or getting FCM token: $e');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    notificationsPlugin.show(
      message.messageId.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@drawable/prologic',
        ),
      ),
    );
  });

  runApp(const AppLauncher());
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    );
  }
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
        '/update-password': (context) => const UpdatePasswordScreen(),
        '/change-password': (context) => ChangePasswordScreen(),
        '/chat': (context) => ChatScreen(),
        '/feed': (context) => const FeedScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/assistant': (context) => const AssistantDashboardScreen(),
      },
      initialRoute: '/',
    );
  }
}
