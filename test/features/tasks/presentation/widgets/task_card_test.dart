import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/themes/app_colors.dart';
import 'package:task_manager_flutter/core/utils/task_formatters.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

void main() {
  group('TaskFormatters Tests', () {
    group('formatDueDate()', () {
      test('returns "Overdue" for past dates', () {
        final pastDate = DateTime(2024, 1, 1, 10, 0);
        expect(TaskFormatters.formatDueDate(pastDate, now: DateTime(2024, 1, 2, 10, 0)), equals('Overdue'));
      });

      test('returns "Due today" for current date', () {
        final today = DateTime(2024, 1, 1, 10, 0);
        expect(TaskFormatters.formatDueDate(today, now: DateTime(2024, 1, 1, 10, 0)), equals('Due today'));
      });

      test('returns "Due tomorrow" for next day', () {
        final tomorrow = DateTime(2024, 1, 2, 10, 0);
        expect(TaskFormatters.formatDueDate(tomorrow, now: DateTime(2024, 1, 1, 10, 0)), equals('Due tomorrow'));
      });

      test('returns "Due in X days" for dates within a week', () {
        final threeDaysLater = DateTime(2024, 1, 4, 10, 0);
        expect(TaskFormatters.formatDueDate(threeDaysLater, now: DateTime(2024, 1, 1, 10, 0)), equals('Due in 3 days'));
      });

      test('returns formatted date for dates beyond a week', () {
        final tenDaysLater = DateTime(2024, 1, 11, 10, 0);
        expect(TaskFormatters.formatDueDate(tenDaysLater, now: DateTime(2024, 1, 1, 10, 0)), equals('11/1/2024'));
      });

      test('returns empty string for null dates', () {
        expect(TaskFormatters.formatDueDate(null), equals(''));
      });
    });

    group('getDueDateColor()', () {
      test('returns error color for overdue tasks', () {
        final pastDate = DateTime(2024, 1, 1, 10, 0);
        expect(TaskFormatters.getDueDateColor(pastDate, now: DateTime(2024, 1, 2, 10, 0)), equals(AppColors.error));
      });

      test('returns warning color for due today', () {
        final today = DateTime(2024, 1, 1, 10, 0);
        expect(TaskFormatters.getDueDateColor(today, now: DateTime(2024, 1, 1, 10, 0)), equals(AppColors.warning));
      });

      test('returns warning color for due tomorrow', () {
        final tomorrow = DateTime(2024, 1, 2, 10, 0);
        expect(TaskFormatters.getDueDateColor(tomorrow, now: DateTime(2024, 1, 1, 10, 0)), equals(AppColors.warning));
      });

      test('returns success color for tasks due in 3+ days', () {
        final threeDaysLater = DateTime(2024, 1, 4, 10, 0);
        expect(TaskFormatters.getDueDateColor(threeDaysLater, now: DateTime(2024, 1, 1, 10, 0)), equals(AppColors.success));
      });

      test('returns onSurfaceVariant color for null due date', () {
        expect(TaskFormatters.getDueDateColor(null), equals(AppColors.onSurfaceVariant));
      });
    });

    group('getStatusColor()', () {
      test('returns statusPending color for pending tasks', () {
        expect(TaskFormatters.getStatusColor(TaskStatus.pending), equals(AppColors.statusPending));
      });

      test('returns statusInProgress color for in progress tasks', () {
        expect(TaskFormatters.getStatusColor(TaskStatus.inProgress), equals(AppColors.statusInProgress));
      });

      test('returns statusCompleted color for completed tasks', () {
        expect(TaskFormatters.getStatusColor(TaskStatus.completed), equals(AppColors.statusCompleted));
      });
    });

    group('getPriorityColor()', () {
      test('returns priorityLow color for low priority', () {
        expect(TaskFormatters.getPriorityColor(TaskPriority.low), equals(AppColors.priorityLow));
      });

      test('returns priorityMedium color for medium priority', () {
        expect(TaskFormatters.getPriorityColor(TaskPriority.medium), equals(AppColors.priorityMedium));
      });

      test('returns priorityHigh color for high priority', () {
        expect(TaskFormatters.getPriorityColor(TaskPriority.high), equals(AppColors.priorityHigh));
      });

      test('returns priorityUrgent color for urgent priority', () {
        expect(TaskFormatters.getPriorityColor(TaskPriority.urgent), equals(AppColors.priorityUrgent));
      });
    });

    group('getStatusIcon()', () {
      test('returns pending_actions icon for pending status', () {
        expect(TaskFormatters.getStatusIcon(TaskStatus.pending), equals(Icons.pending_actions));
      });

      test('returns work_outline icon for in progress status', () {
        expect(TaskFormatters.getStatusIcon(TaskStatus.inProgress), equals(Icons.work_outline));
      });

      test('returns check_circle icon for completed status', () {
        expect(TaskFormatters.getStatusIcon(TaskStatus.completed), equals(Icons.check_circle));
      });
    });
  });
}

