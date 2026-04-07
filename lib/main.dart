import 'package:attendance_tracker/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/announcement_service.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('🔔 [MAIN] Firebase initialized successfully');
  } catch (e) {
    print('❌ [MAIN] Firebase initialization error: $e');
    print('🔔 [MAIN] Continuing without Firebase...');
  }

  // Initialize FCM service (will skip Firebase parts if not configured)
  await FCMService().init();
  print('🔔 [MAIN] FCM service initialized');

  // Initialize announcement service for global notifications
  await AnnouncementService().initialize();

  // Check for new announcements on app start
  await AnnouncementService().checkAndNotifyNewAnnouncements();

  // Set up periodic announcement checking (every 5 minutes)
  _setupPeriodicAnnouncementCheck();

  runApp(const MyApp());
}

void _setupPeriodicAnnouncementCheck() {
  // Check for new announcements every 5 minutes
  Future.delayed(const Duration(minutes: 5), () {
    AnnouncementService().checkAndNotifyNewAnnouncements();
    _setupPeriodicAnnouncementCheck(); // Recursive call for periodic checking
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Somaiya Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      home: const AuthScreen(),
    );
  }
}
