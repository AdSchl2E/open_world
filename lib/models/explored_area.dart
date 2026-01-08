class ExploredArea {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double radius; // Rayon en mètres, stocké en BD

  // Rayon par défaut pour les nouvelles zones (20m)
  static const double defaultRadius = 20.0;

  ExploredArea({
    this.id,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
    double? radius,
  }) : timestamp = timestamp ?? DateTime.now(),
       radius = radius ?? defaultRadius;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'radius': radius,
    };
  }

  factory ExploredArea.fromJson(Map<String, dynamic> json) {
    return ExploredArea(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
      radius: (json['radius'] as num?)?.toDouble() ?? defaultRadius,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'radius': radius,
    };
  }

  factory ExploredArea.fromMap(Map<String, dynamic> map) {
    return ExploredArea(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.parse(map['timestamp']),
      radius: (map['radius'] as num?)?.toDouble() ?? defaultRadius,
    );
  }
}
