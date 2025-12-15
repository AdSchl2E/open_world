import 'package:shared_preferences/shared_preferences.dart';
import 'background_tracking/service_configuration.dart';
import 'background_tracking/background_storage.dart';
import 'database_service.dart';
import '../models/explored_area.dart';

/// Main service for GPS background tracking
/// Uses Android foreground service with persistent notification
class BackgroundTrackingService {
  static final BackgroundTrackingService _instance = BackgroundTrackingService._();
  factory BackgroundTrackingService() => _instance;
  BackgroundTrackingService._();

  final ServiceConfiguration _serviceConfig = ServiceConfiguration();
  final DatabaseService _databaseService = DatabaseService();

  /// Initializes the background service
  Future<void> initialize() async {
    await _serviceConfig.initialize();
    // Sync any pending positions from background
    await syncPendingPositions();
  }

  /// Syncs pending positions from background to database
  Future<void> syncPendingPositions() async {
    if (await BackgroundStorage.hasPendingPositions()) {
      final pending = await BackgroundStorage.getPendingPositions();
      print('🔄 Syncing ${pending.length} background positions to database');
      
      for (var pos in pending) {
        try {
          await _databaseService.insertExploredArea(
            ExploredArea(
              latitude: pos['latitude'] as double,
              longitude: pos['longitude'] as double,
            ),
          );
        } catch (e) {
          print('⚠️ Error syncing position: $e');
        }
      }
      
      await BackgroundStorage.clearPendingPositions();
      print('✅ Background positions synced');
    }
  }

  /// Starts tracking automatically if user had enabled it
  Future<void> startTrackingIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('background_tracking_enabled') ?? true;
    
    if (isEnabled) {
      try {
        await startTracking();
        // Save that tracking is active
        await prefs.setBool('tracking_active', true);
        print('✅ Tracking started automatically');
      } catch (e) {
        print('⚠️ Automatic start error: $e');
        await prefs.setBool('tracking_active', false);
      }
    }
  }

  /// Starts background tracking
  Future<void> startTracking() async {
    await _serviceConfig.startService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_active', true);
  }

  /// Stops background tracking
  Future<void> stopTracking() async {
    await _serviceConfig.stopService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_active', false);
  }

  /// Checks if tracking is currently active
  Future<bool> isTrackingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tracking_active') ?? false;
  }
}
