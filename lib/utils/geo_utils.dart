import 'dart:math';

/// Utility functions for geographic calculations
class GeoUtils {
  /// Calculate distance between two coordinates in meters
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - 
        (cos((lat2 - lat1) * p) / 2) +
        (cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2);
    return 12742000 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Check if two zones are close enough to be considered duplicates
  static bool areZonesDuplicate(double lat1, double lon1, double lat2, double lon2, {double threshold = 100}) {
    return calculateDistance(lat1, lon1, lat2, lon2) < threshold;
  }
}
