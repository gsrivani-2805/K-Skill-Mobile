import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  static Future<void> setUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> setUserStreak(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', streak);
  }

  static Future<int?> getUserStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak');
  }

  static Future<void> setCurrentLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('level', level);
  }

  static Future<void> setCompletedLessons(
      String level, List<String> lessons) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('completed_$level', lessons);
  }

  static Future<List<String>> getCompletedLessons(String level) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('completed_$level') ?? [];
  }

  static Future<void> addCompletedLesson(String level, String lessonKey) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList('completed_$level') ?? [];

    if (!completed.contains(lessonKey)) {
      completed.add(lessonKey);
      await prefs.setStringList('completed_$level', completed);
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
