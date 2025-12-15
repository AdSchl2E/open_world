import 'package:geolocator/geolocator.dart';
import '../models/explored_area.dart';
import '../services/location_service.dart';

/// Utility class for exploration-related calculations
class ExplorationCalculator {
  static final LocationService _locationService = LocationService();

  /// Calculate exploration percentage based on Earth's land surface
  static double calculateExplorationPercentage(int exploredAreasCount) {
    // Land surface only (29% of total surface)
    const earthSurface = 510000000000.0; // km²
    const landPercentage = 0.29;
    final landSurface = earthSurface * landPercentage;
    
    return exploredAreasCount / landSurface * 100;
  }

  /// Check if a position is in a new area (not already explored)
  static bool isNewArea(Position position, List<ExploredArea> exploredAreas) {
    for (var area in exploredAreas) {
      double distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        area.latitude,
        area.longitude,
      );

      // If the new position is less than half the radius of an existing zone,
      // we consider it already explored (to avoid too much overlap)
      if (distance < area.radius * 0.5) {
        print('! Zone already explored (distance: ${distance.toStringAsFixed(1)}m < ${(area.radius * 0.5).toStringAsFixed(1)}m)');
        return false;
      }
    }

    return true;
  }
}
