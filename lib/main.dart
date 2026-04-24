import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

// Screens
import 'screens/animated_splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/admin_product_screen.dart';
import 'screens/AdminLoginScreen.dart';
import 'theme.dart';
// Providers
import 'providers/cart_provider.dart';

// 🔔 Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔔 Background message received: ${message.notification?.title}");
}

// 🔔 Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _setupNotifications() async {
  // Request permission (iOS/Android 13+)
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize local notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Show foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'order_channel',
            'Orders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    }
  });

  // 🔔 Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Save admin token (if any)
  String? token = await messaging.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('adminTokens')
        .doc('mainAdmin')
        .set({'token': token}, SetOptions(merge: true));
    print("✅ Admin FCM Token saved: $token");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    await _setupNotifications();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Duka App',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: AppColors.accent,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (ctx) => const AnimatedSplashScreen(),
          '/': (ctx) => const LandingScreen(),
          '/shop': (ctx) => HomeScreen(),
          CartScreen.routeName: (ctx) => CartScreen(),
          AdminLoginScreen.routeName: (ctx) => const AdminLoginScreen(),
          AdminProductScreen.routeName: (ctx) => const AdminProductScreen(),
        },
      ),
    );
  }
}
