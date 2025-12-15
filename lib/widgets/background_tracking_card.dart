import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/background_tracking_service.dart';
import '../utils/app_notifications.dart';
import 'setting_card.dart';

/// Card to enable/disable background tracking
class BackgroundTrackingCard extends StatefulWidget {
  final bool isDarkFog;

  const BackgroundTrackingCard({
    super.key,
    required this.isDarkFog,
  });

  @override
  State<BackgroundTrackingCard> createState() => _BackgroundTrackingCardState();
}

class _BackgroundTrackingCardState extends State<BackgroundTrackingCard> {
  bool _isBackgroundTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTrackingState();
  }

  Future<void> _loadTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('background_tracking_enabled') ?? true;
    
    if (mounted) {
      setState(() {
        _isBackgroundTrackingEnabled = isEnabled;
      });
    }
  }

  Future<void> _saveTrackingState(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_tracking_enabled', enabled);
    print('💾 [Settings] Tracking state saved: $enabled');
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
            content: Text('Error: $e'),
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
        _isBackgroundTrackingEnabled = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingCard(
      icon: Icons.directions_run,
      title: 'Background tracking',
      subtitle: 'Record even when app is closed',
      isDarkFog: widget.isDarkFog,
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
}
