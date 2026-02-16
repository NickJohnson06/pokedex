import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DailyRotationService {
  static const _kDateKey = 'daily_date';
  static const _kIdKey = 'daily_id';

  /// Get the ID of today's Pokémon. If the day changed, rolls a new one.
  /// Needs a maxId to know the range (e.g. repo count).
  static Future<int> getDailyId(int maxId) async {
    if (maxId <= 0) return 1;

    final now = DateTime.now();
    // Create a seed from today's date (e.g., 20231027)
    final seed = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
    
    // Use the seed to ensure deterministic "random" for the day
    final random = Random(seed);
    
    // Return a number between 1 and maxId (inclusive)
    return random.nextInt(maxId) + 1;
  }
}
