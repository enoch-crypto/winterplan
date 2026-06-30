import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const scheduleKey = 'schedule_v8';
  static const homeworkKey = 'homework_v8';
  static const logsKey = 'logs_v8';
  static const todosKey = 'todos_v1';

  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> clearWinterPlanData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(scheduleKey);
    await prefs.remove(homeworkKey);
    await prefs.remove(logsKey);
    await prefs.remove(todosKey);
  }
}
