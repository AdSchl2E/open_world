import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/explored_area.dart';
import '../utils/data_exporter.dart';
import '../utils/data_importer.dart';
import '../widgets/fog_theme_card.dart';
import '../widgets/background_tracking_card.dart';
import '../widgets/setting_card.dart';
import '../widgets/section_title.dart';
import '../widgets/delete_data_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final List<ExploredArea> exploredAreas;
  final Function() onDataChanged;
  final bool isDarkFog;
  final Function(bool) onFogThemeChanged;

  const SettingsScreen({
    super.key,
    required this.exploredAreas,
    required this.onDataChanged,
    required this.isDarkFog,
    required this.onFogThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkFog ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: widget.isDarkFog ? Colors.black87 : Colors.white,
        foregroundColor: widget.isDarkFog ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        children: [
          // Exploration section
          SectionTitle(title: 'Exploration', isDarkFog: widget.isDarkFog),
          FogThemeCard(
            isDarkFog: widget.isDarkFog,
            onThemeChanged: widget.onFogThemeChanged,
          ),
          const SizedBox(height: 12),
          BackgroundTrackingCard(isDarkFog: widget.isDarkFog),
          
          const SizedBox(height: 24),
          
          // Data section
          SectionTitle(title: 'Data', isDarkFog: widget.isDarkFog),
          SettingCard(
            icon: Icons.upload_file,
            title: 'Export data',
            subtitle: 'Save exploration as JSON',
            isDarkFog: widget.isDarkFog,
            onTap: _exportData,
          ),
          const SizedBox(height: 12),
          SettingCard(
            icon: Icons.download,
            title: 'Import data',
            subtitle: 'Restore from JSON file',
            isDarkFog: widget.isDarkFog,
            onTap: _importData,
          ),
          const SizedBox(height: 12),
          SettingCard(
            icon: Icons.delete_forever,
            title: 'Delete all data',
            subtitle: '${widget.exploredAreas.length} zones explored',
            color: Colors.red,
            isDarkFog: widget.isDarkFog,
            onTap: _deleteAllData,
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final exporter = DataExporter(
      context: context,
      exploredAreas: widget.exploredAreas,
    );
    await exporter.exportData();
  }

  Future<void> _importData() async {
    final importer = DataImporter(
      context: context,
      exploredAreas: widget.exploredAreas,
      databaseService: _databaseService,
      onDataChanged: widget.onDataChanged,
      isDarkFog: widget.isDarkFog,
    );
    await importer.importData();
  }

  void _deleteAllData() {
    DeleteDataDialog(
      context: context,
      zonesCount: widget.exploredAreas.length,
      databaseService: _databaseService,
      onDataChanged: widget.onDataChanged,
      isDarkFog: widget.isDarkFog,
    ).show();
  }
}
