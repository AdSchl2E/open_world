import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/explored_area.dart';
import '../utils/stats_calculator.dart';
import '../widgets/progress_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/section_title.dart';

class StatsScreen extends StatelessWidget {
  final List<ExploredArea> exploredAreas;
  final Position? currentPosition;
  final bool isDarkFog;

  const StatsScreen({
    super.key,
    required this.exploredAreas,
    this.currentPosition,
    this.isDarkFog = true,
  });

  Color get _backgroundColor => isDarkFog ? Colors.grey[900]! : Colors.grey[100]!;

  @override
  Widget build(BuildContext context) {
    final stats = StatsCalculator.calculate(exploredAreas);
    final statsWithCount = {...stats, 'zonesCount': exploredAreas.length};

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: isDarkFog ? Colors.black87 : Colors.white,
        foregroundColor: isDarkFog ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        children: [
          ProgressCard(
            stats: statsWithCount,
            isDarkFog: isDarkFog,
          ),
          
          const SizedBox(height: 16),
          
          SectionTitle(title: 'General', isDarkFog: isDarkFog),
          StatsGrid(
            items: [
              StatItem('Explored zones', '${exploredAreas.length}', Icons.explore),
              StatItem('Covered area', '${stats['totalArea']} km²', Icons.area_chart),
            ],
            isDarkFog: isDarkFog,
          ),
          
          const SizedBox(height: 24),
          
          SectionTitle(title: 'Records', isDarkFog: isDarkFog),
          StatsGrid(
            items: [
              StatItem('Today', '${stats['today']}', Icons.today),
              StatItem('This week', '${stats['thisWeek']}', Icons.calendar_today),
            ],
            isDarkFog: isDarkFog,
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}
