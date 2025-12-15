import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'notification_manager.dart';
import 'position_tracker.dart';

/// Handles the background service execution and lifecycle
@pragma('vm:entry-point')
class ServiceHandler {
  /// Main entry point for the background service
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('🚀 Background service started');
    DartPluginRegistrant.ensureInitialized();

    final notificationManager = NotificationManager();
    final positionTracker = PositionTracker();

    // CRITICAL: Call setForegroundNotificationInfo IMMEDIATELY (within 5 seconds)
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: 'Exploration in progress',
        content: 'Tracking your movements...',
      );
    }

    // Initialize notifications after startForeground
    await notificationManager.initialize();
    await notificationManager.createChannel();
    await notificationManager.showTrackingNotification();

    // Service running flag
    bool isRunning = true;

    // Listen for stop command
    service.on('stop').listen((event) {
      isRunning = false;
      service.stopSelf();
      print('🛑 Service stopped');
    });

    // Start tracking positions
    StreamSubscription<Position>? positionSubscription;

    try {
      positionSubscription = positionTracker.startTracking(
        onNewArea: (position) {
          print('✅ New zone (background): ${position.latitude}, ${position.longitude}');
        },
        onError: (error) {
          print('❌ GPS error: $error');
        },
        isBackgroundMode: true, // Important: running in background
      );

      // Keep service alive while running
      while (isRunning) {
        await Future.delayed(const Duration(seconds: 10));
      }
    } catch (e) {
      print('❌ Service error: $e');
    } finally {
      positionSubscription?.cancel();
      service.stopSelf();
    }
  }

  /// iOS background callback (required but not used)
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
}
