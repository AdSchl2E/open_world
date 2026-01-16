import 'package:flutter/material.dart';
import '../models/explored_area.dart';
import '../utils/app_notifications.dart';
import '../utils/data_manager.dart';

// Handles data export operations
class DataExporter {
  final BuildContext context;
  final List<ExploredArea> exploredAreas;

  DataExporter({
    required this.context,
    required this.exploredAreas,
  });

  // Export data to JSON file
  Future<void> exportData() async {
    try {
      final filePath = await DataManager.exportData(exploredAreas);

      if (context.mounted) {
        AppNotifications.showSuccess(
          context,
          '${exploredAreas.length} zones exported',
          subtitle: filePath,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppNotifications.showError(
          context,
          'Export error',
          subtitle: e.toString(),
        );
      }
    }
  }
}
