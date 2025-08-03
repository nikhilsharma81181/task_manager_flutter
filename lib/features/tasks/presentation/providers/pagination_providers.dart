import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import 'computed_providers.dart';

// PAGINATION PROVIDERS

/// StateProvider for pagination
final currentPageProvider = StateProvider<int>((ref) => 1);

/// StateProvider for loading more state
final isLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// Provider for paginated tasks with loading state
final paginatedTasksProvider = Provider<List<TaskEntity>>((ref) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  final currentPage = ref.watch(currentPageProvider);
  const itemsPerPage = 25;

  return filteredTasks.when(
    data: (tasks) {
      final endIndex = currentPage * itemsPerPage;
      return tasks
          .take(endIndex > tasks.length ? tasks.length : endIndex)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for checking if there are more pages
final hasMorePagesProvider = Provider<bool>((ref) {
  final filteredTasks = ref.watch(filteredTasksProvider);
  final currentPage = ref.watch(currentPageProvider);
  const itemsPerPage = 25;

  return filteredTasks.when(
    data: (tasks) => tasks.length > currentPage * itemsPerPage,
    loading: () => false,
    error: (_, __) => false,
  );
});