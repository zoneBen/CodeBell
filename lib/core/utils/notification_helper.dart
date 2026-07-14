import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  static FlutterLocalNotificationsPlugin? _notifications;
  static bool _initialized = false;
  static bool _isInitializing = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (_isInitializing) {
      // Wait for initialization to complete
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    try {
      _notifications = FlutterLocalNotificationsPlugin();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings();

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications!.initialize(initializationSettings);
      _initialized = true;
    } catch (e) {
      print('Failed to initialize notifications: $e');
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> showNotification(String title, String body) async {
    if (!_initialized) {
      try {
        await initialize();
      } catch (e) {
        return;
      }
    }

    if (_notifications == null) return;

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'aimsg_channel',
        'Task Notifications',
        channelDescription: 'Notifications for completed Claude Code tasks',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notifications!.show(
        DateTime.now().millisecond,
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      // Ignore notification errors
    }
  }

  static void dispose() {
    // nothing to dispose for now
  }
}
