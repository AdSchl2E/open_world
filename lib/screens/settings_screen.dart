import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/explored_area.dart';

class SettingsScreen extends StatefulWidget {
  final List<ExploredArea> exploredAreas;
  final Function() onDataChanged;
  final double displayRadius;
  final Function(double) onDisplayRadiusChanged;
  final bool isDarkFog;
  final Function(bool) onFogThemeChanged;

  const SettingsScreen({
    super.key,
    required this.exploredAreas,
    required this.onDataChanged,
    required this.displayRadius,
    required this.onDisplayRadiusChanged,
    required this.isDarkFog,
    required this.onFogThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();

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
        title: Text('Paramètres'),
        backgroundColor: widget.isDarkFog ? Colors.black87 : Colors.white,
        foregroundColor: widget.isDarkFog ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Padding bas pour menu flottant
        children: [
          // Section Données
          _buildSectionTitle('Données'),
          _buildSettingCard(
            icon: Icons.upload_file,
            title: 'Exporter les données',
            subtitle: 'Sauvegarder l\'exploration en JSON',
            onTap: _exportData,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.download,
            title: 'Importer les données',
            subtitle: 'Restaurer depuis un fichier JSON',
            onTap: _importData,
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.delete_forever,
            title: 'Effacer toutes les données',
            subtitle: '${widget.exploredAreas.length} zones explorées',
            color: Colors.red,
            onTap: _deleteAllData,
          ),
          
          const SizedBox(height: 24),
          
          // Section Exploration
          _buildSectionTitle('Exploration'),
          _buildRadiusSliderCard(),
          const SizedBox(height: 12),
          _buildFogThemeCard(),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.location_on,
            title: 'Fréquence de tracking',
            subtitle: 'Mise à jour tous les 10m',
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              // TODO: Permettre de changer la fréquence
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section À propos
          _buildSectionTitle('À propos'),
          _buildSettingCard(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0 Beta',
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            icon: Icons.code,
            title: 'Open Source',
            subtitle: 'Projet OpenWorld',
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSliderCard() {
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
                const Icon(Icons.adjust, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rayon d\'affichage',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.displayRadius.toInt()}m',
                        style: TextStyle(color: _textColorSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.blueAccent,
                inactiveTrackColor: _dividerColor,
                thumbColor: Colors.blueAccent,
                overlayColor: Colors.blueAccent.withOpacity(0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(
                value: widget.displayRadius,
                min: 100,
                max: 5000,
                divisions: 49,
                label: '${widget.displayRadius.toInt()}m',
                onChanged: (value) {
                  widget.onDisplayRadiusChanged(value);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '100m',
                  style: TextStyle(color: _textColorSecondary, fontSize: 12),
                ),
                Text(
                  '5000m',
                  style: TextStyle(color: _textColorSecondary, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
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
                        'Thème de l\'application',
                        style: TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mode sombre ou clair (interface et nuages)',
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
                    label: '🌑 Sombre',
                    isSelected: widget.isDarkFog,
                    onTap: () => widget.onFogThemeChanged(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeButton(
                    label: '☀️ Clair',
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

  void _exportData() {
    // TODO: Implémenter l'export JSON
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export JSON - À implémenter prochainement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _importData() {
    // TODO: Implémenter l'import JSON
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import JSON - À implémenter prochainement'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deleteAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Confirmer la suppression',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer toutes les ${widget.exploredAreas.length} zones explorées ?\n\nCette action est irréversible.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _databaseService.deleteAllExploredAreas();
              widget.onDataChanged();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les données ont été supprimées'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
