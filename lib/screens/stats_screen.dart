import 'package:flutter/material.dart';
import '../models/explored_area.dart';
import 'package:geolocator/geolocator.dart';

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

  // Helper pour les couleurs selon le thème
  Color get _backgroundColor => isDarkFog ? Colors.grey[900]! : Colors.grey[100]!;
  Color get _cardColor => isDarkFog ? Colors.grey[850]! : Colors.white;
  Color get _textColor => isDarkFog ? Colors.white : Colors.black87;
  Color get _textColorSecondary => isDarkFog ? Colors.white70 : Colors.black54;
  Color get _textColorTertiary => isDarkFog ? Colors.white54 : Colors.black45;

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Statistics'),
        backgroundColor: isDarkFog ? Colors.black87 : Colors.white,
        foregroundColor: isDarkFog ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Padding bas pour menu flottant
        children: [
          // Carte de progression globale
          _buildProgressCard(stats),
          
          const SizedBox(height: 16),
          
          // General section
          _buildSectionTitle('General'),
          _buildStatsGrid([
            _StatItem('Explored zones', '${exploredAreas.length}', Icons.explore),
            _StatItem('Covered area', '${stats['totalArea']} km²', Icons.area_chart),
          ]),
          
          const SizedBox(height: 24),
          
          // Records section
          _buildSectionTitle('Records'),
          _buildStatsGrid([
            _StatItem('Today', '${stats['today']}', Icons.today),
            _StatItem('This week', '${stats['thisWeek']}', Icons.calendar_today),
          ]),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> stats) {
    final percentageLand = stats['percentageLand'] as double;
    final percentageTotal = stats['percentageTotal'] as double;
    
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
                fontSize: 48,
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
              '${exploredAreas.length} zones explored',
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: _textColorTertiary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4, // Réduit de 1.5 à 1.4 pour éviter overflow
      children: items.map((item) => _buildStatCard(item)).toList(),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Card(
      color: _cardColor,
      elevation: isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Réduit de 16 à 12
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: Colors.blueAccent, size: 28), // Réduit de 32 à 28
            const SizedBox(height: 6), // Réduit de 8 à 6
            Text(
              item.value,
              style: TextStyle(
                color: _textColor,
                fontSize: 18, // Réduit de 20 à 18
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                color: _textColorSecondary,
                fontSize: 11, // Réduit de 12 à 11
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionCard(String region, double percentage, int zones) {
    return Card(
      color: _cardColor,
      elevation: isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.public, color: Colors.blueAccent, size: 32),
        title: Text(
          region,
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '$zones zones explored',
          style: TextStyle(color: _textColorSecondary, fontSize: 13),
        ),
        trailing: Text(
          '${(percentage * 100).toStringAsFixed(3)}%',
          style: const TextStyle(
            color: Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Map<String, dynamic> _calculateStats() {
    if (exploredAreas.isEmpty) {
      return {
        'percentage': 0.0,
        'totalArea': 0.0,
        'today': 0,
        'thisWeek': 0,
      };
    }

    // Calculer la surface totale (approximation)
    final totalAreaM2 = exploredAreas.fold<double>(
      0.0,
      (sum, area) => sum + (3.14159 * area.radius * area.radius),
    );
    final totalAreaKm2 = (totalAreaM2 / 1000000).toStringAsFixed(2);

    // Zones ajoutées aujourd'hui et cette semaine
    final now = DateTime.now();
    final today = exploredAreas.where((a) {
      final diff = now.difference(a.timestamp);
      return diff.inHours < 24;
    }).length;

    final thisWeek = exploredAreas.where((a) {
      final diff = now.difference(a.timestamp);
      return diff.inDays < 7;
    }).length;

    // Calcul des pourcentages
    final surfaceTerrestre = 510000000000 * 0.29; // 29% de la surface totale
    final percentageLand = exploredAreas.length / surfaceTerrestre;
    final percentageTotal = exploredAreas.length / 510000000000;

    return {
      'percentageLand': percentageLand,
      'percentageTotal': percentageTotal,
      'totalArea': totalAreaKm2,
      'today': today,
      'thisWeek': thisWeek,
    };
  }

  String _getOldestDate() {
    if (exploredAreas.isEmpty) return 'N/A';
    final oldest = exploredAreas.reduce((a, b) =>
        a.timestamp.isBefore(b.timestamp) ? a : b);
    final diff = DateTime.now().difference(oldest.timestamp);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} ans';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mois';
    if (diff.inDays > 0) return '${diff.inDays} jours';
    return 'Aujourd\'hui';
  }

  String _getNewestDate() {
    if (exploredAreas.isEmpty) return 'N/A';
    final newest = exploredAreas.reduce((a, b) =>
        a.timestamp.isAfter(b.timestamp) ? a : b);
    final diff = DateTime.now().difference(newest.timestamp);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays} jours';
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  _StatItem(this.label, this.value, this.icon);
}
