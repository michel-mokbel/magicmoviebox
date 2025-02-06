import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  
  NotificationService._();

  Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false, // We'll request permissions separately
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permissions
    await requestPermissions();
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    // Request permissions for iOS
    final iOS = await _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // For Android, permissions are handled through the app settings
    return await checkPermissions();
  }

  Future<bool> checkPermissions() async {
    // For iOS, check if notifications are enabled
    final iOS = await _localNotifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      // Request permissions to check if they're granted
      final result = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    // For Android, check if the notification channel is enabled
    final android = await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final areNotificationsEnabled = await android.areNotificationsEnabled();
      return areNotificationsEnabled ?? false;
    }

    return false;
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    // Handle notification tap
    if (response.payload != null) {
      // Navigate to specific screen based on payload
      print('Notification payload: ${response.payload}');
    }
  }

  Future<void> scheduleMovieReminder({
    required String movieTitle,
    required DateTime scheduledTime,
    String? movieId,
    required BuildContext context,
  }) async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      if (!context.mounted) return;
      final requestAgain = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Notifications Disabled', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Notifications are required for reminders. Would you like to enable them?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (requestAgain == true) {
        final granted = await requestPermissions();
        if (!granted) return;
      } else {
        return;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'movie_reminders',
      'Movie Reminders',
      channelDescription: 'Reminders for movies you want to watch',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      movieId.hashCode,
      'Movie Reminder',
      'Time to watch $movieTitle!',
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: movieId,
    );

    // Store reminder in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList('movie_reminders') ?? [];
    reminders.add('$movieId|$movieTitle|${scheduledTime.toIso8601String()}');
    await prefs.setStringList('movie_reminders', reminders);
  }

  Future<void> cancelMovieReminder(String movieId) async {
    await _localNotifications.cancel(movieId.hashCode);
    
    // Remove from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList('movie_reminders') ?? [];
    reminders.removeWhere((reminder) => reminder.startsWith('$movieId|'));
    await prefs.setStringList('movie_reminders', reminders);
  }

  Future<List<Map<String, dynamic>>> getScheduledReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList('movie_reminders') ?? [];
    
    return reminders.map((reminder) {
      final parts = reminder.split('|');
      return {
        'movieId': parts[0],
        'title': parts[1],
        'scheduledTime': DateTime.parse(parts[2]),
      };
    }).toList();
  }
} 