import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/app_notifications.dart';

// Confirmation dialog for deleting all data
class DeleteDataDialog {
  final BuildContext context;
  final int zonesCount;
  final DatabaseService databaseService;
  final Function() onDataChanged;
  final bool isDarkFog;

  DeleteDataDialog({
    required this.context,
    required this.zonesCount,
    required this.databaseService,
    required this.onDataChanged,
    required this.isDarkFog,
  });

  // Show delete confirmation dialog
  void show() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkFog ? Colors.grey[850] : Colors.white,
        title: Text(
          'Confirm deletion',
          style: TextStyle(color: isDarkFog ? Colors.white : Colors.black87),
        ),
        content: Text(
          'Do you really want to delete all $zonesCount explored zones?\n\nThis action is irreversible.',
          style: TextStyle(color: isDarkFog ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteAllData(),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Delete all data and close dialog
  Future<void> _deleteAllData() async {
    await databaseService.deleteAllExploredAreas();
    onDataChanged();
    
    if (context.mounted) {
      Navigator.pop(context);
      AppNotifications.showSuccess(
        context,
        'Data deleted',
        subtitle: 'All your explored zones have been erased',
      );
    }
  }
}
