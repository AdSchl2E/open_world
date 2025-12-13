import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/explored_area.dart';
import 'dart:math' as math;

/// Painter simplifié : fond sombre avec cercles transparents
class FogOfWarPainter extends CustomPainter {
  final List<ExploredArea> exploredAreas;
  final bool isDarkTheme;
  final Position? playerPosition;
  final double displayRadius;
  final double mapZoom;
  final LatLng mapCenter;

  FogOfWarPainter({
    required this.exploredAreas,
    this.isDarkTheme = true,
    this.playerPosition,
    this.displayRadius = 1000.0,
    this.mapZoom = 15.0,
    required this.mapCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner le fog avec un effet de bords doux et nuageux
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Fond sombre ou blanc sur toute la surface avec opacité
    final fogPaint = Paint()
      ..color = isDarkTheme 
          ? Colors.black.withOpacity(0.75)
          : Colors.white.withOpacity(0.75);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);

    // Créer la liste de toutes les zones à révéler (explorées + position actuelle)
    final List<_CircleData> circlesToDraw = [];
    
    // Ajouter toutes les zones explorées
    for (final area in exploredAreas) {
      final areaLatLng = LatLng(area.latitude, area.longitude);
      final point = _latLngToScreenPoint(areaLatLng, mapCenter, mapZoom, size);
      final radiusPixels = _metersToPixels(displayRadius, area.latitude, mapZoom);
      circlesToDraw.add(_CircleData(point, radiusPixels));
    }

    // Ajouter la position actuelle
    if (playerPosition != null) {
      final playerLatLng = LatLng(playerPosition!.latitude, playerPosition!.longitude);
      final point = _latLngToScreenPoint(playerLatLng, mapCenter, mapZoom, size);
      final radiusPixels = _metersToPixels(displayRadius, playerPosition!.latitude, mapZoom);
      circlesToDraw.add(_CircleData(point, radiusPixels));
    }

    // Dessiner tous les cercles avec le même effet nuageux
    for (final circle in circlesToDraw) {
      final gradient = RadialGradient(
        colors: [
          Colors.white,                      // Centre complètement visible
          Colors.white,                      // Zone claire
          Colors.white.withOpacity(0.98),
          Colors.white.withOpacity(0.92),
          Colors.white.withOpacity(0.80),
          Colors.white.withOpacity(0.60),
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
          Colors.transparent,                // Bord extérieur qui se fond
        ],
        stops: const [0.0, 0.45, 0.60, 0.70, 0.77, 0.83, 0.88, 0.93, 0.97, 1.0],
      );
      
      final softPaint = Paint()
        ..shader = gradient.createShader(Rect.fromCircle(
          center: circle.center,
          radius: circle.radius * 1.25,
        ))
        ..blendMode = BlendMode.dstOut;
      
      canvas.drawCircle(circle.center, circle.radius * 1.25, softPaint);
    }
    
    canvas.restore();
  }

  Offset _latLngToScreenPoint(LatLng position, LatLng center, double zoom, Size size) {
    // Use Web Mercator projection (EPSG:3857)
    const double worldSize = 256.0;
    final double scale = worldSize * math.pow(2, zoom);
    
    // Convert geographic coordinates to Web Mercator pixel coordinates
    final double posX = (position.longitude + 180.0) / 360.0 * scale;
    final double latRad = position.latitude * math.pi / 180.0;
    final double posY = (1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * scale;
    
    final double centerX = (center.longitude + 180.0) / 360.0 * scale;
    final double centerLatRad = center.latitude * math.pi / 180.0;
    final double centerY = (1.0 - math.log(math.tan(centerLatRad) + 1.0 / math.cos(centerLatRad)) / math.pi) / 2.0 * scale;
    
    // Calculer l'offset relatif au centre de l'écran
    return Offset(
      size.width / 2.0 + (posX - centerX),
      size.height / 2.0 + (posY - centerY),
    );
  }

  double _metersToPixels(double meters, double latitude, double zoom) {
    const double earthRadius = 6378137.0;
    final latRad = latitude * math.pi / 180;
    final metersPerPixel = (2 * math.pi * earthRadius * math.cos(latRad)) / (256 * math.pow(2, zoom));
    return meters / metersPerPixel;
  }

  @override
  bool shouldRepaint(FogOfWarPainter oldDelegate) {
    // Check if position changed by comparing coordinates
    final positionChanged = playerPosition != null && oldDelegate.playerPosition != null
        ? (playerPosition!.latitude != oldDelegate.playerPosition!.latitude ||
           playerPosition!.longitude != oldDelegate.playerPosition!.longitude)
        : playerPosition != oldDelegate.playerPosition;
    
    return exploredAreas.length != oldDelegate.exploredAreas.length ||
           isDarkTheme != oldDelegate.isDarkTheme ||
           positionChanged ||
           displayRadius != oldDelegate.displayRadius ||
           mapZoom != oldDelegate.mapZoom ||
           mapCenter.latitude != oldDelegate.mapCenter.latitude ||
           mapCenter.longitude != oldDelegate.mapCenter.longitude;
  }
}

/// Widget wrapper pour le fog of war
class FogOfWarOverlay extends StatelessWidget {
  final List<ExploredArea> exploredAreas;
  final bool isDarkTheme;
  final Position? playerPosition;
  final double displayRadius;
  final double mapZoom;
  final LatLng mapCenter;

  const FogOfWarOverlay({
    super.key,
    required this.exploredAreas,
    this.isDarkTheme = true,
    this.playerPosition,
    this.displayRadius = 1000.0,
    this.mapZoom = 15.0,
    required this.mapCenter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FogOfWarPainter(
        exploredAreas: exploredAreas,
        isDarkTheme: isDarkTheme,
        playerPosition: playerPosition,
        displayRadius: displayRadius,
        mapZoom: mapZoom,
        mapCenter: mapCenter,
      ),
      child: Container(),
    );
  }
}

// Helper class to store circle data
class _CircleData {
  final Offset center;
  final double radius;
  
  _CircleData(this.center, this.radius);
}
