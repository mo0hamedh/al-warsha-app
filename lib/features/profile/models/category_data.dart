import 'package:flutter/material.dart';

class TaskCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isCustom;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'colorValue': color.value, // Note: consider color.value
      'isCustom': isCustom,
    };
  }

  factory TaskCategory.fromMap(Map<String, dynamic> map, String docId) {
    return TaskCategory(
      id: docId,
      name: map['name'] ?? 'أخرى',
      icon: IconData(
        map['iconCodePoint'] ?? Icons.more_horiz.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
        fontPackage: map['iconFontPackage'],
      ),
      color: Color(map['colorValue'] ?? 0xFF78909C),
      isCustom: map['isCustom'] ?? true,
    );
  }
}

const List<TaskCategory> taskCategories = [
  TaskCategory(id: 'study', name: 'دراسة', icon: Icons.school, color: Color(0xFF4FC3F7)),
  TaskCategory(id: 'work', name: 'شغل', icon: Icons.work, color: theme.accentColor),
  TaskCategory(id: 'project', name: 'مشروع', icon: Icons.rocket_launch, color: Color(0xFFAB47BC)),
  TaskCategory(id: 'personal', name: 'شخصي', icon: Icons.person, color: Color(0xFF66BB6A)),
  TaskCategory(id: 'other', name: 'أخرى', icon: Icons.more_horiz, color: Color(0xFF78909C)),
];
