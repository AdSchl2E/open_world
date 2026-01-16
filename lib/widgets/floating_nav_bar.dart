import 'package:flutter/material.dart';

// Navigation bar with three tabs: Settings, Map, Stats
class FloatingNavBar extends StatelessWidget {
  final int currentTab;
  final Function(int) onTabChanged;
  final bool isDarkTheme;

  const FloatingNavBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.isDarkTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: isDarkTheme ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.settings,
            label: 'Settings',
            isSelected: currentTab == 0,
            onTap: () => onTabChanged(0),
          ),
          _buildNavButton(
            icon: Icons.map,
            label: 'Map',
            isSelected: currentTab == 1,
            onTap: () => onTabChanged(1),
          ),
          _buildNavButton(
            icon: Icons.bar_chart,
            label: 'Stats',
            isSelected: currentTab == 2,
            onTap: () => onTabChanged(2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(35),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? Colors.blueAccent 
                      : (isDarkTheme ? Colors.white54 : Colors.black45),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.blueAccent 
                        : (isDarkTheme ? Colors.white54 : Colors.black45),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
