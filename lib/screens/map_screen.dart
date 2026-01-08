import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  double _currentRadius = ExploredArea.defaultRadius; // Zone radius preference
  bool _waitingForGps = false; // True when GPS is not available yet
  String? _gpsErrorMessage; // Error message to show user
  
  // Google Maps camera state
  LatLng _mapCenter = const LatLng(48.8566, 2.3522); // Paris default
  double _mapZoom = 14.0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    _currentRadius = prefs.getDouble('zone_radius') ?? ExploredArea.defaultRadius;
    print('📏 Zone radius loaded: ${_currentRadius}m');
    
    // Load explored areas from database
    _exploredAreas = await _databaseService.getAllExploredAreas();
    print('🗺️ Explored areas loaded: ${_exploredAreas.length}');
    
    // Calculate exploration percentage
    _explorationPercentage = ExplorationCalculator.calculateExplorationPercentage(_exploredAreas.length);
    
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _waitingForGps = true;
        _gpsErrorMessage = 'Location service is disabled. Please enable GPS in your device settings.';
      });
      // Still start tracking - it will work when GPS becomes available
      _startLocationTracking();
      _startGpsCheckTimer();
      return;
    }
    
    // Check permissions
    bool hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      _showPermissionDialog();
      setState(() {
        _isLoading = false;
        _waitingForGps = true;
        _gpsErrorMessage = 'Location permission denied. Please grant permission in settings.';
      });
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
        _waitingForGps = false;
        _gpsErrorMessage = null;
      });
      _centerMapOnPosition(position);
    } else {
      // Use last known position from explored areas
      _centerOnLastKnownPosition();
      setState(() {
        _isLoading = false;
        _waitingForGps = true;
        _gpsErrorMessage = 'Waiting for GPS signal...';
      });
    }

    // Start tracking
    _startLocationTracking();
  }
  
  Timer? _gpsCheckTimer;
  
  void _startGpsCheckTimer() {
    _gpsCheckTimer?.cancel();
    _gpsCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_waitingForGps) {
        _gpsCheckTimer?.cancel();
        return;
      }
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        bool hasPermission = await _locationService.checkPermissions();
        if (hasPermission) {
          _gpsCheckTimer?.cancel();
          await BackgroundTrackingService().startTrackingIfEnabled();
          Position? position = await _locationService.getCurrentPosition();
          if (position != null) {
            setState(() {
              _currentPosition = position;
              _waitingForGps = false;
              _gpsErrorMessage = null;
            });
            _centerMapOnPosition(position);
            _checkAndAddNewArea(position);
          }
        }
      }
    });
  }

  void _startLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = _locationService.getPositionStream(radius: _currentRadius).listen(
      (position) {
        final wasWaiting = _waitingForGps;
        setState(() {
          _currentPosition = position;
          _waitingForGps = false;
          _gpsErrorMessage = null;
        });
        // Center map when GPS signal is recovered
        if (wasWaiting) {
          _centerMapOnPosition(position);
        }
        _checkAndAddNewArea(position);
      },
      onError: (error) {
        print('📍 GPS Error: $error');
        setState(() {
          _waitingForGps = true;
          _gpsErrorMessage = 'GPS signal lost. Waiting for signal...';
        });
      },
    );
  }

  void _centerMapOnPosition(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          17.0,
        ),
      );
    }
  }

  void _centerOnLastKnownPosition() {
    if (_exploredAreas.isNotEmpty && _mapController != null) {
      // Get the most recent explored area
      final lastArea = _exploredAreas.last;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(lastArea.latitude, lastArea.longitude),
          17.0,
        ),
      );
    }
  }

  void _checkAndAddNewArea(Position position) {
    if (ExplorationCalculator.isNewArea(position, _exploredAreas, radius: _currentRadius)) {
      print('🆕 New zone to add!');
      _addExploredArea(position);
    }
  }

  Future<void> _addExploredArea(Position position) async {
    ExploredArea newArea = ExploredArea(
      latitude: position.latitude,
      longitude: position.longitude,
      radius: _currentRadius, // Use current radius preference
    );
    
    print('✅ New explored area added: ${position.latitude}, ${position.longitude}, radius: ${_currentRadius}m');
    
    await _databaseService.insertExploredArea(newArea);
    setState(() {
      _exploredAreas.add(newArea);
      _explorationPercentage = ExplorationCalculator.calculateExplorationPercentage(_exploredAreas.length);
    });
    
    print('📊 Total explored zones: ${_exploredAreas.length}');
  }

  void _onRadiusChanged(double newRadius) {
    setState(() {
      _currentRadius = newRadius;
    });
    // Restart tracking with new distance filter
    _positionStreamSubscription?.cancel();
    _startLocationTracking();
    print('📏 Radius changed to: ${newRadius}m, tracking restarted');
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
              onRadiusChanged: _onRadiusChanged,
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
              currentRadius: _currentRadius,
              waitingForGps: _waitingForGps,
              gpsErrorMessage: _gpsErrorMessage,
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
                      17.0, // Higher zoom for smaller default radius
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
