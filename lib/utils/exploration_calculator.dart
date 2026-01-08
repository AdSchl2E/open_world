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
  /// [radius] is the radius for new zones (used for overlap calculation)
  static bool isNewArea(Position position, List<ExploredArea> exploredAreas, {double? radius}) {
    final newZoneRadius = radius ?? ExploredArea.defaultRadius;
    
    for (var area in exploredAreas) {
      double distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        area.latitude,
        area.longitude,
      );

      // Use the larger of the two radii for overlap check
      // This ensures we don't add a small zone that would be covered by a large existing zone
      final checkRadius = area.radius > newZoneRadius ? area.radius : newZoneRadius;
      
      // If the new position is less than half the check radius,
      // we consider it already explored (to avoid too much overlap)
      if (distance < checkRadius * 0.5) {
        print('! Zone already explored (distance: ${distance.toStringAsFixed(1)}m < ${(checkRadius * 0.5).toStringAsFixed(1)}m)');
        return false;
      }
    }

    return true;
  }
}
