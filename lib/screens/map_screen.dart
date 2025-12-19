import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../services/background_tracking_service.dart';
import '../models/explored_area.dart';
import '../utils/exploration_calculator.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/map_view.dart';
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
  int _currentTab = 1; // 0: Settings, 1: Map, 2: Stats
  bool _isDarkFog = true;
  
  // Google Maps camera state
  LatLng _mapCenter = const LatLng(48.8566, 2.3522); // Paris default
  double _mapZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load explored areas from database
    _exploredAreas = await _databaseService.getAllExploredAreas();
    print('🗺️ Explored areas loaded: ${_exploredAreas.length}');
    
    // Check permissions
    bool hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      _showPermissionDialog();
      setState(() => _isLoading = false);
      return;
    }

    // ✅ CRITICAL: Start background tracking after permissions are granted
    // This ensures tracking starts automatically on first launch
    await BackgroundTrackingService().startTrackingIfEnabled();

    // Get current position
    Position? position = await _locationService.getCurrentPosition();
    if (position != null) {
      print('📍 Current position: ${position.latitude}, ${position.longitude}');
      
      // Check and add current position as explored area (only if new)
      _checkAndAddNewArea(position);
      
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }

    // Start tracking
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionStreamSubscription = _locationService.getPositionStream().listen((position) {
      setState(() => _currentPosition = position);
      _checkAndAddNewArea(position);
    });
  }

  void _checkAndAddNewArea(Position position) {
    if (ExplorationCalculator.isNewArea(position, _exploredAreas)) {
      print('🆕 New zone to add!');
      _addExploredArea(position);
    }
  }

  Future<void> _addExploredArea(Position position) async {
    ExploredArea newArea = ExploredArea(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    
    print('✅ New explored area added: ${position.latitude}, ${position.longitude}, radius: 1000m');
    
    await _databaseService.insertExploredArea(newArea);
    setState(() {
      _exploredAreas.add(newArea);
      _explorationPercentage = ExplorationCalculator.calculateExplorationPercentage(_exploredAreas.length);
    });
    
    print('📊 Total explored zones: ${_exploredAreas.length}');
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission required'),
        content: const Text(
          'The application needs access to your location to function.',
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
          // Display screen according to selected tab
          if (_currentTab == 0)
            SettingsScreen(
              exploredAreas: _exploredAreas,
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
                  _explorationPercentage = ExplorationCalculator.calculateExplorationPercentage(areas.length);
                });
              },
            )
          else if (_currentTab == 1)
            MapView(
              currentPosition: _currentPosition,
              exploredAreas: _exploredAreas,
              explorationPercentage: _explorationPercentage,
              isDarkFog: _isDarkFog,
              onMapCreated: (controller) => _mapController = controller,
              onCameraMove: (position) {
                setState(() {
                  _mapCenter = position.target;
                  _mapZoom = position.zoom;
                });
              },
              onCenterPressed: () {
                if (_currentPosition != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      15.0,
                    ),
                  );
                }
              },
              mapCenter: _mapCenter,
              mapZoom: _mapZoom,
            )
          else
            StatsScreen(
              exploredAreas: _exploredAreas,
              currentPosition: _currentPosition,
              isDarkFog: _isDarkFog,
            ),
          
          // Floating navigation bar at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: FloatingNavBar(
              currentTab: _currentTab,
              onTabChanged: (tab) => setState(() => _currentTab = tab),
              isDarkTheme: _isDarkFog,
            ),
          ),
        ],
      ),
    );
  }
}
