import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/explored_area.dart';

// Handles data import/export operations
class DataManager {
  // Export explored areas to JSON file using system file picker
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
    final bytes = utf8.encode(jsonString);

    // Create default filename
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final fileName = 'openworld_export_$timestamp.json';

    // Open system "Save As" dialog - user chooses where to save
    String? outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save exploration data',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: bytes,
    );

    if (outputPath == null) {
      throw Exception('Export cancelled');
    }

    // On some platforms, saveFile doesn't write the file, just returns the path
    // So we write it manually to be safe
    if (!outputPath.endsWith('.json')) {
      outputPath = '$outputPath.json';
    }
    
    final file = File(outputPath);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes);
    }

    return outputPath;
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
