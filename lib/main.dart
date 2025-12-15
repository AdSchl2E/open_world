import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/map_screen.dart';
import 'services/background_tracking_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize background tracking service
  await BackgroundTrackingService().initialize();
  
  // IMPORTANT: Only start tracking if permissions are already granted
  // If not granted yet, MapScreen will request them and start tracking
  final locationService = LocationService();
  final hasPermissions = await locationService.checkPermissions(requestIfNeeded: false);
  
  if (hasPermissions) {
    // Start tracking automatically if user had enabled it
    await BackgroundTrackingService().startTrackingIfEnabled();
  } else {
    print('⏳ Waiting for permissions before starting background service');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open World',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
