import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'location_service.dart';
import '../models/explored_area.dart';

/// Service pour le tracking GPS en arrière-plan
/// Utilise un foreground service Android avec notification persistante
@pragma('vm:entry-point')
class BackgroundTrackingService {
  static final BackgroundTrackingService _instance = BackgroundTrackingService._();
  factory BackgroundTrackingService() => _instance;
  BackgroundTrackingService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();
  final LocationService _locationService = LocationService();
  
  static const String _notificationChannelId = 'background_tracking';
  static const String _notificationChannelName = 'Exploration in progress';
  static const int _notificationId = 888;

  /// Initialise et démarre le service en arrière-plan
  Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Configuration des notifications Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Notification displayed during world exploration',
      importance: Importance.low, // Low to not disturb
      playSound: false,
      enableVibration: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configuration du service en arrière-plan
    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: true, // Mode foreground obligatoire pour Android
        autoStart: false,
        autoStartOnBoot: false,
        initialNotificationTitle: 'OpenWorld',
        initialNotificationContent: 'Démarrage...',
        foregroundServiceNotificationId: _notificationId,
      ),
    );
  }

  /// Démarre automatiquement le tracking si l'utilisateur l'avait activé
  Future<void> startTrackingIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('background_tracking_enabled') ?? true;
    
    if (isEnabled) {
      try {
        await startTracking();
        print('✅ Tracking started automatically');
      } catch (e) {
        print('⚠️ Automatic start error: $e');
      }
    }
  }

  /// Démarre le tracking en arrière-plan
  Future<void> startTracking() async {
    if (await _requestNotificationPermission()) {
      await FlutterBackgroundService().startService();
    } else {
      throw Exception('Permission de notification requise');
    }
  }

  /// Demande la permission d'afficher des notifications
  Future<bool> _requestNotificationPermission() async {
    final androidImpl = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      return await androidImpl.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  /// Arrête le tracking en arrière-plan
  Future<void> stopTracking() async {
    FlutterBackgroundService().invoke('stop');
  }

  /// Point d'entrée principal du service (appelé en arrière-plan)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('🚀 Background service started');
    DartPluginRegistrant.ensureInitialized();

    final notifications = FlutterLocalNotificationsPlugin();
    final databaseService = DatabaseService();
    final locationService = LocationService();

    // Initialiser les notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    await notifications.initialize(const InitializationSettings(android: androidSettings));

    // Créer le canal de notification
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Persistent notification during exploration',
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );
    await notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show notification
    await _showNotification(notifications);
    
    // Update foreground service
    if (service is AndroidServiceInstance) {
      await service.setForegroundNotificationInfo(
        title: 'Exploration in progress',
        content: 'Disable in Settings > Exploration',
      );
    }

    // Stream de positions GPS
    StreamSubscription<Position>? positionSubscription;

    try {
      // Vérifier les permissions GPS
      if (!await locationService.checkPermissions()) {
        print('⚠️ No GPS permission');
        service.stopSelf();
        return;
      }

      // Écouter la commande d'arrêt
      service.on('stop').listen((event) {
        service.stopSelf();
        print('🛑 Service stopped');
      });

      // Écouter les changements de position
      positionSubscription = locationService.getPositionStream().listen(
        (Position position) async {
          // Vérifier si c'est une nouvelle zone (500m minimum)
          final existingAreas = await databaseService.getAllExploredAreas();
          if (_isNewArea(position, existingAreas)) {
            await databaseService.insertExploredArea(
              ExploredArea(latitude: position.latitude, longitude: position.longitude),
            );
            print('✅ New zone: ${position.latitude}, ${position.longitude}');
          }
        },
        onError: (error) => print('❌ GPS error: $error'),
      );

      // Boucle pour maintenir le service actif
      while (true) {
        await Future.delayed(const Duration(seconds: 10));
      }
    } catch (e) {
      print('❌ Service error: $e');
    } finally {
      positionSubscription?.cancel();
      service.stopSelf();
    }
  }

  /// Callback iOS (obligatoire mais non utilisé ici)
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  /// Affiche la notification de tracking
  @pragma('vm:entry-point')
  static Future<void> _showNotification(FlutterLocalNotificationsPlugin notifications) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _notificationChannelId,
      _notificationChannelName,
      channelDescription: 'Persistent notification during exploration',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
      showWhen: true,
      usesChronometer: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.service,
      icon: '@drawable/ic_notification',
    );

    await notifications.show(
      _notificationId,
      'Exploration in progress',
      'Disable in Settings > Exploration',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Vérifie si une position représente une nouvelle zone
  @pragma('vm:entry-point')
  static bool _isNewArea(Position position, List<ExploredArea> existingAreas) {
    const double minDistance = 500.0; // 500m minimum entre zones

    for (var area in existingAreas) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        area.latitude,
        area.longitude,
      );

      if (distance < minDistance) {
        return false; // Trop proche d'une zone existante
      }
    }

    return true; // Nouvelle zone
  }
}
