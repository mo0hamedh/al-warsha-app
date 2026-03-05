import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class LocalStorageService {
  static Box get tasksBox => Hive.box('tasks');
  static Box get habitsBox => Hive.box('habits');
  static Box get settingsBox => Hive.box('settings');
  
  // حفظ المهام محلياً
  static Future<void> saveTasks(List<dynamic> tasks) async {
    await tasksBox.put('cached_tasks', jsonEncode(tasks));
  }
  
  // جلب المهام المحلية
  static List<dynamic> getCachedTasks() {
    final data = tasksBox.get('cached_tasks');
    if (data == null) return [];
    return jsonDecode(data);
  }
  
  // حفظ العادات محلياً  
  static Future<void> saveHabits(List<dynamic> habits) async {
    await habitsBox.put('cached_habits', jsonEncode(habits));
  }

  static List<dynamic> getCachedHabits() {
    final data = habitsBox.get('cached_habits');
    if (data == null) return [];
    return jsonDecode(data);
  }

  // Auto-lock last check
  static Future<void> setLastLockCheck(DateTime date) async {
    await settingsBox.put('lastLockCheck', date.toIso8601String());
  }

  static Future<DateTime?> getLastLockCheck() async {
    final data = settingsBox.get('lastLockCheck');
    if (data == null) return null;
    return DateTime.tryParse(data.toString());
  }
}
