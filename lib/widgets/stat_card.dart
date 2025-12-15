import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDarkFog;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isDarkFog,
  });

  Color get _cardColor => isDarkFog ? Colors.grey[850]! : Colors.white;
  Color get _textColor => isDarkFog ? Colors.white : Colors.black87;
  Color get _textColorSecondary => isDarkFog ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _cardColor,
      elevation: isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: _textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _textColorSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
