import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/explored_area.dart';

// Handles data import/export operations
class DataManager {
  // Export explored areas to JSON file
  static Future<String> exportData(List<ExploredArea> exploredAreas) async {
    // Convert zones to JSON
    final data = {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'zonesCount': exploredAreas.length,
      'zones': exploredAreas.map((area) => {
        'latitude': area.latitude,
        'longitude': area.longitude,
        'radius': area.radius,
        'timestamp': area.timestamp.toIso8601String(),
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // Get download directory
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }
    } else if (Platform.isWindows) {
      directory = await getDownloadsDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception('Cannot find download directory');
    }

    // Create file with unique name
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'openworld_export_$timestamp.json';
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(jsonString);

    return file.path;
  }

  // Parse and validate JSON import data
  static Future<List<Map<String, dynamic>>> parseImportData(File file) async {
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    // Validate data
    if (!data.containsKey('zones') || data['zones'] is! List) {
      throw Exception('Invalid file format');
    }

    return (data['zones'] as List).cast<Map<String, dynamic>>();
  }

  // Convert JSON zone data to ExploredArea
  static ExploredArea zoneFromJson(Map<String, dynamic> zoneData) {
    return ExploredArea(
      latitude: zoneData['latitude'] as double,
      longitude: zoneData['longitude'] as double,
      timestamp: DateTime.parse(zoneData['timestamp'] as String),
      radius: (zoneData['radius'] as num?)?.toDouble(),
    );
  }
}
