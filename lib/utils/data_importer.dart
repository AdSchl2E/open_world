import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../models/explored_area.dart';
import '../utils/app_notifications.dart';
import '../utils/data_manager.dart';
import '../utils/geo_utils.dart';

// Handles data import operations
class DataImporter {
  final BuildContext context;
  final List<ExploredArea> exploredAreas;
  final DatabaseService databaseService;
  final Function() onDataChanged;
  final bool isDarkFog;

  DataImporter({
    required this.context,
    required this.exploredAreas,
    required this.databaseService,
    required this.onDataChanged,
    required this.isDarkFog,
  });

  // Import data from JSON file
  Future<void> importData() async {
    try {
      // Select a JSON file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);
      final zones = await DataManager.parseImportData(file);
      
      // Confirm import
      if (!context.mounted) return;
      
      final confirmed = await _showImportConfirmDialog(zones.length);
      if (confirmed != true) return;

      // Import zones
      final importResult = await _importZones(zones);

      // Reload data
      onDataChanged();

      if (context.mounted) {
        AppNotifications.showSuccess(
          context,
          'Import completed successfully',
          subtitle: '${importResult.imported} zones added • ${importResult.skipped} duplicates ignored',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppNotifications.showError(
          context,
          'Import error',
          subtitle: e.toString(),
        );
      }
    }
  }

  // Show confirmation dialog for import
  Future<bool?> _showImportConfirmDialog(int zonesCount) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkFog ? Colors.grey[850] : Colors.white,
        title: Text(
          'Confirm import',
          style: TextStyle(color: isDarkFog ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Do you want to import $zonesCount zones?\nThis will add new zones to your existing exploration.',
          style: TextStyle(color: isDarkFog ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  // Import zones and return statistics
  Future<ImportResult> _importZones(List<Map<String, dynamic>> zones) async {
    int importedCount = 0;
    int skippedCount = 0;

    for (var zoneData in zones) {
      try {
        final area = DataManager.zoneFromJson(zoneData);

        // Check if zone already exists
        bool exists = exploredAreas.any((existing) {
          return GeoUtils.areZonesDuplicate(
            existing.latitude,
            existing.longitude,
            area.latitude,
            area.longitude,
          );
        });

        if (!exists) {
          await databaseService.insertExploredArea(area);
          importedCount++;
        } else {
          skippedCount++;
        }
      } catch (e) {
        print('⚠️ Zone import error: $e');
      }
    }

    return ImportResult(imported: importedCount, skipped: skippedCount);
  }
}

// Result of import operation
class ImportResult {
  final int imported;
  final int skipped;

  ImportResult({required this.imported, required this.skipped});
}
