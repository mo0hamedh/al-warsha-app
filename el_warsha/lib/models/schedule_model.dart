import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleHabitModel {
  final String id;
  final String name;
  final String icon;
  final String type; // 'checkbox' or 'number'

  ScheduleHabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory ScheduleHabitModel.fromMap(Map<String, dynamic> data) {
    return ScheduleHabitModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      icon: data['icon'] ?? '',
      type: data['type'] ?? 'checkbox',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
    };
  }
}

class WeeklyScheduleModel {
  final String id;
  final int weekNumber;
  final String month; // '2026-02'
  final List<ScheduleHabitModel> habits;
  final Timestamp createdAt;
  final bool isActive;

  WeeklyScheduleModel({
    required this.id,
    required this.weekNumber,
    required this.month,
    required this.habits,
    required this.createdAt,
    this.isActive = true,
  });

  factory WeeklyScheduleModel.fromMap(Map<String, dynamic> data, String id) {
    return WeeklyScheduleModel(
      id: id,
      weekNumber: data['weekNumber'] ?? 1,
      month: data['month'] ?? '',
      habits: (data['habits'] as List<dynamic>?)
              ?.map((h) => ScheduleHabitModel.fromMap(h as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'month': month,
      'habits': habits.map((h) => h.toMap()).toList(),
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}

class ScheduleProgressModel {
  final String weekId;
  final String userId;
  final Map<String, dynamic> days; 
  // e.g: { 'السبت': { 'بث الورشة': true, 'ذاكرت كام مسألة': 5 } }
  final double completionRate;
  final int totalPoints;
  final Timestamp lastUpdated;

  ScheduleProgressModel({
    required this.weekId,
    required this.userId,
    required this.days,
    this.completionRate = 0.0,
    this.totalPoints = 0,
    required this.lastUpdated,
  });

  factory ScheduleProgressModel.fromMap(Map<String, dynamic> data) {
    return ScheduleProgressModel(
      weekId: data['weekId'] ?? '',
      userId: data['userId'] ?? '',
      days: Map<String, dynamic>.from(data['days'] ?? {}),
      completionRate: (data['completionRate'] ?? 0.0).toDouble(),
      totalPoints: data['totalPoints'] ?? 0,
      lastUpdated: data['lastUpdated'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekId': weekId,
      'userId': userId,
      'days': days,
      'completionRate': completionRate,
      'totalPoints': totalPoints,
      'lastUpdated': lastUpdated,
    };
  }
}
