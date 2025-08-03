import 'package:flutter/material.dart';
import '../themes/app_colors.dart';
import '../../features/tasks/domain/entities/task.dart';

class TaskFormatters {
  TaskFormatters._();

  static String formatDueDate(DateTime? dueDate, {DateTime? now}) {
    if (dueDate == null) return '';

    final currentTime = now ?? DateTime.now();
    
    // Normalize dates to compare by day only (same logic as filter)
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateNormalized = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateNormalized.isBefore(today)) {
      return 'Overdue';
    } else if (dueDateNormalized.isAtSameMomentAs(today)) {
      return 'Due today';
    } else if (dueDateNormalized.isAtSameMomentAs(tomorrow)) {
      return 'Due tomorrow';
    } else {
      final difference = dueDateNormalized.difference(today).inDays;
      if (difference <= 7) {
        return 'Due in $difference days';
      } else {
        return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    }
  }

  static Color getDueDateColor(DateTime? dueDate, {DateTime? now}) {
    if (dueDate == null) return AppColors.onSurfaceVariant;

    final currentTime = now ?? DateTime.now();
    
    // Normalize dates to compare by day only (same logic as filter)
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateNormalized = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateNormalized.isBefore(today)) {
      return AppColors.error;
    } else if (dueDateNormalized.isAtSameMomentAs(today) || dueDateNormalized.isAtSameMomentAs(tomorrow)) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
    }
  }

  static IconData getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_actions;
      case TaskStatus.inProgress:
        return Icons.work_outline;
      case TaskStatus.completed:
        return Icons.check_circle;
    }
  }

  static IconData getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  static String getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  static String getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}