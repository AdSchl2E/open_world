class ExploredArea {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  // Le rayon n'est plus stocké en BD, toujours 1000m
  double get radius => 1000.0;

  ExploredArea({
    this.id,
    required this.latitude,
    required this.longitude,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ExploredArea.fromJson(Map<String, dynamic> json) {
    return ExploredArea(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ExploredArea.fromMap(Map<String, dynamic> map) {
    return ExploredArea(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
