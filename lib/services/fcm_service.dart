import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('🔔 [FCM] Background message received: ${message.messageId}');
  print('🔔 [FCM] Background message title: ${message.notification?.title}');
  print('🔔 [FCM] Background message body: ${message.notification?.body}');
  print('🔔 [FCM] Background message data: ${message.data}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Stream controllers for notification handling
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  // Initialize FCM
  Future<void> init() async {
    print('🔔 [FCM] Initializing Firebase Cloud Messaging...');

    try {
      // Initialize Firebase (will be skipped if not configured)
      try {
        await Firebase.initializeApp();
        _firebaseMessaging = FirebaseMessaging.instance;
        print('🔔 [FCM] Firebase initialized successfully');
      } catch (e) {
        print('❌ [FCM] Firebase initialization failed: $e');
        print('🔔 [FCM] Continuing without Firebase...');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      await _requestPermission();

      // Get token (may fail if Firebase not configured)
      try {
        await getToken();
      } catch (e) {
        print('❌ [FCM] Failed to get token: $e');
        print('🔔 [FCM] Continuing without FCM token...');
      }

      // Set up message handlers
      await _setupMessageHandlers();

      print('🔔 [FCM] FCM initialization completed');
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
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    print('🔔 [FCM] Local notifications initialized');
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    print('🔔 [FCM] Requesting notification permissions...');

    NotificationSettings settings = await _firebaseMessaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 [FCM] Permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('🔔 [FCM] Provisional permission granted');
    } else {
      print('❌ [FCM] Permission denied');
    }
  }

  // Get FCM token
  Future<String?> getToken() async {
    print('🔔 [FCM] Getting FCM token...');

    try {
      String? token = await _firebaseMessaging!.getToken();

      if (token == null || token.isEmpty) {
        print('❌ [FCM] Token is null or empty, retrying once...');
        // Retry once after a short delay
        await Future.delayed(const Duration(seconds: 2));
        token = await _firebaseMessaging!.getToken();
      }

      if (token == null || token.isEmpty) {
        print('❌ [FCM] Failed to get token after retry');
        return null;
      }

      print('🔔 [FCM] FCM Token generated successfully: $token');

      // Save token locally
      await _saveTokenLocally(token);

      // Send token to backend
      await _sendTokenToBackend(token);

      return token;
    } catch (e) {
      print('❌ [FCM] Error getting token: $e');
      print('🔔 [FCM] Token may not be available - Firebase not configured');
      return null;
    }
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

  // Send token to backend
  Future<void> _sendTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final facultyId = prefs.getString('facultyId') ?? 'FAC001';
      final facultyName = prefs.getString('facultyName') ?? 'Faculty';

      print(
        '🔔 [FCM] Sending token to backend for faculty: $facultyId ($facultyName)',
      );

      final response = await http.post(
        Uri.parse('http://13.235.16.3:5000/save-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'faculty_id': facultyId,
          'faculty_name': facultyName,
          'token': token,
        }),
      );

      print(
        '🔔 [FCM] API request payload: {"faculty_id": "$facultyId", "faculty_name": "$facultyName", "token": "$token"}',
      );
      print('🔔 [FCM] API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('🔔 [FCM] Token sent to backend successfully');
      } else {
        print(
          '❌ [FCM] Failed to send token to backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [FCM] Error sending token to backend: $e');
    }
  }

  // Set up message handlers
  Future<void> _setupMessageHandlers() async {
    print('🔔 [FCM] Setting up message handlers...');

    // Handle foreground messages
    if (_firebaseMessaging != null) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 [FCM] Foreground message received: ${message.messageId}');
        print('🔔 [FCM] Title: ${message.notification?.title}');
        print('🔔 [FCM] Body: ${message.notification?.body}');
        print('🔔 [FCM] Data: ${message.data}');

        _showLocalNotification(message);
        _messageStreamController.add(message);
      });
    }

    // Handle messages when app is opened from notification
    if (_firebaseMessaging != null) {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 [FCM] App opened from notification: ${message.messageId}');
        _handleNavigation(message);
        _messageStreamController.add(message);
      });
    }

    // Handle messages when app is terminated
    final initialMessage = await _firebaseMessaging?.getInitialMessage();
    if (initialMessage != null) {
      print(
        '🔔 [FCM] App opened from terminated state: ${initialMessage.messageId}',
      );
      _handleNavigation(initialMessage);
      _messageStreamController.add(initialMessage);
    }

    // Handle token refresh
    _firebaseMessaging?.onTokenRefresh.listen((token) {
      print('🔔 [FCM] Token refreshed: $token');
      print('🔔 [FCM] Sending refreshed token to backend...');
      _saveTokenLocally(token);
      _sendTokenToBackend(token);
    });

    // Set background message handler
    if (_firebaseMessaging != null) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    print('🔔 [FCM] Message handlers set up completed');
  }

  // Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
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
        id: message.hashCode,
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? 'You have a new notification',
        notificationDetails: platformChannelSpecifics,
        payload: jsonEncode(message.data),
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

        // Create a RemoteMessage from the payload data
        final message = RemoteMessage(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          notification: RemoteNotification(
            title: data['title'] ?? 'Notification',
            body: data['body'] ?? 'You have a new notification',
          ),
          data: data,
        );

        _handleNavigation(message);
      } catch (e) {
        print('❌ [FCM] Error parsing notification payload: $e');
      }
    }
  }

  // Handle navigation based on message
  void _handleNavigation(RemoteMessage message) {
    print('🔔 [FCM] Handling navigation for message: ${message.messageId}');

    // Extract substitution_id from data
    final substitutionId = message.data['substitution_id'];
    print('🔔 [FCM] Substitution ID: $substitutionId');

    // Navigate to substitution requests screen
    // This will be handled by the main app using the stream
    _messageStreamController.add(message);
  }

  // Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}
