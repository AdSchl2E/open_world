import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/map_screen.dart';
import 'services/background_tracking_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger les variables d'environnement
  await dotenv.load(fileName: ".env");
  
  // Initialiser le service de tracking en arrière-plan
  await BackgroundTrackingService().initialize();
  
  // Démarrer automatiquement le tracking si l'utilisateur l'avait activé
  await BackgroundTrackingService().startTrackingIfEnabled();
  
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
