import '../models/explored_area.dart';

class StatsCalculator {
  static Map<String, dynamic> calculate(List<ExploredArea> exploredAreas) {
    if (exploredAreas.isEmpty) {
      return {
        'percentageLand': 0.0,
        'percentageTotal': 0.0,
        'totalArea': '0.00',
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

  static String getOldestDate(List<ExploredArea> exploredAreas) {
    if (exploredAreas.isEmpty) return 'N/A';
    final oldest = exploredAreas.reduce((a, b) =>
        a.timestamp.isBefore(b.timestamp) ? a : b);
    final diff = DateTime.now().difference(oldest.timestamp);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} ans';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mois';
    if (diff.inDays > 0) return '${diff.inDays} jours';
    return 'Aujourd\'hui';
  }

  static String getNewestDate(List<ExploredArea> exploredAreas) {
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
