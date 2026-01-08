import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DailyRotationService {
  static const _kDateKey = 'daily_date';
  static const _kIdKey = 'daily_id';

  /// Get the ID of today's Pokémon. If the day changed, rolls a new one.
  /// Needs a maxId to know the range (e.g. repo count).
  static Future<int> getDailyId(int maxId) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final savedDate = prefs.getString(_kDateKey);
    final savedId = prefs.getInt(_kIdKey);

    if (savedDate == todayStr && savedId != null && savedId <= maxId) {
      return savedId;
    }

    // New day or first run: roll dice
    // ID range 1..maxId
    final newId = maxId > 0 ? Random().nextInt(maxId) + 1 : 1; 
    
    await prefs.setString(_kDateKey, todayStr);
    await prefs.setInt(_kIdKey, newId);
    
    return newId;
  }
}
