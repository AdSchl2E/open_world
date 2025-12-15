import 'package:flutter/material.dart';

/// Card with theme selection (Dark/Light)
class FogThemeCard extends StatelessWidget {
  final bool isDarkFog;
  final Function(bool) onThemeChanged;

  const FogThemeCard({
    super.key,
    required this.isDarkFog,
    required this.onThemeChanged,
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDarkFog ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application theme',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dark or light mode (interface and clouds)',
                        style: TextStyle(
                          color: _textColorSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildThemeButton(
                    label: '🌑 Dark',
                    isSelected: isDarkFog,
                    onTap: () => onThemeChanged(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(
                    label: '☀️ Light',
                    isSelected: !isDarkFog,
                    onTap: () => onThemeChanged(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : (isDarkFog ? Colors.grey[700] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : (isDarkFog ? Colors.white70 : Colors.black54),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
