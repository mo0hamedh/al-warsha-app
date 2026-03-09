import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTask {
  final String id;
  final String title;
  final String? description;
  final dynamic assignedTo;
  final DateTime? dueDate;
  final int points;
  final bool isActive;

  AdminTask({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    this.dueDate,
    this.points = 10,
    this.isActive = true,
  });

  factory AdminTask.fromMap(Map<String, dynamic> map, String id) {
    return AdminTask(
      id: id,
      title: map['title'] ?? '',
      description: map['description'],
      assignedTo: map['assignedTo'],
      dueDate: (map['dueDate'] as Timestamp?)?.toDate(),
      points: map['points'] ?? 10,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'points': points,
      'isActive': isActive,
    };
  }
}
