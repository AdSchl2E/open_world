import 'package:flutter/material.dart';

// Section title for settings groups
class SectionTitle extends StatelessWidget {
  final String title;
  final bool isDarkFog;

  const SectionTitle({
    super.key,
    required this.title,
    required this.isDarkFog,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkFog ? Colors.white54 : Colors.black45;
    
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
