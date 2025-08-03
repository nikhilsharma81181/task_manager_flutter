import '../../features/tasks/domain/entities/task.dart';

class TaskSorter {
  TaskSorter._();

  /// Sorts tasks by completion status first, then by date urgency and priority
  /// Order: 
  /// 1. Incomplete tasks: Overdue (Urgent -> High -> Medium -> Low), 
  ///                     Due Today (Urgent -> High -> Medium -> Low),
  ///                     Due Tomorrow (Urgent -> High -> Medium -> Low), etc.
  /// 2. Completed tasks: At the very bottom
  static List<TaskEntity> sortByDateAndPriority(List<TaskEntity> tasks, {DateTime? now}) {
    final List<TaskEntity> sortedTasks = List.from(tasks);
    final referenceDate = now ?? DateTime.now();
    
    sortedTasks.sort((a, b) {
      // First: Completed tasks go to bottom
      if (a.status == TaskStatus.completed && b.status != TaskStatus.completed) {
        return 1; // a (completed) goes after b (incomplete)
      }
      if (b.status == TaskStatus.completed && a.status != TaskStatus.completed) {
        return -1; // b (completed) goes after a (incomplete)
      }
      
      // If both have same completion status, sort by date urgency
      final dateComparison = _compareDateUrgency(a, b, referenceDate);
      if (dateComparison != 0) return dateComparison;
      
      // Then sort by task priority (Urgent -> High -> Medium -> Low)
      return _comparePriority(a, b);
    });
    
    return sortedTasks;
  }

  /// Compares tasks by date urgency
  /// Returns: negative if a is more urgent, positive if b is more urgent, 0 if equal
  static int _compareDateUrgency(TaskEntity a, TaskEntity b, DateTime referenceDate) {
    final aDateScore = _getDateUrgencyScore(a.dueDate, referenceDate);
    final bDateScore = _getDateUrgencyScore(b.dueDate, referenceDate);
    
    return aDateScore.compareTo(bDateScore);
  }

  /// Gets urgency score for a due date (lower score = more urgent)
  static int _getDateUrgencyScore(DateTime? dueDate, DateTime referenceDate) {
    if (dueDate == null) return 1000; // No due date = least urgent
    
    final daysDifference = dueDate.difference(referenceDate).inDays;
    
    if (daysDifference < 0) return 0;  // Overdue = most urgent
    if (daysDifference == 0) return 1; // Due today
    if (daysDifference == 1) return 2; // Due tomorrow
    if (daysDifference <= 3) return 3; // Due within 3 days
    if (daysDifference <= 7) return 4; // Due within a week
    if (daysDifference <= 14) return 5; // Due within 2 weeks
    if (daysDifference <= 30) return 6; // Due within a month
    
    return 7; // Due later than a month
  }

  /// Compares tasks by priority (Urgent -> High -> Medium -> Low)
  static int _comparePriority(TaskEntity a, TaskEntity b) {
    // Higher priority enum index = higher priority
    // We want urgent (3) first, so we reverse the comparison
    return b.priority.index.compareTo(a.priority.index);
  }
}