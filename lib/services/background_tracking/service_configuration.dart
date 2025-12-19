import 'package:flutter_background_service/flutter_background_service.dart';
import 'notification_manager.dart';
import 'service_handler.dart';

/// Configures and manages the background service lifecycle
class ServiceConfiguration {
  final NotificationManager _notificationManager = NotificationManager();

  bool _isConfigured = false;

  /// Initializes notification channel (lightweight, no service start)
  Future<void> initialize() async {
    // Only create notification channel, don't configure service yet
    await _notificationManager.createChannel();
  }

  /// Configures the background service (call this before first start)
  Future<void> _ensureConfigured() async {
    if (_isConfigured) return;

    // Initialize flutter_local_notifications in main isolate BEFORE starting service
    await _notificationManager.initialize();

    final service = FlutterBackgroundService();

    // Configure background service
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: ServiceHandler.onStart,
        onBackground: ServiceHandler.onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: ServiceHandler.onStart,
        isForegroundMode: true,
        autoStart: false, // Don't auto-start, we control when to start
        autoStartOnBoot: false, // Will be started by app if needed
        initialNotificationTitle: 'Exploration in progress',
        initialNotificationContent: 'Tracking your exploration',
        foregroundServiceNotificationId: NotificationManager.notificationId,
      ),
    );

    _isConfigured = true;
  }

  /// Starts the background tracking service
  Future<void> startService() async {
    if (await _notificationManager.requestPermission()) {
      // Ensure service is configured before starting
      await _ensureConfigured();
      await FlutterBackgroundService().startService();
    } else {
      throw Exception('Notification permission required');
    }
  }

  /// Stops the background tracking service
  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    // Use sendData instead of invoke to avoid UI isolate error
    service.invoke('stop');
  }
}
