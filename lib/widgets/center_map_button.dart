import 'package:flutter/material.dart';

/// Button to center the map on user's current position
class CenterMapButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDarkTheme;

  const CenterMapButton({
    super.key,
    required this.onPressed,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'center',
      onPressed: onPressed,
      backgroundColor: isDarkTheme ? Colors.grey[850] : Colors.white,
      child: Icon(
        Icons.my_location,
        color: isDarkTheme ? Colors.white : Colors.blue,
      ),
    );
  }
}
