import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/explored_area.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<bool> checkPermissions({bool requestIfNeeded = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (requestIfNeeded) {
        // Only request permission if we're in foreground (has UI)
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      } else {
        // Background mode: can't request, just return false
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting position: $e');
      return null;
    }
  }

  // Get the current zone radius preference
  Future<double> getCurrentRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('zone_radius') ?? ExploredArea.defaultRadius;
  }

  // Calculate appropriate distance filter based on radius
  // (half the radius to ensure good coverage)
  int _calculateDistanceFilter(double radius) {
    return (radius / 2).clamp(5, 100).toInt();
  }

  Stream<Position> getPositionStream({double? radius}) {
    // Use provided radius or default
    final effectiveRadius = radius ?? ExploredArea.defaultRadius;
    final distanceFilter = _calculateDistanceFilter(effectiveRadius);
    
    print('📍 Position stream: radius=${effectiveRadius}m, distanceFilter=${distanceFilter}m');
    
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        // No timeLimit: tracking continu sans timeout
      ),
    );
  }

  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
