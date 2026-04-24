import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AdminLoginScreen extends StatefulWidget {
  static const routeName = '/admin-login';

  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  bool _isLoading = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        message.notification?.title ?? 'New Order',
        message.notification?.body ?? 'A new order has been placed!',
      );
    });
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_order_channel',
      'New Order Notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _email)
          .where('role', isEqualTo: 'admin')
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Save admin FCM token
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('adminTokens')
              .doc('mainAdmin')
              .set({'token': token});
        }

        Navigator.of(context).pushReplacementNamed('/admin-product');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access denied: not an admin')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Gradient hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DMJK Store',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Admin Portal',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15),
                    ),
                  ],
                ),
              ),

              // Login form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sign In', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                        const SizedBox(height: 4),
                        Text('Enter your admin email to continue', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Admin Email',
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.green.shade600, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.green.shade600, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => _email = value!.trim(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Please enter email';
                            if (!value.contains('@')) return 'Invalid email format';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  onPressed: _submit,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Login to Admin Panel', style: TextStyle(fontSize: 15)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Authorized personnel only',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
