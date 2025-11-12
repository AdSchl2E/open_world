import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/explored_area.dart';
import 'dart:math' as math;

/// Générateur de bruit de Perlin simplifié pour texture de nuages
class NoiseGenerator {
  final int seed;
  final List<List<double>> _permutation = [];
  static const int size = 256;

  NoiseGenerator(this.seed) {
    final random = math.Random(seed);
    for (int i = 0; i < size; i++) {
      _permutation.add([]);
      for (int j = 0; j < size; j++) {
        _permutation[i].add(random.nextDouble());
      }
    }
  }

  double noise(double x, double y) {
    final xi = x.floor() % size;
    final yi = y.floor() % size;
    final xf = x - x.floor();
    final yf = y - y.floor();

    final u = _fade(xf);
    final v = _fade(yf);

    final a = _permutation[xi][yi];
    final b = _permutation[(xi + 1) % size][yi];
    final c = _permutation[xi][(yi + 1) % size];
    final d = _permutation[(xi + 1) % size][(yi + 1) % size];

    final x1 = _lerp(a, b, u);
    final x2 = _lerp(c, d, u);
    return _lerp(x1, x2, v);
  }

  double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);
  double _lerp(double a, double b, double t) => a + t * (b - a);

  /// Fractional Brownian Motion - plusieurs octaves de bruit
  double fbm(double x, double y, int octaves, double persistence, double lacunarity) {
    double total = 0;
    double frequency = 1;
    double amplitude = 1;
    double maxValue = 0;

    for (int i = 0; i < octaves; i++) {
      total += noise(x * frequency, y * frequency) * amplitude;
      maxValue += amplitude;
      amplitude *= persistence;
      frequency *= lacunarity;
    }

    return total / maxValue;
  }
}

// Classe helper pour stocker les zones à ne pas dessiner
class _ClearZone {
  final double x;
  final double y;
  final double radius;
  
  _ClearZone(this.x, this.y, this.radius);
}

/// Painter optimisé : texture procédurale de nuages sur toute la map
class FogOfWarPainter extends CustomPainter {
  final List<ExploredArea> exploredAreas;
  final MapCamera camera;
  final bool isDarkTheme;
  final LatLng? playerPosition; // Position du joueur
  final double displayRadius; // Rayon d'affichage des zones découvertes
  static NoiseGenerator? _noiseGenerator;

  FogOfWarPainter({
    required this.exploredAreas,
    required this.camera,
    this.isDarkTheme = false,
    this.playerPosition,
    this.displayRadius = 1000.0,
  }) {
    _noiseGenerator ??= NoiseGenerator(42); // Seed fixe pour cohérence
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner uniquement les nuages qui ne sont PAS dans les zones découvertes
    _drawCloudTexture(canvas, size);
  }

  void _drawCloudTexture(Canvas canvas, Size size) {
    final noise = _noiseGenerator!;
    
    // Paramètres de rendu - ADAPTÉ AU ZOOM pour voir les zones même dézoomer
    // Zoom élevé (zoomer) : pixelStep plus grand (performance)
    // Zoom bas (dézoomer) : pixelStep plus petit (précision pour voir les zones)
    final int pixelStep = camera.zoom > 12 
        ? 32  // Zoom proche : grande résolution
        : (camera.zoom > 11
            ? 24  // Zoom moyen
            : camera.zoom > 10
                ? 16  // Zoom loin : résolution moyenne pour voir les petites zones
                : camera.zoom > 8 
                    ? 8  // Zoom très loin : haute résolution pour voir toutes les zones
                    : 6); // Zoom extrême : très haute résolution

    final paint = Paint()..style = PaintingStyle.fill;

    // Précalculer les zones découvertes en pixels pour optimisation
    final List<_ClearZone> clearZones = [];
    
    // Zone joueur
    if (playerPosition != null) {
      final playerCenter = camera.latLngToScreenPoint(playerPosition!);
      final playerRadiusPixels = _metersToPixels(displayRadius, playerPosition!.latitude);
      clearZones.add(_ClearZone(playerCenter.x, playerCenter.y, playerRadiusPixels));
    }
    
    // Zones découvertes - TOUJOURS afficher pour vision globale
    for (final area in exploredAreas) {
      final center = camera.latLngToScreenPoint(LatLng(area.latitude, area.longitude));
      final radiusPixels = _metersToPixels(displayRadius, area.latitude);
      
      // Au moins 2 pixels pour avoir une vision globale même dézoomer à fond
      final effectiveRadius = radiusPixels < 2 ? 2.0 : radiusPixels;
      clearZones.add(_ClearZone(center.x, center.y, effectiveRadius));
    }

    // Parcourir l'écran par blocs de pixels
    for (double x = 0; x < size.width; x += pixelStep) {
      for (double y = 0; y < size.height; y += pixelStep) {
        // VÉRIFIER SI CE PIXEL EST DANS UNE ZONE DÉCOUVERTE
        // Utiliser le CENTRE du carré pour éviter le clignotement au zoom
        final centerX = x + (pixelStep / 2);
        final centerY = y + (pixelStep / 2);
        
        bool isInClearZone = false;
        for (final zone in clearZones) {
          final dx = centerX - zone.x;
          final dy = centerY - zone.y;
          final distanceSquared = dx * dx + dy * dy; // Éviter sqrt pour perf
          if (distanceSquared <= zone.radius * zone.radius) {
            isInClearZone = true;
            break;
          }
        }
        
        // Si dans une zone découverte, ne pas dessiner de nuage
        if (isInClearZone) continue;
        
        // Convertir position écran en coordonnées map
        final point = camera.pointToLatLng(math.Point(x, y));

        // Générer valeur de bruit basée sur les coordonnées géographiques
        final noiseValue = noise.fbm(
          point.longitude * 1000, 
          point.latitude * 1000,
          4, // octaves réduit pour performance (avant: 5)
          0.5, // persistence
          2.0, // lacunarity
        );

        // Mapper le bruit à l'opacité/couleur
        final normalized = (noiseValue + 1) / 2;
        
        // Seuil pour créer des formes de nuages
        if (normalized > 0.3) {
          // Couleur selon le thème : noir si dark, blanc si light
          // OPACITÉ RÉDUITE pour voir la map derrière
          final brightness = 0.9 + (normalized - 0.3) * 0.1;
          final opacity = 0.60 + ((normalized - 0.3) / 0.7) * 0.20;
          
          if (isDarkTheme) {
            // Nuages NOIRS pour thème sombre
            paint.color = Color.fromRGBO(
              (20 * (1 - brightness)).toInt(), // Très sombre
              (20 * (1 - brightness)).toInt(),
              (25 * (1 - brightness)).toInt(),
              opacity,
            );
          } else {
            // Nuages BLANCS pour thème clair
            paint.color = Color.fromRGBO(
              (255 * brightness).toInt(),
              (255 * brightness).toInt(),
              (255 * brightness * 1.05).toInt().clamp(0, 255),
              opacity,
            );
          }

          canvas.drawRect(
            Rect.fromLTWH(x, y, pixelStep.toDouble(), pixelStep.toDouble()),
            paint,
          );
        }
      }
    }
  }

  double _metersToPixels(double meters, double latitude) {
    const double earthRadius = 6378137.0;
    final latRad = latitude * math.pi / 180;
    final metersPerPixel = (2 * math.pi * earthRadius * math.cos(latRad)) / 
                           (256 * math.pow(2, camera.zoom));
    return meters / metersPerPixel;
  }

  @override
  bool shouldRepaint(FogOfWarPainter oldDelegate) {
    return exploredAreas.length != oldDelegate.exploredAreas.length ||
           camera.center != oldDelegate.camera.center ||
           camera.zoom != oldDelegate.camera.zoom ||
           isDarkTheme != oldDelegate.isDarkTheme ||
           playerPosition != oldDelegate.playerPosition ||
           displayRadius != oldDelegate.displayRadius;
  }
}

/// Widget wrapper pour le fog of war
class FogOfWarOverlay extends StatelessWidget {
  final List<ExploredArea> exploredAreas;
  final MapCamera camera;
  final bool isDarkTheme;
  final Position? playerPosition;
  final double displayRadius;

  const FogOfWarOverlay({
    super.key,
    required this.exploredAreas,
    required this.camera,
    this.isDarkTheme = false,
    this.playerPosition,
    this.displayRadius = 1000.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FogOfWarPainter(
        exploredAreas: exploredAreas,
        camera: camera,
        isDarkTheme: isDarkTheme,
        playerPosition: playerPosition != null 
            ? LatLng(playerPosition!.latitude, playerPosition!.longitude)
            : null,
        displayRadius: displayRadius,
      ),
      child: Container(),
    );
  }
}
