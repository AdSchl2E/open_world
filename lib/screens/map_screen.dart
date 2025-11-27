import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../models/explored_area.dart';
import '../widgets/fog_of_war_painter.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  
  Position? _currentPosition;
  List<ExploredArea> _exploredAreas = [];
  StreamSubscription<Position>? _positionStreamSubscription;
  
  bool _isLoading = true;
  double _explorationPercentage = 0.0;
  int _currentTab = 1; // 0: Paramètres, 1: Carte, 2: Stats
  double _displayRadius = 1000.0;
  bool _testDataInitialized = false;
  bool _isDarkFog = true;
  
  // État de la caméra Google Maps
  LatLng _mapCenter = const LatLng(48.8566, 2.3522); // Paris par défaut
  double _mapZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Charger les zones explorées depuis la base de données
    _exploredAreas = await _databaseService.getAllExploredAreas();
    print('🗺️ Zones explorées chargées: ${_exploredAreas.length}');
    
    // ⚠️ ZONES DE TEST - Créées une seule fois
    if (_exploredAreas.isEmpty && !_testDataInitialized) {
      print('🧪 Initialisation des zones de test...');
      await _createTestZones();
      _testDataInitialized = true;
    }
    
    // Vérifier les permissions
    bool hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      _showPermissionDialog();
      setState(() => _isLoading = false);
      return;
    }

    // Obtenir la position actuelle
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      print('📍 Position actuelle: ${position.latitude}, ${position.longitude}');
      
      // Ajouter immédiatement la position actuelle comme zone explorée
      await _addExploredArea(position);
      
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      // Ne pas déplacer la caméra ici - attendre onMapReady
    } else {
      setState(() => _isLoading = false);
    }

    // Commencer le tracking
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionStreamSubscription = _locationService.getPositionStream().listen((position) {
      setState(() => _currentPosition = position);
      _checkAndAddNewArea(position);
    });
  }

  void _checkAndAddNewArea(Position position) {
    // Vérifier si cette zone est déjà explorée
    bool isNewArea = true;
    for (var area in _exploredAreas) {
      double distance = _locationService.calculateDistance(
        position.latitude,
        position.longitude,
        area.latitude,
        area.longitude,
      );
      
      // Si la nouvelle position est à moins de la moitié du rayon d'une zone existante,
      // on considère que c'est déjà exploré (pour éviter trop de chevauchement)
      if (distance < area.radius * 0.5) {
        isNewArea = false;
        print('⚠️ Zone déjà explorée (distance: ${distance.toStringAsFixed(1)}m < ${(area.radius * 0.5).toStringAsFixed(1)}m)');
        break;
      }
    }

    if (isNewArea) {
      print('🆕 Nouvelle zone à ajouter!');
      _addExploredArea(position);
    }
  }

  Future<void> _addExploredArea(Position position) async {
    ExploredArea newArea = ExploredArea(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    
    print('✅ Nouvelle zone explorée ajoutée: ${position.latitude}, ${position.longitude}, rayon: 1000m');
    
    await _databaseService.insertExploredArea(newArea);
    setState(() {
      _exploredAreas.add(newArea);
      _explorationPercentage = _exploredAreas.length / 510000000000 * 100;
    });
    
    print('📊 Total zones explorées: ${_exploredAreas.length}');
  }

  Future<void> _createTestZones() async {
    const totalZones = 500;
    print('🧪 Création de $totalZones zones de test (1 zone = 3.14km², espacement 500m)...');

    final random = Random();
    int createdCount = 0;

    // STRASBOURG - 40% (200 zones) - Ville natale, exploration intensive
    // Strasbourg ville: ~78 km² = max ~25 zones si 100% couvert
    final strasbourgZones = [
      // Centre historique (très exploré)
      {'name': 'Centre-Ville', 'lat': 48.5816, 'lng': 7.7507, 'count': 40, 'radius': 0.025},
      {'name': 'Krutenau', 'lat': 48.5790, 'lng': 7.7650, 'count': 15, 'radius': 0.015},
      {'name': 'Neudorf', 'lat': 48.5650, 'lng': 7.7580, 'count': 20, 'radius': 0.02},
      {'name': 'Esplanade', 'lat': 48.5830, 'lng': 7.7620, 'count': 15, 'radius': 0.015},
      // Quartiers résidentiels
      {'name': 'Orangerie', 'lat': 48.5880, 'lng': 7.7720, 'count': 12, 'radius': 0.02},
      {'name': 'Robertsau', 'lat': 48.5950, 'lng': 7.7800, 'count': 12, 'radius': 0.02},
      {'name': 'Koenigshoffen', 'lat': 48.5800, 'lng': 7.7350, 'count': 10, 'radius': 0.02},
      {'name': 'Meinau', 'lat': 48.5550, 'lng': 7.7600, 'count': 10, 'radius': 0.02},
      {'name': 'Hautepierre', 'lat': 48.5950, 'lng': 7.7000, 'count': 10, 'radius': 0.025},
      {'name': 'Cronenbourg', 'lat': 48.5850, 'lng': 7.7200, 'count': 10, 'radius': 0.02},
      {'name': 'Neuhof', 'lat': 48.5470, 'lng': 7.7550, 'count': 8, 'radius': 0.025},
      // Villes périphériques (exploration occasionnelle)
      {'name': 'Schiltigheim', 'lat': 48.6070, 'lng': 7.7500, 'count': 3, 'radius': 0.015},
      {'name': 'Lingolsheim', 'lat': 48.5580, 'lng': 7.6830, 'count': 8, 'radius': 0.015},
      {'name': 'Illkirch', 'lat': 48.5290, 'lng': 7.7200, 'count': 8, 'radius': 0.02},
      {'name': 'Ostwald', 'lat': 48.5380, 'lng': 7.7040, 'count': 5, 'radius': 0.015},
      {'name': 'Kehl (Allemagne)', 'lat': 48.5706, 'lng': 7.8156, 'count': 14, 'radius': 0.02},
    ];

    print('📍 STRASBOURG (40% - Ville natale)');
    for (final zone in strasbourgZones) {
      await _generateZonesForArea(
        zone['name'] as String,
        zone['lat'] as double,
        zone['lng'] as double,
        zone['count'] as int,
        zone['radius'] as double,
        random,
        1825, // 5 ans d'exploration
        (count) => createdCount = count,
      );
    }

    // LYON - 30% (150 zones) - Études, exploration régulière
    // Lyon ville: ~48 km² = max ~15 zones si 100% couvert
    final lyonZones = [
      {'name': 'Presqu\'île', 'lat': 45.7640, 'lng': 4.8357, 'count': 30, 'radius': 0.02},
      {'name': 'Part-Dieu', 'lat': 45.7606, 'lng': 4.8566, 'count': 25, 'radius': 0.02},
      {'name': 'Croix-Rousse', 'lat': 45.7743, 'lng': 4.8326, 'count': 20, 'radius': 0.02},
      {'name': 'Vieux Lyon', 'lat': 45.7620, 'lng': 4.8270, 'count': 15, 'radius': 0.015},
      {'name': 'Guillotière', 'lat': 45.7530, 'lng': 4.8420, 'count': 15, 'radius': 0.02},
      {'name': 'Villeurbanne', 'lat': 45.7708, 'lng': 4.8803, 'count': 15, 'radius': 0.025},
      {'name': 'Gerland', 'lat': 45.7267, 'lng': 4.8267, 'count': 10, 'radius': 0.02},
      {'name': 'Vaise', 'lat': 45.7800, 'lng': 4.8040, 'count': 8, 'radius': 0.02},
      {'name': 'Monplaisir', 'lat': 45.7440, 'lng': 4.8700, 'count': 7, 'radius': 0.015},
      {'name': 'Perrache', 'lat': 45.7490, 'lng': 4.8260, 'count': 5, 'radius': 0.01},
    ];

    print('📍 LYON (30% - Études)');
    for (final zone in lyonZones) {
      await _generateZonesForArea(
        zone['name'] as String,
        zone['lat'] as double,
        zone['lng'] as double,
        zone['count'] as int,
        zone['radius'] as double,
        random,
        1095, // 3 ans d'études
        (count) => createdCount = count,
      );
    }

    // JAPON - 25% (125 zones) - Séjour actuel, exploration active
    final japonZones = [
      // Tokyo (exploration principale)
      {'name': 'Shibuya', 'lat': 35.6595, 'lng': 139.7004, 'count': 20, 'radius': 0.015},
      {'name': 'Shinjuku', 'lat': 35.6938, 'lng': 139.7036, 'count': 18, 'radius': 0.02},
      {'name': 'Akihabara', 'lat': 35.6984, 'lng': 139.7731, 'count': 12, 'radius': 0.015},
      {'name': 'Harajuku', 'lat': 35.6702, 'lng': 139.7027, 'count': 10, 'radius': 0.01},
      {'name': 'Asakusa', 'lat': 35.7148, 'lng': 139.7967, 'count': 10, 'radius': 0.015},
      {'name': 'Roppongi', 'lat': 35.6627, 'lng': 139.7290, 'count': 8, 'radius': 0.01},
      {'name': 'Ikebukuro', 'lat': 35.7295, 'lng': 139.7109, 'count': 8, 'radius': 0.015},
      {'name': 'Ueno', 'lat': 35.7141, 'lng': 139.7774, 'count': 6, 'radius': 0.015},
      // Kyoto (week-ends culturels)
      {'name': 'Kyoto Centre', 'lat': 35.0116, 'lng': 135.7681, 'count': 12, 'radius': 0.02},
      {'name': 'Arashiyama', 'lat': 35.0094, 'lng': 135.6686, 'count': 5, 'radius': 0.015},
      {'name': 'Gion', 'lat': 35.0037, 'lng': 135.7753, 'count': 5, 'radius': 0.01},
      // Osaka (sorties week-end)
      {'name': 'Osaka Namba', 'lat': 34.6686, 'lng': 135.5010, 'count': 7, 'radius': 0.015},
      {'name': 'Osaka Umeda', 'lat': 34.7024, 'lng': 135.4959, 'count': 4, 'radius': 0.015},
    ];

    print('📍 JAPON (25% - Séjour actuel)');
    for (final zone in japonZones) {
      await _generateZonesForArea(
        zone['name'] as String,
        zone['lat'] as double,
        zone['lng'] as double,
        zone['count'] as int,
        zone['radius'] as double,
        random,
        180, // 6 mois au Japon
        (count) => createdCount = count,
      );
    }

    // TRAJETS & AUTRES - 5% (25 zones) - Voyages, transits
    final autresZones = [
      {'name': 'Paris Centre', 'lat': 48.8566, 'lng': 2.3522, 'count': 8, 'radius': 0.025},
      {'name': 'Paris CDG', 'lat': 49.0097, 'lng': 2.5479, 'count': 2, 'radius': 0.01},
      {'name': 'Narita Airport', 'lat': 35.7720, 'lng': 140.3929, 'count': 2, 'radius': 0.01},
      {'name': 'Mulhouse', 'lat': 47.7508, 'lng': 7.3359, 'count': 4, 'radius': 0.015},
      {'name': 'Colmar', 'lat': 48.0794, 'lng': 7.3582, 'count': 4, 'radius': 0.012},
      {'name': 'Bâle', 'lat': 47.5596, 'lng': 7.5886, 'count': 3, 'radius': 0.01},
      {'name': 'Freiburg', 'lat': 47.9990, 'lng': 7.8421, 'count': 2, 'radius': 0.01},
    ];

    print('📍 AUTRES (5% - Trajets & voyages)');
    for (final zone in autresZones) {
      await _generateZonesForArea(
        zone['name'] as String,
        zone['lat'] as double,
        zone['lng'] as double,
        zone['count'] as int,
        zone['radius'] as double,
        random,
        730, // 2 ans
        (count) => createdCount = count,
      );
    }

    setState(() {
      _explorationPercentage = _exploredAreas.length / 510000000000 * 100;
    });

    print('✅ $createdCount zones de test créées - Votre parcours complet simulé !');
    print('   🏠 Strasbourg: ~200 zones');
    print('   🎓 Lyon: ~150 zones');
    print('   🇯🇵 Japon: ~125 zones');
    print('   ✈️ Autres: ~25 zones');
  }

  Future<void> _generateZonesForArea(
    String name,
    double centerLat,
    double centerLng,
    int count,
    double maxRadius,
    Random random,
    int maxDaysAgo,
    Function(int) updateCount,
  ) async {
    print('   📌 $name: $count zones...');
    
    for (int i = 0; i < count; i++) {
      // Distribution gaussienne pour concentration au centre
      final distance = maxRadius * sqrt(random.nextDouble());
      final angle = random.nextDouble() * 2 * pi;
      
      final lat = centerLat + (distance * cos(angle));
      final lng = centerLng + (distance * sin(angle));

      // Timestamp progressif selon l'ancienneté de la zone
      final daysAgo = random.nextInt(maxDaysAgo);
      final timestamp = DateTime.now().subtract(Duration(days: daysAgo));

      final area = ExploredArea(
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
      );

      await _databaseService.insertExploredArea(area);
      _exploredAreas.add(area);
      
      final currentCount = _exploredAreas.length;
      updateCount(currentCount);

      // Log tous les 50 zones (ajusté pour 500 zones)
      if (currentCount % 50 == 0) {
        print('      ⏳ $currentCount zones créées au total...');
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'application a besoin d\'accéder à votre position pour fonctionner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Afficher l'écran selon l'onglet sélectionné
          if (_currentTab == 0)
            SettingsScreen(
              exploredAreas: _exploredAreas,
              displayRadius: _displayRadius,
              onDisplayRadiusChanged: (newRadius) {
                setState(() {
                  _displayRadius = newRadius;
                });
              },
              isDarkFog: _isDarkFog,
              onFogThemeChanged: (isDark) {
                setState(() {
                  _isDarkFog = isDark;
                });
              },
              onDataChanged: () async {
                final areas = await _databaseService.getAllExploredAreas();
                setState(() {
                  _exploredAreas = areas;
                  _explorationPercentage = areas.length / 510000000000 * 100;
                });
              },
            )
          else if (_currentTab == 1)
            _buildMapView()
          else
            StatsScreen(
              exploredAreas: _exploredAreas,
              currentPosition: _currentPosition,
              isDarkFog: _isDarkFog,
            ),
          
          // Barre de navigation flottante en bas
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildFloatingNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // Google Maps
        GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: _currentPosition != null
                ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                : const LatLng(48.8566, 2.3522), // Paris par défaut
            zoom: 15.0,
            bearing: 0.0, // Orientation fixe vers le nord
          ),
          onCameraMove: (position) {
            setState(() {
              _mapCenter = position.target;
              _mapZoom = position.zoom;
            });
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          rotateGesturesEnabled: false, // Désactiver la rotation
          tiltGesturesEnabled: false,   // Désactiver l'inclinaison
        ),
        
        // Overlay de fog of war
        Positioned.fill(
          child: IgnorePointer(
            child: FogOfWarOverlay(
              exploredAreas: _exploredAreas,
              isDarkTheme: _isDarkFog,
              playerPosition: _currentPosition,
              displayRadius: _displayRadius,
              mapZoom: _mapZoom,
              mapCenter: _mapCenter,
            ),
          ),
        ),
        
        // Bouton de centrage
        Positioned(
          top: 60,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'center',
            onPressed: () {
              if (_currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    15.0,
                  ),
                );
              }
            },
            backgroundColor: _isDarkFog ? Colors.grey[850] : Colors.white,
            child: Icon(
              Icons.my_location, 
              color: _isDarkFog ? Colors.white : Colors.blue,
            ),
          ),
        ),
        
        // Indicateur de progression
        Positioned(
          top: 60,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkFog ? Colors.black87 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_explorationPercentage.toStringAsFixed(7)}%',
              style: TextStyle(
                color: _isDarkFog ? Colors.white : Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: _isDarkFog ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.settings,
            label: 'Réglages',
            isSelected: _currentTab == 0,
            onTap: () => setState(() => _currentTab = 0),
          ),
          _buildNavButton(
            icon: Icons.map,
            label: 'Carte',
            isSelected: _currentTab == 1,
            onTap: () => setState(() => _currentTab = 1),
          ),
          _buildNavButton(
            icon: Icons.bar_chart,
            label: 'Stats',
            isSelected: _currentTab == 2,
            onTap: () => setState(() => _currentTab = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(35),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected 
                      ? Colors.blueAccent 
                      : (_isDarkFog ? Colors.white54 : Colors.black45),
                  size: 28,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.blueAccent 
                        : (_isDarkFog ? Colors.white54 : Colors.black45),
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
