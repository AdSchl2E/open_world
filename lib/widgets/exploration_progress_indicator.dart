import 'package:flutter/material.dart';

// Shows the exploration percentage on the map
class ExplorationProgressIndicator extends StatelessWidget {
  final double explorationPercentage;
  final bool isDarkTheme;

  const ExplorationProgressIndicator({
    super.key,
    required this.explorationPercentage,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${explorationPercentage.toStringAsFixed(9)}%',
            style: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
