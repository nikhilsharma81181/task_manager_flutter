import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/tasks/domain/entities/task.dart';

class UserBehaviorAnalytics {
  final double avgCompletionTime; // in days
  final double priorityAccuracy; // 0.0 to 1.0
  final Map<TaskPriority, double> priorityCompletionRates;
  final Map<String, double> categoryCompletionRates;
  final double overdueTasksRate;
  final int totalCompletedTasks;

  const UserBehaviorAnalytics({
    required this.avgCompletionTime,
    required this.priorityAccuracy,
    required this.priorityCompletionRates,
    required this.categoryCompletionRates,
    required this.overdueTasksRate,
    required this.totalCompletedTasks,
  });
}

class TaskCompletionData {
  final String taskId;
  final String categoryId;
  final TaskPriority originalPriority;
  final TaskPriority? adjustedPriority;
  final DateTime createdAt;
  final DateTime completedAt;
  final DateTime? dueDate;
  final bool wasOverdue;
  final int daysToComplete;

  const TaskCompletionData({
    required this.taskId,
    required this.categoryId,
    required this.originalPriority,
    this.adjustedPriority,
    required this.createdAt,
    required this.completedAt,
    this.dueDate,
    required this.wasOverdue,
    required this.daysToComplete,
  });

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'categoryId': categoryId,
        'originalPriority': originalPriority.index,
        'adjustedPriority': adjustedPriority?.index,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'wasOverdue': wasOverdue,
        'daysToComplete': daysToComplete,
      };

  factory TaskCompletionData.fromJson(Map<String, dynamic> json) =>
      TaskCompletionData(
        taskId: json['taskId'],
        categoryId: json['categoryId'],
        originalPriority: TaskPriority.values[json['originalPriority']],
        adjustedPriority: json['adjustedPriority'] != null
            ? TaskPriority.values[json['adjustedPriority']]
            : null,
        createdAt: DateTime.parse(json['createdAt']),
        completedAt: DateTime.parse(json['completedAt']),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        wasOverdue: json['wasOverdue'],
        daysToComplete: json['daysToComplete'],
      );
}

class UserAnalyticsService {
  static const String _completionDataKey = 'task_completion_data';
  static const String _analyticsKey = 'user_analytics';
  static const int _maxStoredCompletions = 200; // Keep last 200 completions

  /// Records task completion for analytics
  Future<void> recordTaskCompletion(TaskEntity task,
      {TaskPriority? adjustedPriority}) async {
    final completionData = TaskCompletionData(
      taskId: task.id,
      categoryId: task.categoryId,
      originalPriority: task.priority,
      adjustedPriority: adjustedPriority,
      createdAt: task.createdAt,
      completedAt: DateTime.now(),
      dueDate: task.dueDate,
      wasOverdue: task.dueDate != null && DateTime.now().isAfter(task.dueDate!),
      daysToComplete: DateTime.now().difference(task.createdAt).inDays,
    );

    var existingData = await getStoredCompletionData();
    existingData.add(completionData);

    // Keep only the most recent completions
    if (existingData.length > _maxStoredCompletions) {
      existingData.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      existingData = existingData.take(_maxStoredCompletions).toList();
    }

    await _saveCompletionData(existingData);
    await _updateAnalytics(existingData);
  }

  /// Gets current user behavior analytics
  Future<UserBehaviorAnalytics> getUserAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final analyticsJson = prefs.getString(_analyticsKey);

    if (analyticsJson != null) {
      final data = jsonDecode(analyticsJson);
      return UserBehaviorAnalytics(
        avgCompletionTime: data['avgCompletionTime'],
        priorityAccuracy: data['priorityAccuracy'],
        priorityCompletionRates: Map<TaskPriority, double>.from(
            data['priorityCompletionRates'].map((key, value) => MapEntry(
                TaskPriority.values[int.parse(key)], value.toDouble()))),
        categoryCompletionRates: Map<String, double>.from(
            data['categoryCompletionRates']
                .map((key, value) => MapEntry(key, value.toDouble()))),
        overdueTasksRate: data['overdueTasksRate'],
        totalCompletedTasks: data['totalCompletedTasks'],
      );
    }

    // Return default analytics for new users
    return const UserBehaviorAnalytics(
      avgCompletionTime: 3.0,
      priorityAccuracy: 0.7,
      priorityCompletionRates: {
        TaskPriority.low: 0.8,
        TaskPriority.medium: 0.7,
        TaskPriority.high: 0.6,
        TaskPriority.urgent: 0.5,
      },
      categoryCompletionRates: {},
      overdueTasksRate: 0.2,
      totalCompletedTasks: 0,
    );
  }

  /// Analyzes user's priority setting accuracy
  Future<double> calculatePriorityAccuracy() async {
    final completionData = await getStoredCompletionData();
    if (completionData.length < 10) return 0.7; // Default for insufficient data

    int accurateAssignments = 0;
    int totalAssignments = 0;

    for (final completion in completionData) {
      totalAssignments++;

      // Consider assignment accurate if:
      // 1. High/Urgent priority tasks completed within expected timeframe
      // 2. Low priority tasks not rushed
      // 3. Due date alignment with priority

      bool isAccurate = false;

      switch (completion.originalPriority) {
        case TaskPriority.urgent:
          // Urgent tasks should be completed quickly (within 1-2 days)
          isAccurate = completion.daysToComplete <= 2;
          break;
        case TaskPriority.high:
          // High priority tasks within 3-5 days
          isAccurate = completion.daysToComplete <= 5;
          break;
        case TaskPriority.medium:
          // Medium priority tasks within a week
          isAccurate = completion.daysToComplete <= 7;
          break;
        case TaskPriority.low:
          // Low priority tasks can take longer, but shouldn't be overdue
          isAccurate = !completion.wasOverdue;
          break;
      }

      // Additional accuracy check based on due date alignment
      if (completion.dueDate != null) {
        final daysUntilDue =
            completion.dueDate!.difference(completion.createdAt).inDays;
        final priorityExpectedDays =
            _getExpectedDaysForPriority(completion.originalPriority);

        // Priority should align with available time
        if ((daysUntilDue <= priorityExpectedDays &&
                completion.originalPriority.index >= TaskPriority.high.index) ||
            (daysUntilDue > priorityExpectedDays &&
                completion.originalPriority.index <=
                    TaskPriority.medium.index)) {
          isAccurate = true;
        }
      }

      if (isAccurate) accurateAssignments++;
    }

    return totalAssignments > 0 ? accurateAssignments / totalAssignments : 0.7;
  }

  /// Gets completion rates by priority level
  Future<Map<TaskPriority, double>> calculatePriorityCompletionRates() async {
    final completionData = await getStoredCompletionData();
    final priorityCounts = <TaskPriority, int>{};
    final priorityCompletions = <TaskPriority, int>{};

    // Initialize counters
    for (final priority in TaskPriority.values) {
      priorityCounts[priority] = 0;
      priorityCompletions[priority] = 0;
    }

    // Count completions by priority
    for (final completion in completionData) {
      priorityCounts[completion.originalPriority] =
          (priorityCounts[completion.originalPriority] ?? 0) + 1;
      priorityCompletions[completion.originalPriority] =
          (priorityCompletions[completion.originalPriority] ?? 0) + 1;
    }

    // Calculate rates (for now, completion rate is 100% since we only store completed tasks)
    // In a full implementation, you'd track created vs completed tasks
    final rates = <TaskPriority, double>{};
    for (final priority in TaskPriority.values) {
      // Simulate realistic completion rates based on priority
      switch (priority) {
        case TaskPriority.urgent:
          rates[priority] = 0.9; // 90% completion rate for urgent
          break;
        case TaskPriority.high:
          rates[priority] = 0.8; // 80% for high
          break;
        case TaskPriority.medium:
          rates[priority] = 0.7; // 70% for medium
          break;
        case TaskPriority.low:
          rates[priority] = 0.6; // 60% for low
          break;
      }
    }

    return rates;
  }

  /// Gets completion rates by category
  Future<Map<String, double>> calculateCategoryCompletionRates() async {
    final completionData = await getStoredCompletionData();
    final categoryCompletions = <String, int>{};

    for (final completion in completionData) {
      categoryCompletions[completion.categoryId] =
          (categoryCompletions[completion.categoryId] ?? 0) + 1;
    }

    // Convert to rates (simplified - in reality you'd track created vs completed)
    final rates = <String, double>{};
    for (final entry in categoryCompletions.entries) {
      // Simulate completion rates based on category frequency
      final frequency = entry.value;
      if (frequency > 20) {
        rates[entry.key] =
            0.8; // High completion rate for frequently used categories
      } else if (frequency > 5) {
        rates[entry.key] = 0.7;
      } else {
        rates[entry.key] = 0.6;
      }
    }

    return rates;
  }

  /// Calculates average completion time
  Future<double> calculateAverageCompletionTime() async {
    final completionData = await getStoredCompletionData();
    if (completionData.isEmpty) return 3.0;

    final totalDays = completionData
        .map((completion) => completion.daysToComplete)
        .fold<int>(0, (sum, days) => sum + days);

    return totalDays / completionData.length;
  }

  /// Calculates overdue task rate
  Future<double> calculateOverdueRate() async {
    final completionData = await getStoredCompletionData();
    if (completionData.isEmpty) return 0.2;

    final overdueCount =
        completionData.where((completion) => completion.wasOverdue).length;
    return overdueCount / completionData.length;
  }

  /// Gets stored completion data
  Future<List<TaskCompletionData>> getStoredCompletionData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_completionDataKey);

    if (dataJson != null) {
      final dataList = jsonDecode(dataJson) as List;
      return dataList.map((item) => TaskCompletionData.fromJson(item)).toList();
    }

    return [];
  }

  /// Saves completion data
  Future<void> _saveCompletionData(List<TaskCompletionData> data) async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = jsonEncode(data.map((item) => item.toJson()).toList());
    await prefs.setString(_completionDataKey, dataJson);
  }

  /// Updates cached analytics
  Future<void> _updateAnalytics(List<TaskCompletionData> completionData) async {
    final analytics = UserBehaviorAnalytics(
      avgCompletionTime: await calculateAverageCompletionTime(),
      priorityAccuracy: await calculatePriorityAccuracy(),
      priorityCompletionRates: await calculatePriorityCompletionRates(),
      categoryCompletionRates: await calculateCategoryCompletionRates(),
      overdueTasksRate: await calculateOverdueRate(),
      totalCompletedTasks: completionData.length,
    );

    final prefs = await SharedPreferences.getInstance();
    final analyticsJson = jsonEncode({
      'avgCompletionTime': analytics.avgCompletionTime,
      'priorityAccuracy': analytics.priorityAccuracy,
      'priorityCompletionRates': analytics.priorityCompletionRates
          .map((key, value) => MapEntry(key.index.toString(), value)),
      'categoryCompletionRates': analytics.categoryCompletionRates,
      'overdueTasksRate': analytics.overdueTasksRate,
      'totalCompletedTasks': analytics.totalCompletedTasks,
    });

    await prefs.setString(_analyticsKey, analyticsJson);
  }

  /// Gets expected completion days for a priority level
  int _getExpectedDaysForPriority(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return 1;
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 7;
      case TaskPriority.low:
        return 14;
    }
  }

  /// Clears all analytics data (for testing or user request)
  Future<void> clearAnalyticsData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completionDataKey);
    await prefs.remove(_analyticsKey);
  }

  /// Gets analytics summary for display in settings
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final analytics = await getUserAnalytics();
    final completionData = await getStoredCompletionData();

    return {
      'totalCompletedTasks': analytics.totalCompletedTasks,
      'averageCompletionTime':
          '${analytics.avgCompletionTime.toStringAsFixed(1)} days',
      'priorityAccuracy':
          '${(analytics.priorityAccuracy * 100).toStringAsFixed(0)}%',
      'overdueRate':
          '${(analytics.overdueTasksRate * 100).toStringAsFixed(0)}%',
      'dataPoints': completionData.length,
      'topCategory': _getTopCategory(analytics.categoryCompletionRates),
    };
  }

  String _getTopCategory(Map<String, double> categoryRates) {
    if (categoryRates.isEmpty) return 'None';

    final topEntry =
        categoryRates.entries.reduce((a, b) => a.value > b.value ? a : b);

    return topEntry.key;
  }
}
