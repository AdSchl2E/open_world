import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Générateur de nuages procéduraux organiques
class CloudGenerator {
  static ui.Image? _cachedCloudTexture;
  static bool _isGenerating = false;

  /// Génère une texture de nuage organique de manière procédurale
  static Future<ui.Image> generateCloudTexture({
    int size = 512,
    bool isDark = true,
  }) async {
    // Cache pour éviter de régénérer
    if (_cachedCloudTexture != null && !_isGenerating) {
      return _cachedCloudTexture!;
    }

    if (_isGenerating) {
      // Attendre que la génération en cours se termine
      while (_isGenerating) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedCloudTexture!;
    }

    _isGenerating = true;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    // Fond transparent
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      Paint()..color = Colors.transparent,
    );

    // Couleur du nuage
    final cloudColor = isDark 
        ? const Color(0xFF1A1A1A) // Gris très foncé pour nuages sombres
        : const Color(0xFFF5F5F5); // Blanc cassé pour nuages clairs

    final random = math.Random(42); // Seed fixe pour reproductibilité

    // Générer plusieurs "blobs" pour créer un nuage organique
    final numBlobs = 8 + random.nextInt(5); // 8-12 blobs
    
    for (int i = 0; i < numBlobs; i++) {
      final centerX = size * (0.3 + random.nextDouble() * 0.4);
      final centerY = size * (0.3 + random.nextDouble() * 0.4);
      final radius = size * (0.15 + random.nextDouble() * 0.25);
      
      // Gradient radial pour chaque blob
      final gradient = ui.Gradient.radial(
        Offset(centerX, centerY),
        radius,
        [
          cloudColor.withOpacity(0.8),
          cloudColor.withOpacity(0.4),
          cloudColor.withOpacity(0.0),
        ],
        [0.0, 0.6, 1.0],
      );

      paint.shader = gradient;
      canvas.drawCircle(Offset(centerX, centerY), radius, paint);
    }

    // Convertir en image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    
    _cachedCloudTexture = image;
    _isGenerating = false;
    
    return image;
  }

  /// Nettoyer le cache
  static void clearCache() {
    _cachedCloudTexture?.dispose();
    _cachedCloudTexture = null;
  }
}

/// Painter pour dessiner les nuages avec des textures organiques
class OrganicCloudPainter extends CustomPainter {
  final List<CloudInstance> clouds;
  final ui.Image? cloudTexture;
  final bool isDark;

  OrganicCloudPainter({
    required this.clouds,
    this.cloudTexture,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cloudTexture == null) return;

    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..blendMode = BlendMode.srcOver;

    // Dessiner chaque nuage
    for (final cloud in clouds) {
      canvas.save();
      
      // Positionner et dimensionner le nuage
      canvas.translate(cloud.x, cloud.y);
      canvas.scale(cloud.scale, cloud.scale);
      canvas.rotate(cloud.rotation);
      
      // Dessiner la texture du nuage
      final srcRect = Rect.fromLTWH(
        0,
        0,
        cloudTexture!.width.toDouble(),
        cloudTexture!.height.toDouble(),
      );
      
      final dstRect = Rect.fromCenter(
        center: Offset.zero,
        width: cloudTexture!.width.toDouble(),
        height: cloudTexture!.height.toDouble(),
      );
      
      paint.color = paint.color.withOpacity(cloud.opacity);
      canvas.drawImageRect(cloudTexture!, srcRect, dstRect, paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(OrganicCloudPainter oldDelegate) {
    return clouds.length != oldDelegate.clouds.length ||
           cloudTexture != oldDelegate.cloudTexture ||
           isDark != oldDelegate.isDark;
  }
}

/// Instance d'un nuage à l'écran
class CloudInstance {
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final double opacity;

  CloudInstance({
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.opacity = 0.9,
  });
}
