import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const _streakKey = 'daily_streak';
  static const _lastSeenKey = 'last_seen_date';

  Future<Map<String, dynamic>> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastSeenStr = prefs.getString(_lastSeenKey);
    int streak = prefs.getInt(_streakKey) ?? 0;
    DateTime? lastSeen;

    if (lastSeenStr != null) {
      lastSeen = DateTime.parse(lastSeenStr);
      final lastDate = DateTime(lastSeen.year, lastSeen.month, lastSeen.day);
      final diff = today.difference(lastDate).inDays;

      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_lastSeenKey, today.toIso8601String());
    
    return {
      'streak': streak,
      'lastSeen': lastSeen,
    };
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }
}
