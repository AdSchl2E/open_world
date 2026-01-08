import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database_service.dart';
import '../location_service.dart';
import '../../models/explored_area.dart';
import 'background_storage.dart';

/// Tracks GPS position and stores new explored areas
class PositionTracker {
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  
  List<Map<String, double>> _cachedPositions = [];
  double _currentRadius = ExploredArea.defaultRadius;

  /// Checks if GPS permissions are granted (without requesting)
  Future<bool> hasPermissions({bool requestIfNeeded = true}) async {
    return await _locationService.checkPermissions(requestIfNeeded: requestIfNeeded);
  }

  /// Loads cached positions and current radius from SharedPreferences
  Future<void> _loadCachedPositions() async {
    final prefs = await SharedPreferences.getInstance();
    _currentRadius = prefs.getDouble('zone_radius') ?? ExploredArea.defaultRadius;
    
    final keys = prefs.getKeys().where((k) => k.startsWith('cached_pos_'));
    
    _cachedPositions.clear();
    for (var key in keys) {
      final lat = prefs.getDouble('${key}_lat');
      final lon = prefs.getDouble('${key}_lon');
      if (lat != null && lon != null) {
        _cachedPositions.add({'lat': lat, 'lon': lon});
      }
    }
    print('📦 Loaded ${_cachedPositions.length} cached positions, radius: ${_currentRadius}m');
  }

  /// Starts listening to position changes and saves new areas
  StreamSubscription<Position> startTracking({
    required Function(Position) onNewArea,
    required Function(dynamic) onError,
    bool isBackgroundMode = false,
  }) {
    // Load cached positions on start
    _loadCachedPositions();

    return _locationService.getPositionStream(radius: _currentRadius).listen(
      (Position position) async {
        if (await _isNewArea(position, isBackgroundMode)) {
          if (isBackgroundMode) {
            // In background: save to SharedPreferences
            await BackgroundStorage.savePendingPosition(
              position.latitude,
              position.longitude,
            );
          } else {
            // In foreground: save directly to database with current radius
            await _databaseService.insertExploredArea(
              ExploredArea(
                latitude: position.latitude,
                longitude: position.longitude,
                radius: _currentRadius,
              ),
            );
          }
          onNewArea(position);
        }
      },
      onError: onError,
    );
  }

  /// Checks if a position represents a new exploration area
  Future<bool> _isNewArea(Position position, bool isBackgroundMode) async {
    final minDistance = _currentRadius * 0.5; // Half the radius for overlap check
    
    // Check against cached positions first (faster)
    for (var cached in _cachedPositions) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        cached['lat']!,
        cached['lon']!,
      );

      if (distance < minDistance) {
        return false;
      }
    }

    // If in foreground, also check database
    if (!isBackgroundMode) {
      try {
        final existingAreas = await _databaseService.getAllExploredAreas();
        for (var area in existingAreas) {
          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            area.latitude,
            area.longitude,
          );

          // Use the larger radius for overlap check
          final checkRadius = area.radius > _currentRadius ? area.radius : _currentRadius;
          if (distance < checkRadius * 0.5) {
            return false;
          }
        }
      } catch (e) {
        print('⚠️ Database check failed: $e');
      }
    }

    // Add to cache
    _cachedPositions.add({'lat': position.latitude, 'lon': position.longitude});
    
    // Save to SharedPreferences for persistence
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setDouble('cached_pos_${timestamp}_lat', position.latitude);
    await prefs.setDouble('cached_pos_${timestamp}_lon', position.longitude);

    return true;
  }
}
