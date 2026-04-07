import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

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
    print('🔔 [ANNOUNCEMENT_SERVICE] Notification service initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 [ANNOUNCEMENT_SERVICE] Notification tapped: ${response.payload}');
  }

  Future<void> checkAndNotifyNewAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final batch = prefs.getString('studentYear') ?? '';

      if (batch.isEmpty) {
        print('🔔 [ANNOUNCEMENT_SERVICE] No student batch found');
        return;
      }

      print(
        '🔔 [ANNOUNCEMENT_SERVICE] Checking announcements for batch: $batch',
      );

      final url = Uri.parse('${ApiService.baseUrl}/announcements?batch=$batch');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final announcements = data
            .map((json) => _parseAnnouncement(json))
            .toList();

        await _processNewAnnouncements(announcements);
        print(
          '🔔 [ANNOUNCEMENT_SERVICE] Processed ${announcements.length} announcements',
        );
      } else {
        print(
          '❌ [ANNOUNCEMENT_SERVICE] Failed to fetch announcements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [ANNOUNCEMENT_SERVICE] Error checking announcements: $e');
    }
  }

  Map<String, dynamic> _parseAnnouncement(Map<String, dynamic> json) {
    return {
      'id': json['id']?.toString() ?? '',
      'title': json['title'] ?? '',
      'content': json['content'] ?? '',
      'audience': json['batch'] ?? '',
      'priority': json['priority'] ?? '',
      'facultyName': json['faculty_id'] ?? 'Unknown',
      'timestamp': json['created_at'] ?? DateTime.now().toIso8601String(),
    };
  }

  Future<void> _processNewAnnouncements(
    List<Map<String, dynamic>> announcements,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeenId = prefs.getInt('lastSeenAnnouncementId');

      print('🔔 [ANNOUNCEMENT_SERVICE] Last seen announcement ID: $lastSeenId');

      // Edge case: First app launch
      if (lastSeenId == null) {
        print('🔔 [ANNOUNCEMENT_SERVICE] First app launch - no notifications');

        // Store the highest ID as last seen without triggering notifications
        if (announcements.isNotEmpty) {
          final highestId = announcements
              .map((a) => int.tryParse(a['id']) ?? 0)
              .reduce((a, b) => a > b ? a : b);

          await prefs.setInt('lastSeenAnnouncementId', highestId);
          print(
            '🔔 [ANNOUNCEMENT_SERVICE] Set initial last seen ID to: $highestId',
          );
        }
        return;
      }

      // Identify new announcements
      final newAnnouncements = announcements.where((announcement) {
        final announcementId = int.tryParse(announcement['id']) ?? 0;
        return announcementId > lastSeenId;
      }).toList();

      print(
        '🔔 [ANNOUNCEMENT_SERVICE] Found ${newAnnouncements.length} new announcements',
      );

      // Trigger notifications for new announcements
      for (final announcement in newAnnouncements) {
        await _triggerNotification(announcement);
        print(
          '🔔 [ANNOUNCEMENT_SERVICE] Triggered notification for: ${announcement['title']}',
        );
      }

      // Update last seen announcement ID
      if (announcements.isNotEmpty) {
        final highestId = announcements
            .map((a) => int.tryParse(a['id']) ?? 0)
            .reduce((a, b) => a > b ? a : b);

        await prefs.setInt('lastSeenAnnouncementId', highestId);
        print('🔔 [ANNOUNCEMENT_SERVICE] Updated last seen ID to: $highestId');
      }
    } catch (e) {
      print('❌ [ANNOUNCEMENT_SERVICE] Error processing new announcements: $e');
    }
  }

  Future<void> _triggerNotification(Map<String, dynamic> announcement) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'announcements_channel',
        'Announcements',
        channelDescription: 'Important announcements from faculty',
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
        title: announcement['title'],
        body: announcement['content'],
        payload: announcement['id'],
        notificationDetails: notificationDetails,
      );

      print(
        '🔔 [ANNOUNCEMENT_SERVICE] Notification sent: ${announcement['title']}',
      );
    } catch (e) {
      print('❌ [ANNOUNCEMENT_SERVICE] Error sending notification: $e');
    }
  }
}
