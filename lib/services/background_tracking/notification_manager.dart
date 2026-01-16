import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Manages notifications for background tracking service
class NotificationManager {
  static const String channelId = 'background_tracking';
  static const String channelName = 'Exploration in progress';
  static const int notificationId = 888;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Creates the notification channel
  Future<void> createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Notification displayed during world exploration',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Requests notification permission from user
  Future<bool> requestPermission() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      return await androidImpl.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  // Initializes notifications with icon
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@drawable/ic_notification');
    
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  // Shows persistent tracking notification
  Future<void> showTrackingNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Persistent notification during exploration',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: true,
      usesChronometer: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      icon: '@drawable/ic_notification',
    );

    await _notifications.show(
      notificationId,
      'Exploration in progress',
      'Disable in Settings > Exploration',
      const NotificationDetails(android: androidDetails),
    );
  }
}
