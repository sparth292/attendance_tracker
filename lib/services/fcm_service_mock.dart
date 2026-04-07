import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controllers for notification handling
  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  // Initialize FCM (mock version for testing without Firebase)
  Future<void> init() async {
    print('🔔 [FCM] Initializing FCM Service (mock mode)...');

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      print('🔔 [FCM] FCM service initialized (mock mode)');
    } catch (e) {
      print('❌ [FCM] Error initializing FCM: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    print('🔔 [FCM] Initializing local notifications...');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'substitution_requests',
      'Substitution Requests',
      description: 'Notifications for lecture substitution requests',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        ?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print('🔔 [FCM] Local notifications initialized');
  }

  // Mock method to simulate receiving notification
  void simulateNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    print('🔔 [FCM] Simulating notification: $title');

    // Show local notification
    _showLocalNotification(title, body, data);

    // Add to stream for navigation
    _messageStreamController.add(data ?? {});
  }

  // Show local notification for foreground messages
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    print('🔔 [FCM] Showing local notification...');

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'substitution_requests',
            'Substitution Requests',
            channelDescription:
                'Notifications for lecture substitution requests',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: jsonEncode(data ?? {}),
      );

      print('🔔 [FCM] Local notification shown successfully');
    } catch (e) {
      print('❌ [FCM] Error showing local notification: $e');
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('🔔 [FCM] Local notification tapped');
    print(
      '🔔 [FCM] Response type: ${notificationResponse.notificationResponseType}',
    );
    print('🔔 [FCM] Payload: ${notificationResponse.payload}');

    if (notificationResponse.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(
          notificationResponse.payload!,
        );
        print('🔔 [FCM] Parsed data: $data');

        // Add to stream for navigation
        _messageStreamController.add(data);
      } catch (e) {
        print('❌ [FCM] Error parsing notification payload: $e');
      }
    }
  }

  // Mock token method
  Future<String?> getToken() async {
    print('🔔 [FCM] Getting mock FCM token...');

    // Return a mock token for testing
    const mockToken = 'mock_fcm_token_for_testing';
    print('🔔 [FCM] Mock FCM Token: $mockToken');

    // Save token locally
    await _saveTokenLocally(mockToken);

    return mockToken;
  }

  // Save token locally
  Future<void> _saveTokenLocally(String? token) async {
    if (token != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
        print('🔔 [FCM] Token saved locally');
      } catch (e) {
        print('❌ [FCM] Error saving token locally: $e');
      }
    }
  }

  // Send token to backend (mock)
  Future<void> _sendTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';

      print('🔔 [FCM] Would send token to backend for faculty: $facultyId');
      print('🔔 [FCM] Token: $token');

      // Uncomment when Firebase is configured
      // final response = await http.post(
      //   Uri.parse('http://13.235.16.3:5000/api/save-token'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'faculty_id': facultyId,
      //     'token': token,
      //   }),
      // );

      // if (response.statusCode == 200) {
      //   print('🔔 [FCM] Token sent to backend successfully');
      // } else {
      //   print('❌ [FCM] Failed to send token to backend: ${response.statusCode}');
      // }
    } catch (e) {
      print('❌ [FCM] Error sending token to backend: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}
