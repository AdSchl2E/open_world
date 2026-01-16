import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/explored_area.dart';
import '../widgets/fog_of_war_painter.dart';
import '../widgets/exploration_progress_indicator.dart';
import '../widgets/center_map_button.dart';

// Map view with Google Maps and fog of war overlay
class MapView extends StatelessWidget {
  final Position? currentPosition;
  final List<ExploredArea> exploredAreas;
  final double explorationPercentage;
  final bool isDarkFog;
  final Function(GoogleMapController) onMapCreated;
  final Function(CameraPosition) onCameraMove;
  final Function() onCenterPressed;
  final LatLng mapCenter;
  final double mapZoom;
  final double currentRadius;
  final bool waitingForGps;
  final String? gpsErrorMessage;

  const MapView({
    super.key,
    required this.currentPosition,
    required this.exploredAreas,
    required this.explorationPercentage,
    required this.isDarkFog,
    required this.onMapCreated,
    required this.onCameraMove,
    required this.onCenterPressed,
    required this.mapCenter,
    required this.mapZoom,
    this.currentRadius = 20.0,
    this.waitingForGps = false,
    this.gpsErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Determine initial position: current > last explored > Paris default
    LatLng initialTarget;
    if (currentPosition != null) {
      initialTarget = LatLng(currentPosition!.latitude, currentPosition!.longitude);
    } else if (exploredAreas.isNotEmpty) {
      final lastArea = exploredAreas.last;
      initialTarget = LatLng(lastArea.latitude, lastArea.longitude);
    } else {
      initialTarget = const LatLng(48.8566, 2.3522); // Paris default
    }
    
    return Stack(
      children: [
        // Google Maps
        GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 17.0, // Higher zoom for smaller default radius (20m)
            bearing: 0.0, // Fixed orientation to north
          ),
          onCameraMove: onCameraMove,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          rotateGesturesEnabled: false, // Disable rotation
          tiltGesturesEnabled: false,   // Disable tilt
        ),

        // Fog of war overlay
        Positioned.fill(
          child: IgnorePointer(
            child: FogOfWarOverlay(
              exploredAreas: exploredAreas,
              isDarkTheme: isDarkFog,
              playerPosition: currentPosition,
              currentRadius: currentRadius,
              mapZoom: mapZoom,
              mapCenter: mapCenter,
            ),
          ),
        ),

        // Center button
        Positioned(
          top: 60,
          right: 16,
          child: CenterMapButton(
            onPressed: onCenterPressed,
            isDarkTheme: isDarkFog,
          ),
        ),

        // Progress indicator
        Positioned(
          top: 60,
          left: 16,
          child: ExplorationProgressIndicator(
            explorationPercentage: explorationPercentage,
            isDarkTheme: isDarkFog,
          ),
        ),
        
        // GPS waiting indicator
        if (waitingForGps)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkFog ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkFog ? Colors.orange : Colors.orange[700]!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'GPS unavailable',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkFog ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        if (gpsErrorMessage != null)
                          Text(
                            gpsErrorMessage!,
                            style: TextStyle(
                              color: isDarkFog ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.location_off,
                    color: Colors.orange,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
