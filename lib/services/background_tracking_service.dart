import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'background_tracking/service_configuration.dart';
import 'background_tracking/background_storage.dart';
import 'database_service.dart';
import '../models/explored_area.dart';

// Main service for GPS background tracking
// Uses Android foreground service with persistent notification
class BackgroundTrackingService {
  static final BackgroundTrackingService _instance = BackgroundTrackingService._();
  factory BackgroundTrackingService() => _instance;
  BackgroundTrackingService._();

  final ServiceConfiguration _serviceConfig = ServiceConfiguration();
  final DatabaseService _databaseService = DatabaseService();

  // Initializes the background service
  Future<void> initialize() async {
    await _serviceConfig.initialize();
    // Sync any pending positions from background
    await syncPendingPositions();
  }

  // Syncs pending positions from background to database
  Future<void> syncPendingPositions() async {
    if (await BackgroundStorage.hasPendingPositions()) {
      final pending = await BackgroundStorage.getPendingPositions();
      print('🔄 Syncing ${pending.length} background positions to database');
      
      // Get existing explored areas and current radius
      final existingAreas = await _databaseService.getAllExploredAreas();
      final prefs = await SharedPreferences.getInstance();
      final currentRadius = prefs.getDouble('zone_radius') ?? ExploredArea.defaultRadius;
      
      int added = 0;
      int skipped = 0;
      
      for (var pos in pending) {
        try {
          final lat = pos['latitude'] as double;
          final lon = pos['longitude'] as double;
          
          // Check if already covered by existing areas
          bool isAlreadyCovered = false;
          for (var area in existingAreas) {
            final distance = _calculateDistance(lat, lon, area.latitude, area.longitude);
            // Utiliser le max entre le radius de la zone existante et le nouveau
            final checkRadius = area.radius > currentRadius ? area.radius : currentRadius;
            if (distance < checkRadius * 0.5) {
              isAlreadyCovered = true;
              skipped++;
              break;
            }
          }
          
          // Add only if not already covered
          if (!isAlreadyCovered) {
            final newArea = ExploredArea(latitude: lat, longitude: lon, radius: currentRadius);
            await _databaseService.insertExploredArea(newArea);
            // Add to local list for subsequent checks
            existingAreas.add(newArea);
            added++;
          }
        } catch (e) {
          print('⚠️ Error processing position: $e');
          skipped++;
        }
      }
      
      await BackgroundStorage.clearPendingPositions();
      print('✅ Background positions synced: $added added, $skipped skipped');
    }
  }
  
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Formule de Haversine
    const double earthRadius = 6378137.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) * 
        math.cos(lat2 * math.pi / 180.0) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Starts tracking automatically if user had enabled it
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

  // Starts background tracking
  Future<void> startTracking() async {
    await _serviceConfig.startService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_active', true);
  }

  // Stops background tracking
  Future<void> stopTracking() async {
    await _serviceConfig.stopService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tracking_active', false);
  }

  // Checks if tracking is currently active
  Future<bool> isTrackingActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('tracking_active') ?? false;
  }
}
