import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class SubstitutionNotificationService {
  static final SubstitutionNotificationService _instance = 
      SubstitutionNotificationService._internal();
  factory SubstitutionNotificationService() => _instance;
  SubstitutionNotificationService._internal();

  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Service initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Notification tapped: ${response.payload}');
  }

  Future<void> checkAndNotifyNewSubstitutionNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final batch = prefs.getString('studentYear') ?? '';

      if (batch.isEmpty) {
        print('🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] No student batch found');
        return;
      }

      print(
        '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Checking substitution notifications for batch: $batch',
      );

      final url = Uri.parse('${ApiService.baseUrl}/substitution/notifications?batch=$batch');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notifications = data['substitution_notifications'] ?? [];
        
        final substitutionNotifications = notifications
            .map((json) => _parseSubstitutionNotification(json))
            .toList();

        await _processNewSubstitutionNotifications(substitutionNotifications);
        print(
          '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Processed ${substitutionNotifications.length} substitution notifications',
        );
      } else {
        print(
          '❌ [SUBSTITUTION_NOTIFICATION_SERVICE] Failed to fetch substitution notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [SUBSTITUTION_NOTIFICATION_SERVICE] Error checking substitution notifications: $e');
    }
  }

  Map<String, dynamic> _parseSubstitutionNotification(Map<String, dynamic> json) {
    return {
      'id': json['id']?.toString() ?? '',
      'original_faculty_id': json['original_faculty_id'] ?? '',
      'original_faculty_name': json['original_faculty_name'] ?? '',
      'substitute_faculty_id': json['substitute_faculty_id'] ?? '',
      'substitute_faculty_name': json['substitute_faculty_name'] ?? '',
      'course_name': json['course_name'] ?? '',
      'batch': json['batch'] ?? '',
      'date': json['date'] ?? '',
      'start_time': json['start_time'] ?? '',
      'end_time': json['end_time'] ?? '',
      'room_no': json['room_no'] ?? '',
      'timestamp': json['created_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  Future<void> _processNewSubstitutionNotifications(
    List<Map<String, dynamic>> substitutionNotifications,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenId = prefs.getInt('lastSeenSubstitutionNotificationId');

      print(
        '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Last seen substitution notification ID: $lastSeenId',
      );

      // Edge case: First app launch
      if (lastSeenId == null) {
        print('🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] First app launch - no notifications');
        
        // Store the highest ID as last seen without triggering notifications
        if (substitutionNotifications.isNotEmpty) {
          final highestId = substitutionNotifications
              .map((n) => int.tryParse(n['id']) ?? 0)
              .reduce((a, b) => a > b ? a : b);

          await prefs.setInt('lastSeenSubstitutionNotificationId', highestId);
          print(
            '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Set initial last seen substitution notification ID to: $highestId',
          );
        }
        return;
      }

      // Identify new substitution notifications
      final newSubstitutionNotifications = substitutionNotifications.where((notification) {
        final notificationId = int.tryParse(notification['id']) ?? 0;
        return notificationId > lastSeenId;
      }).toList();

      print(
        '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Found ${newSubstitutionNotifications.length} new substitution notifications',
      );

      // Trigger notifications for new substitution notifications
      for (final notification in newSubstitutionNotifications) {
        await _triggerSubstitutionNotification(notification);
        print(
          '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Triggered notification for: ${notification['course_name']}',
        );
      }

      // Update last seen substitution notification ID
      if (substitutionNotifications.isNotEmpty) {
        final highestId = substitutionNotifications
            .map((n) => int.tryParse(n['id']) ?? 0)
            .reduce((a, b) => a > b ? a : b);

        await prefs.setInt('lastSeenSubstitutionNotificationId', highestId);
        print(
          '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Updated last seen substitution notification ID to: $highestId',
        );
      }
    } catch (e) {
      print('❌ [SUBSTITUTION_NOTIFICATION_SERVICE] Error processing substitution notifications: $e');
    }
  }

  Future<void> _triggerSubstitutionNotification(
      Map<String, dynamic> substitutionNotification) async {
    try {
      final originalFaculty = substitutionNotification['original_faculty_name'] ?? 'Unknown Faculty';
      final substituteFaculty = substitutionNotification['substitute_faculty_name'] ?? 'Unknown Faculty';
      final courseName = substitutionNotification['course_name'] ?? 'Unknown Course';
      final batch = substitutionNotification['batch'] ?? '';
      final date = substitutionNotification['date'] ?? '';
      final startTime = substitutionNotification['start_time'] ?? '';
      final endTime = substitutionNotification['end_time'] ?? '';
      final roomNo = substitutionNotification['room_no'] ?? '';

      final notificationTitle = 'Faculty Changed - $courseName';
      final notificationBody = '$originalFaculty → $substituteFaculty\nBatch: $batch | Date: $date\nTime: $startTime - $endTime | Room: $roomNo';

      const androidDetails = AndroidNotificationDetails(
        'substitution_notifications_channel',
        'Substitution Notifications',
        channelDescription: 'Faculty substitution notifications for your batch',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: notificationTitle,
        body: notificationBody,
        payload: substitutionNotification['id'],
        notificationDetails: notificationDetails,
      );

      print(
        '🔔 [SUBSTITUTION_NOTIFICATION_SERVICE] Substitution notification sent: $notificationTitle',
      );
    } catch (e) {
      print('❌ [SUBSTITUTION_NOTIFICATION_SERVICE] Error sending substitution notification: $e');
    }
  }
}
