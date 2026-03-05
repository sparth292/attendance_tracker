import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  bool isRead;
  bool isExpanded;
  bool showDescription;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isExpanded = false,
    this.showDescription = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Attendance Marked',
      message: 'Your attendance for Image Processing has been marked successfully.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationItem(
      id: '2',
      title: 'New Event',
      message: 'Symposium event has been announced. Register now!',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    NotificationItem(
      id: '3',
      title: 'Assignment Reminder',
      message: 'Submit your SE assignment before tomorrow evening.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: '4',
      title: 'Timetable Update',
      message: 'Tomorrow\'s timetable has been updated. Check for changes.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationItem(
      id: '5',
      title: 'Exam Schedule',
      message: 'Mid-term exam schedule has been released.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    NotificationItem(
      id: '6',
      title: 'Holiday Notice',
      message: 'College will remain closed on upcoming Monday.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
    NotificationItem(
      id: '7',
      title: 'Fee Reminder',
      message: 'Last date for fee payment is approaching.',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      showDescription: true,
    ),
    NotificationItem(
      id: '8',
      title: 'Library Return',
      message: 'Return the issued books before due date.',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      showDescription: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Trigger animation on first click
            if (!notification.showDescription) {
              notification.showDescription = true;
            } else {
              // Toggle read state on subsequent clicks
              notification.isRead = !notification.isRead;
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.grey[400] : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              
              // Checkbox
              Checkbox(
                value: notification.isRead,
                onChanged: (bool? value) {
                  setState(() {
                    notification.isRead = value ?? false;
                  });
                },
                activeColor: const Color(0xFFE53935),
                checkColor: Colors.white,
              ),
              const SizedBox(width: 12),
              
              // Message content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Animated description container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: notification.showDescription ? 50 : 0,
                      child: notification.showDescription 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lorem ipsum dolor sit amet consectetur adipisicing elit.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTimestamp(notification.timestamp),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
