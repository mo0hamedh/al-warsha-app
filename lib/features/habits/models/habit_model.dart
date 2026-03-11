import 'package:cloud_firestore/cloud_firestore.dart';

class HabitModel {
  final String id;
  final String name;
  final String type; // 'positive' or 'negative'
  final String category;
  final String icon;
  final String color;
  final int targetDays;
  final Timestamp startDate;
  final int currentStreak;
  final int longestStreak;
  final int totalCleanDays;
  final Timestamp? lastCheckIn;
  final bool isActive;

  HabitModel({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.icon,
    required this.color,
    required this.targetDays,
    required this.startDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCleanDays = 0,
    this.lastCheckIn,
    this.isActive = true,
  });

  factory HabitModel.fromMap(Map<String, dynamic> data, String id) {
    return HabitModel(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'positive',
      category: data['category'] ?? '',
      icon: data['icon'] ?? '',
      color: data['color'] ?? '#FF6A00',
      targetDays: data['targetDays'] ?? 21,
      startDate: data['startDate'] as Timestamp? ?? Timestamp.now(),
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      totalCleanDays: data['totalCleanDays'] ?? 0,
      lastCheckIn: data['lastCheckIn'] as Timestamp?,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'category': category,
      'icon': icon,
      'color': color,
      'targetDays': targetDays,
      'startDate': startDate,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'totalCleanDays': totalCleanDays,
      'lastCheckIn': lastCheckIn,
      'isActive': isActive,
    };
  }
}

class HabitLogModel {
  final String date; // Format: 'YYYY-MM-DD'
  final String status; // 'clean', 'slip', 'skip'
  final String? note;
  final int pointsEarned;

  HabitLogModel({
    required this.date,
    required this.status,
    this.note,
    this.pointsEarned = 0,
  });

  factory HabitLogModel.fromMap(Map<String, dynamic> data) {
    return HabitLogModel(
      date: data['date'] ?? '',
      status: data['status'] ?? 'skip',
      note: data['note'],
      pointsEarned: data['pointsEarned'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'status': status,
      'note': note,
      'pointsEarned': pointsEarned,
    };
  }
}
