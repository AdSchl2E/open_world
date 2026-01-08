import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/explored_area.dart';

class ZoneRadiusCard extends StatefulWidget {
  final bool isDarkFog;
  final Function(double)? onRadiusChanged;

  const ZoneRadiusCard({
    super.key,
    required this.isDarkFog,
    this.onRadiusChanged,
  });

  @override
  State<ZoneRadiusCard> createState() => _ZoneRadiusCardState();
}

class _ZoneRadiusCardState extends State<ZoneRadiusCard> {
  static const String _prefKey = 'zone_radius';
  static const double _minRadius = 10.0;
  static const double _maxRadius = 500.0;
  
  // Logarithmic scale: slider position 0-1 maps to radius 10-500
  static const double _logMin = 1.0; // log10(10) = 1
  static const double _logMax = 2.699; // log10(500) ≈ 2.699
  
  double _currentRadius = ExploredArea.defaultRadius;

  @override
  void initState() {
    super.initState();
    _loadRadius();
  }

  Future<void> _loadRadius() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentRadius = prefs.getDouble(_prefKey) ?? ExploredArea.defaultRadius;
    });
  }

  Future<void> _saveRadius(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefKey, value);
    widget.onRadiusChanged?.call(value);
  }

  // Convert radius to slider position (0-1) using logarithmic scale
  double _radiusToSlider(double radius) {
    final logValue = _log10(radius.clamp(_minRadius, _maxRadius));
    return (logValue - _logMin) / (_logMax - _logMin);
  }

  // Convert slider position (0-1) to radius using logarithmic scale
  double _sliderToRadius(double sliderValue) {
    final logValue = _logMin + sliderValue * (_logMax - _logMin);
    final rawRadius = _pow10(logValue);
    return _snapToNiceValue(rawRadius);
  }

  // Snap to nice round values for easier selection
  double _snapToNiceValue(double value) {
    if (value <= 15) return 10;
    if (value <= 25) return 20;
    if (value <= 35) return 30;
    if (value <= 45) return 40;
    if (value <= 60) return 50;
    if (value <= 80) return 75;
    if (value <= 125) return 100;
    if (value <= 175) return 150;
    if (value <= 225) return 200;
    if (value <= 275) return 250;
    if (value <= 350) return 300;
    if (value <= 450) return 400;
    return 500;
  }

  double _log10(double x) => log(x) / ln10;
  double _pow10(double x) => pow(10, x).toDouble();

  String _formatRadius(double radius) {
    if (radius >= 1000) {
      return '${(radius / 1000).toStringAsFixed(1)} km';
    }
    return '${radius.toInt()} m';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkFog ? Colors.grey[850] : Colors.white;
    final textColor = widget.isDarkFog ? Colors.white : Colors.black87;
    final subtitleColor = widget.isDarkFog ? Colors.grey[400] : Colors.grey[600];

    return Card(
      color: bgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.circle_outlined, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zone radius',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Size of new explored zones',
                        style: TextStyle(
                          fontSize: 13,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Current value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatRadius(_currentRadius),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Slider with logarithmic scale
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.blue,
                inactiveTrackColor: Colors.blue.withOpacity(0.2),
                thumbColor: Colors.blue,
                overlayColor: Colors.blue.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _radiusToSlider(_currentRadius),
                min: 0.0,
                max: 1.0,
                onChanged: (sliderValue) {
                  setState(() {
                    _currentRadius = _sliderToRadius(sliderValue);
                  });
                },
                onChangeEnd: (sliderValue) {
                  _saveRadius(_sliderToRadius(sliderValue));
                },
              ),
            ),
            
            // Min/Max labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10 m',
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                  Text(
                    '500 m',
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Static method to get current radius from SharedPreferences
  static Future<double> getCurrentRadius() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefKey) ?? ExploredArea.defaultRadius;
  }
}
