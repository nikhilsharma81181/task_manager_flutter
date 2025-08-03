import 'package:flutter/material.dart';

class TaskCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class TaskCategories {
  static const List<TaskCategory> categories = [
    TaskCategory(
      id: 'work',
      name: 'Work',
      icon: Icons.work_rounded,
      color: Color(0xFF3B82F6), // Blue
    ),
    TaskCategory(
      id: 'personal',
      name: 'Personal',
      icon: Icons.person_rounded,
      color: Color(0xFF10B981), // Green
    ),
    TaskCategory(
      id: 'health',
      name: 'Health',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEF4444), // Red
    ),
    TaskCategory(
      id: 'education',
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF8B5CF6), // Purple
    ),
    TaskCategory(
      id: 'finance',
      name: 'Finance',
      icon: Icons.attach_money_rounded,
      color: Color(0xFFF59E0B), // Yellow
    ),
    TaskCategory(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_cart_rounded,
      color: Color(0xFFEC4899), // Pink
    ),
  ];

  static TaskCategory? getCategoryById(String id) {
    try {
      return categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  static String getCategoryName(String id) {
    final category = getCategoryById(id);
    return category?.name ?? 'Unknown';
  }

  static IconData getCategoryIcon(String id) {
    final category = getCategoryById(id);
    return category?.icon ?? Icons.category_rounded;
  }

  static Color getCategoryColor(String id) {
    final category = getCategoryById(id);
    return category?.color ?? const Color(0xFF6B7280); // Gray
  }
}