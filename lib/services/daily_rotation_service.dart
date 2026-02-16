import 'dart:math';

class DailyRotationService {
  static Future<int> getDailyId(int maxId) async {
    if (maxId <= 0) return 1;

    final now = DateTime.now();
    final seed = int.parse('${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}');
    
    final random = Random(seed);
    
    return random.nextInt(maxId) + 1;
  }
}
