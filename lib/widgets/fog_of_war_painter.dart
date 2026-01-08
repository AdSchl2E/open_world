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
  final double currentRadius; // Radius pour la position actuelle (nouveau zones)
  final double mapZoom;
  final LatLng mapCenter;

  FogOfWarPainter({
    required this.exploredAreas,
    this.isDarkTheme = true,
    this.playerPosition,
    this.currentRadius = 20.0, // Default pour nouvelles zones
    this.mapZoom = 14.0,
    required this.mapCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner le fog avec un effet de bords doux et nuageux
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    
    // Fond sombre sur toute la surface avec opacité
    // Mode clair: gris foncé (un peu plus clair que le mode sombre)
    final fogPaint = Paint()
      ..color = isDarkTheme 
          ? Colors.black.withOpacity(0.75)
          : const Color(0xFF3A3A3A).withOpacity(0.70); // Gris foncé
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fogPaint);

    // Définir la zone visible avec padding pour éviter de dessiner hors écran
    final visibleRect = Rect.fromLTWH(-size.width * 0.2, -size.height * 0.2, 
                                      size.width * 1.4, size.height * 1.4);
    
    // Créer la liste de toutes les zones à révéler (explorées + position actuelle)
    final List<_CircleData> circlesToDraw = [];
    
    // Calculer les seuils pour adapter la taille des zones au dézoom
    final minRadiusPixels = size.width * 0.001;
    final minRadiusPixels2 = minRadiusPixels / 5.0; // 5 fois plus petit (niveau régional)
    final minRadiusPixels3 = minRadiusPixels / 20.0; // 20 fois plus petit (niveau pays)
    final minRadiusPixels4 = minRadiusPixels / 100.0; // 100 fois plus petit (niveau continent)
    
    // Ajouter toutes les zones explorées (avec culling optimisé)
    for (final area in exploredAreas) {
      final areaLatLng = LatLng(area.latitude, area.longitude);
      final point = _latLngToScreenPoint(areaLatLng, mapCenter, mapZoom, size);
      
      // Utiliser le radius stocké dans chaque zone
      double radiusPixels = _metersToPixels(area.radius, area.latitude, mapZoom);
      
      // Adaptation de la taille selon le niveau de zoom (4 seuils)
      if (radiusPixels < minRadiusPixels4) {
        // Très très très petit (niveau continent): multiplier par 1000
        radiusPixels *= 1000.0;
      } else if (radiusPixels < minRadiusPixels3) {
        // Très très petit (niveau pays): multiplier par 200
        radiusPixels *= 200.0;
      } else if (radiusPixels < minRadiusPixels2) {
        // Très petit: multiplier par 50
        radiusPixels *= 50.0;
      } else if (radiusPixels < minRadiusPixels) {
        // Petit: multiplier par 10
        radiusPixels *= 10.0;
      }
      
      // Check si dans la zone visible (avec radius)
      if (visibleRect.inflate(radiusPixels * 1.25).contains(point)) {
        circlesToDraw.add(_CircleData(point, radiusPixels));
      }
    }

    // Ajouter la position actuelle seulement si pas déjà couverte
    if (playerPosition != null) {
      // Vérifier si la position actuelle est déjà dans une zone existante
      bool isAlreadyCovered = false;
      for (final area in exploredAreas) {
        final distance = _calculateDistance(
          playerPosition!.latitude,
          playerPosition!.longitude,
          area.latitude,
          area.longitude,
        );
        // Utiliser le radius de la zone pour la comparaison
        if (distance < area.radius * 0.5) {
          isAlreadyCovered = true;
          break;
        }
      }
      
      // Afficher uniquement si pas déjà couverte
      if (!isAlreadyCovered) {
        final playerLatLng = LatLng(playerPosition!.latitude, playerPosition!.longitude);
        final point = _latLngToScreenPoint(playerLatLng, mapCenter, mapZoom, size);
        // Utiliser currentRadius pour la position actuelle (nouvelles zones)
        double radiusPixels = _metersToPixels(currentRadius, playerPosition!.latitude, mapZoom);
        
        // Adaptation de la taille selon le niveau de zoom
        if (radiusPixels < minRadiusPixels4) {
          radiusPixels *= 1000.0;
        } else if (radiusPixels < minRadiusPixels3) {
          radiusPixels *= 200.0;
        } else if (radiusPixels < minRadiusPixels2) {
          radiusPixels *= 5.0;
        } else if (radiusPixels < minRadiusPixels) {
          radiusPixels *= 2.0;
        }
        
        circlesToDraw.add(_CircleData(point, radiusPixels));
      }
    }

    // Optimisation: réutiliser le gradient et le paint
    final gradientStops = const [0.0, 0.45, 0.60, 0.70, 0.77, 0.83, 0.88, 0.93, 0.97, 1.0];
    final gradientColors = [
      Colors.white,
      Colors.white,
      Colors.white.withOpacity(0.98),
      Colors.white.withOpacity(0.92),
      Colors.white.withOpacity(0.80),
      Colors.white.withOpacity(0.60),
      Colors.white.withOpacity(0.35),
      Colors.white.withOpacity(0.15),
      Colors.white.withOpacity(0.05),
      Colors.transparent,
    ];
    
    // Dessiner tous les cercles
    for (final circle in circlesToDraw) {
      final gradient = RadialGradient(
        colors: gradientColors,
        stops: gradientStops,
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6378137.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) * math.cos(lat2 * math.pi / 180.0) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
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
           currentRadius != oldDelegate.currentRadius ||
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
  final double currentRadius;
  final double mapZoom;
  final LatLng mapCenter;

  const FogOfWarOverlay({
    super.key,
    required this.exploredAreas,
    this.isDarkTheme = true,
    this.playerPosition,
    this.currentRadius = 20.0,
    this.mapZoom = 14.0,
    required this.mapCenter,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FogOfWarPainter(
        exploredAreas: exploredAreas,
        isDarkTheme: isDarkTheme,
        playerPosition: playerPosition,
        currentRadius: currentRadius,
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
