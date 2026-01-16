import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Manages temporary storage for positions discovered in background
class BackgroundStorage {
  static const String _keyPendingPositions = 'pending_background_positions';

  // Saves a position discovered in background
  static Future<void> savePendingPosition(double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getPendingPositions();
    
    existing.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_keyPendingPositions, jsonEncode(existing));
    print('💾 Saved background position: $latitude, $longitude');
  }

  // Gets all pending positions from background
  static Future<List<Map<String, dynamic>>> getPendingPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyPendingPositions);
    
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('⚠️ Error reading pending positions: $e');
      return [];
    }
  }

  // Clears all pending positions after sync
  static Future<void> clearPendingPositions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingPositions);
    print('🗑️ Cleared pending background positions');
  }

  // Checks if there are pending positions to sync
  static Future<bool> hasPendingPositions() async {
    final positions = await getPendingPositions();
    return positions.isNotEmpty;
  }
}
