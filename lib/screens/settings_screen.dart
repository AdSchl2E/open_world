import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../services/database_service.dart';
import '../services/background_tracking_service.dart';
import '../models/explored_area.dart';
import '../utils/app_notifications.dart';

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
  bool _isBackgroundTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTrackingState();
  }

  /// Charge l'état du tracking depuis les préférences
  Future<void> _loadTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('background_tracking_enabled') ?? true; // Activé par défaut
    
    if (mounted) {
      setState(() {
        _isBackgroundTrackingEnabled = isEnabled;
      });
    }
  }

  /// Sauvegarde l'état du tracking dans les préférences
  Future<void> _saveTrackingState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_tracking_enabled', enabled);
    print('💾 [Settings] Tracking state saved: $enabled');
  }

  // Helper pour les couleurs selon le thème
  Color get _cardColor => widget.isDarkFog ? Colors.grey[850]! : Colors.white;
  Color get _textColor => widget.isDarkFog ? Colors.white : Colors.black87;
  Color get _textColorSecondary => widget.isDarkFog ? Colors.white70 : Colors.black54;
  Color get _textColorTertiary => widget.isDarkFog ? Colors.white54 : Colors.black45;
  Color get _dividerColor => widget.isDarkFog ? Colors.grey[700]! : Colors.grey[300]!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkFog ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: widget.isDarkFog ? Colors.black87 : Colors.white,
        foregroundColor: widget.isDarkFog ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Padding bas pour menu flottant
        children: [
          // Exploration section
          _buildSectionTitle('Exploration'),
          _buildFogThemeCard(),
          const SizedBox(height: 12),
          _buildBackgroundTrackingCard(),
          
          const SizedBox(height: 24),
          
          // Data section
          _buildSectionTitle('Data'),
          _buildSettingCard(
            icon: Icons.upload_file,
            title: 'Export data',
            subtitle: 'Save exploration as JSON',
            onTap: _exportData,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.download,
            title: 'Import data',
            subtitle: 'Restore from JSON file',
            onTap: _importData,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.delete_forever,
            title: 'Delete all data',
            subtitle: '${widget.exploredAreas.length} zones explored',
            color: Colors.red,
            onTap: _deleteAllData,
          ),
        ],
      ),
    );
  }

  Widget _buildFogThemeCard() {
    return Card(
      color: _cardColor,
      elevation: widget.isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isDarkFog ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Application theme',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dark or light mode (interface and clouds)',
                        style: TextStyle(
                          color: _textColorSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildThemeButton(
                    label: '🌑 Dark',
                    isSelected: widget.isDarkFog,
                    onTap: () => widget.onFogThemeChanged(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(
                    label: '☀️ Light',
                    isSelected: !widget.isDarkFog,
                    onTap: () => widget.onFogThemeChanged(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : (widget.isDarkFog ? Colors.grey[700] : Colors.grey[300]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : (widget.isDarkFog ? Colors.white70 : Colors.black54),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundTrackingCard() {
    return _buildSettingCard(
      icon: Icons.directions_run,
      title: 'Background tracking',
      subtitle: 'Record even when app is closed',
      trailing: Switch(
        value: _isBackgroundTrackingEnabled,
        onChanged: (value) async {
          print('🔵 [Settings] Switch changed to: $value');
          if (value) {
            await _startBackgroundTracking();
          } else {
            await _stopBackgroundTracking();
          }
        },
        activeColor: Colors.green,
      ),
    );
  }

  Future<void> _startBackgroundTracking() async {
    print('🔵 [Settings] _startBackgroundTracking called');
    try {
      final BackgroundTrackingService service = BackgroundTrackingService();
      await service.startTracking();
      
      setState(() {
        _isBackgroundTrackingEnabled = true;
      });
      await _saveTrackingState(true);
      
      if (mounted) {
        AppNotifications.showSuccess(
          context,
          'Tracking enabled',
          subtitle: 'Background exploration is now active',
        );
      }
      print('✅ [Settings] Tracking activated successfully');
    } catch (e) {
      print('❌ [Settings] Activation error: $e');
      setState(() {
        _isBackgroundTrackingEnabled = false;
      });
      await _saveTrackingState(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopBackgroundTracking() async {
    print('🔵 [Settings] _stopBackgroundTracking called');
    try {
      final BackgroundTrackingService service = BackgroundTrackingService();
      await service.stopTracking();
      
      setState(() {
        _isBackgroundTrackingEnabled = false;
      });
      await _saveTrackingState(false);
      
      if (mounted) {
        AppNotifications.showWarning(
          context,
          'Tracking disabled',
          subtitle: 'Background exploration is stopped',
        );
      }
      print('✅ [Settings] Tracking deactivated successfully');
    } catch (e) {
      print('❌ [Settings] Deactivation error: $e');
      setState(() {
        _isBackgroundTrackingEnabled = true; // Remettre à true en cas d'erreur
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      color: _cardColor,
      elevation: widget.isDarkFog ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.blueAccent, size: 28),
        title: Text(
          title,
          style: TextStyle(
            color: color ?? _textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: _textColorSecondary, fontSize: 13),
              )
            : null,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      // Convert zones to JSON
      final data = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'zonesCount': widget.exploredAreas.length,
        'zones': widget.exploredAreas.map((area) => {
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

      if (mounted) {
        AppNotifications.showSuccess(
          context,
          '${widget.exploredAreas.length} zones exported',
          subtitle: file.path,
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          'Export error',
          subtitle: e.toString(),
        );
      }
    }
  }

  Future<void> _importData() async {
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
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate data
      if (!data.containsKey('zones') || data['zones'] is! List) {
        throw Exception('Invalid file format');
      }

      final zones = data['zones'] as List;
      
      // Confirm import
      if (!mounted) return;
      
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: widget.isDarkFog ? Colors.grey[850] : Colors.white,
          title: Text(
            'Confirm import',
            style: TextStyle(color: widget.isDarkFog ? Colors.white : Colors.black87),
          ),
          content: Text(
            'Do you want to import ${zones.length} zones?\nThis will add new zones to your existing exploration.',
            style: TextStyle(color: widget.isDarkFog ? Colors.white70 : Colors.black54),
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

      if (confirmed != true) return;

      // Import zones
      int importedCount = 0;
      int skippedCount = 0;

      for (var zoneData in zones) {
        try {
          final area = ExploredArea(
            latitude: zoneData['latitude'] as double,
            longitude: zoneData['longitude'] as double,
            timestamp: DateTime.parse(zoneData['timestamp'] as String),
          );

          // Check if zone already exists
          bool exists = widget.exploredAreas.any((existing) {
            final distance = _calculateDistance(
              existing.latitude,
              existing.longitude,
              area.latitude,
              area.longitude,
            );
            return distance < 100; // Less than 100m = same zone
          });

          if (!exists) {
            await _databaseService.insertExploredArea(area);
            importedCount++;
          } else {
            skippedCount++;
          }
        } catch (e) {
          print('⚠️ Zone import error: $e');
        }
      }

      // Reload data
      widget.onDataChanged();

      if (mounted) {
        AppNotifications.showSuccess(
          context,
          'Import completed successfully',
          subtitle: '$importedCount zones added • $skippedCount duplicates ignored',
        );
      }
    } catch (e) {
      if (mounted) {
        AppNotifications.showError(
          context,
          'Import error',
          subtitle: e.toString(),
        );
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 - 
        (cos((lat2 - lat1) * p) / 2) +
        (cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2);
    return 12742000 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _deleteAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Confirm deletion',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you really want to delete all ${widget.exploredAreas.length} explored zones?\n\nThis action is irreversible.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseService.deleteAllExploredAreas();
              widget.onDataChanged();
              Navigator.pop(context);
              AppNotifications.showSuccess(
                context,
                'Data deleted',
                subtitle: 'All your explored zones have been erased',
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
