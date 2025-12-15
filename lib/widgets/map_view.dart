import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/explored_area.dart';
import '../widgets/fog_of_war_painter.dart';
import '../widgets/exploration_progress_indicator.dart';
import '../widgets/center_map_button.dart';

/// Map view with Google Maps and fog of war overlay
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
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Maps
        GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: currentPosition != null
                ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                : const LatLng(48.8566, 2.3522), // Paris default
            zoom: 14.0,
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
              displayRadius: 1000.0,
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
      ],
    );
  }
}
