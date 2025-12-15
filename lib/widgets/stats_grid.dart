import 'package:flutter/material.dart';
import 'stat_card.dart';

class StatsGrid extends StatelessWidget {
  final List<StatItem> items;
  final bool isDarkFog;

  const StatsGrid({
    super.key,
    required this.items,
    required this.isDarkFog,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: items.map((item) => StatCard(
        label: item.label,
        value: item.value,
        icon: item.icon,
        isDarkFog: isDarkFog,
      )).toList(),
    );
  }
}

class StatItem {
  final String label;
  final String value;
  final IconData icon;

  StatItem(this.label, this.value, this.icon);
}
