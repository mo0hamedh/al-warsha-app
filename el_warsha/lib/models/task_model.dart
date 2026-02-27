import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final int estimatedMinutes;
  final String category;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.estimatedMinutes = 0,
    this.category = 'other',
  });

  factory TaskModel.fromMap(Map<String, dynamic> data, String documentId) {
    return TaskModel(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      estimatedMinutes: data['estimatedMinutes'] ?? 0,
      category: data['category'] ?? 'other',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'estimatedMinutes': estimatedMinutes,
      'category': category,
    };
  }
}
