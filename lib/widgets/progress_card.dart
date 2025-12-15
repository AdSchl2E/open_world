import 'package:flutter/material.dart';

class ProgressCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isDarkFog;

  const ProgressCard({
    super.key,
    required this.stats,
    required this.isDarkFog,
  });

  Color get _cardColor => isDarkFog ? Colors.grey[850]! : Colors.white;
  Color get _textColorSecondary => isDarkFog ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    final percentageLand = stats['percentageLand'] as double;
    final percentageTotal = stats['percentageTotal'] as double;
    final zonesCount = stats['zonesCount'] as int;

    return Card(
      color: _cardColor,
      elevation: isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Global Progress',
              style: TextStyle(
                color: _textColorSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${(percentageLand * 100).toStringAsFixed(9)}%',
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentageLand,
              backgroundColor: isDarkFog ? Colors.grey[700] : Colors.grey[300],
              color: Colors.blueAccent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Text(
              '$zonesCount zones explored',
              style: TextStyle(
                color: _textColorSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'With oceans: ${(percentageTotal * 100).toStringAsFixed(9)}%',
              style: TextStyle(
                color: _textColorSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
