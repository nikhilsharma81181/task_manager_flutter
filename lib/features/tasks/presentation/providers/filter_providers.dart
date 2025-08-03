import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import 'home_state.dart';

// SEARCH AND FILTER PROVIDERS

/// StateProvider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// StateProvider for status filter
final statusFilterProvider = StateProvider<TaskStatus?>((ref) => null);

/// StateProvider for priority filter
final priorityFilterProvider = StateProvider<TaskPriority?>((ref) => null);

/// StateProvider for date filter
final dateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.all);

/// StateProvider for custom date range start
final customStartDateProvider = StateProvider<DateTime?>((ref) => null);

/// StateProvider for custom date range end
final customEndDateProvider = StateProvider<DateTime?>((ref) => null);