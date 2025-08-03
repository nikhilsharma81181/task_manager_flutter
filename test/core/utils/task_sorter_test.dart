import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/core/utils/task_sorter.dart';
import 'package:task_manager_flutter/features/tasks/domain/entities/task.dart';

void main() {
  group('TaskSorter', () {
    test('sorts tasks by date urgency first, then priority', () {
      final now = DateTime(2024, 1, 1);
      final tasks = [
        // Low priority, due tomorrow  
        TaskEntity(
          id: '1',
          title: 'Low Tomorrow',
          description: '',
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.add(const Duration(days: 1)),
        ),
        // High priority, due next week
        TaskEntity(
          id: '2', 
          title: 'High Next Week',
          description: '',
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.add(const Duration(days: 7)),
        ),
        // Urgent priority, overdue
        TaskEntity(
          id: '3',
          title: 'Urgent Overdue', 
          description: '',
          priority: TaskPriority.urgent,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.subtract(const Duration(days: 1)),
        ),
        // Medium priority, due today
        TaskEntity(
          id: '4',
          title: 'Medium Today',
          description: '',
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          categoryId: 'work', 
          createdAt: now,
          lastModified: now,
          dueDate: now,
        ),
        // Completed high priority task (should go to bottom)
        TaskEntity(
          id: '5',
          title: 'Completed High',
          description: '',
          priority: TaskPriority.high,
          status: TaskStatus.completed,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.subtract(const Duration(days: 2)),
        ),
      ];

      final sorted = TaskSorter.sortByDateAndPriority(tasks, now: now);

      // Expected order: Urgent Overdue, Medium Today, Low Tomorrow, High Next Week, Completed High
      expect(sorted[0].title, equals('Urgent Overdue')); // Overdue wins over everything
      expect(sorted[1].title, equals('Medium Today')); // Due today  
      expect(sorted[2].title, equals('Low Tomorrow')); // Due tomorrow
      expect(sorted[3].title, equals('High Next Week')); // Due later
      expect(sorted[4].title, equals('Completed High')); // Completed tasks at bottom
    });

    test('sorts tasks with same date urgency by priority', () {
      final now = DateTime(2024, 1, 1);
      final dueDate = now.add(const Duration(days: 3));
      
      final tasks = [
        TaskEntity(
          id: '1',
          title: 'Low Priority',
          description: '',
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: dueDate,
        ),
        TaskEntity(
          id: '2',
          title: 'Urgent Priority',
          description: '',
          priority: TaskPriority.urgent,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: dueDate,
        ),
        TaskEntity(
          id: '3',
          title: 'Medium Priority',
          description: '',
          priority: TaskPriority.medium,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: dueDate,
        ),
      ];

      final sorted = TaskSorter.sortByDateAndPriority(tasks, now: now);

      // Should be sorted by priority: Urgent -> Medium -> Low
      expect(sorted[0].title, equals('Urgent Priority'));
      expect(sorted[1].title, equals('Medium Priority'));
      expect(sorted[2].title, equals('Low Priority'));
    });

    test('handles tasks without due dates', () {
      final now = DateTime(2024, 1, 1);
      
      final tasks = [
        TaskEntity(
          id: '1',
          title: 'No Due Date High',
          description: '',
          priority: TaskPriority.high,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: null,
        ),
        TaskEntity(
          id: '2',
          title: 'Due Tomorrow Low',
          description: '',
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.add(const Duration(days: 1)),
        ),
      ];

      final sorted = TaskSorter.sortByDateAndPriority(tasks, now: now);

      // Task with due date should come first (more urgent)
      expect(sorted[0].title, equals('Due Tomorrow Low'));
      expect(sorted[1].title, equals('No Due Date High'));
    });

    test('puts completed tasks at the bottom regardless of priority or due date', () {
      final now = DateTime(2024, 1, 1);
      
      final tasks = [
        TaskEntity(
          id: '1',
          title: 'Completed Urgent Overdue',
          description: '',
          priority: TaskPriority.urgent,
          status: TaskStatus.completed,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.subtract(const Duration(days: 1)),
        ),
        TaskEntity(
          id: '2',
          title: 'Pending Low Next Week',
          description: '',
          priority: TaskPriority.low,
          status: TaskStatus.pending,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now.add(const Duration(days: 7)),
        ),
        TaskEntity(
          id: '3',
          title: 'Completed High Due Today',
          description: '',
          priority: TaskPriority.high,
          status: TaskStatus.completed,
          categoryId: 'work',
          createdAt: now,
          lastModified: now,
          dueDate: now,
        ),
      ];

      final sorted = TaskSorter.sortByDateAndPriority(tasks, now: now);

      // Incomplete task should come first, even if it's low priority and due later
      expect(sorted[0].title, equals('Pending Low Next Week'));
      // Completed tasks should be at the bottom, regardless of priority/due date
      expect(sorted[1].title, equals('Completed Urgent Overdue'));
      expect(sorted[2].title, equals('Completed High Due Today'));
    });
  });
}