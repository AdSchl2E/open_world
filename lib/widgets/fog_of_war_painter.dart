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
    // Utiliser saveLayer pour gérer correctement la transparence
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Fond sombre ou blanc sur toute la surface
    final fogPaint = Paint()
      ..color = isDarkTheme 
          ? Colors.black.withOpacity(0.7)
          : Colors.white.withOpacity(0.7);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);

    // Paint pour les cercles transparents (révèle la carte)
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.fill;

    // Dessiner les cercles pour les zones explorées
    for (final area in exploredAreas) {
      final areaLatLng = LatLng(area.latitude, area.longitude);
      final point = _latLngToScreenPoint(areaLatLng, mapCenter, mapZoom, size);
      final radiusPixels = _metersToPixels(displayRadius, area.latitude, mapZoom);
      
      canvas.drawCircle(
        Offset(point.dx, point.dy),
        radiusPixels,
        clearPaint,
      );
    }

    // Dessiner le cercle pour la position actuelle
    if (playerPosition != null) {
      final playerLatLng = LatLng(playerPosition!.latitude, playerPosition!.longitude);
      final point = _latLngToScreenPoint(playerLatLng, mapCenter, mapZoom, size);
      final radiusPixels = _metersToPixels(displayRadius, playerPosition!.latitude, mapZoom);
      
      canvas.drawCircle(
        Offset(point.dx, point.dy),
        radiusPixels,
        clearPaint,
      );
    }
    
    canvas.restore();
  }

  Offset _latLngToScreenPoint(LatLng position, LatLng center, double zoom, Size size) {
    // Utiliser la projection Web Mercator (EPSG:3857)
    const double worldSize = 256.0;
    final double scale = worldSize * math.pow(2, zoom);
    
    // Convertir les coordonnées géographiques en coordonnées de pixels Web Mercator
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
    return exploredAreas.length != oldDelegate.exploredAreas.length ||
           isDarkTheme != oldDelegate.isDarkTheme ||
           playerPosition != oldDelegate.playerPosition ||
           displayRadius != oldDelegate.displayRadius ||
           mapZoom != oldDelegate.mapZoom ||
           mapCenter != oldDelegate.mapCenter;
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
