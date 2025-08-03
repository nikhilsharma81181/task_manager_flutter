import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/computed_providers.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/filter_providers.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/pagination_providers.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_form_notifier.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_providers.dart';
import 'package:task_manager_flutter/features/tasks/presentation/widgets/task_card.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';

import '../../../../core/widgets/common/loading_overlay.dart';
import '../../../../core/widgets/common/empty_state_widget.dart';
import '../../../../core/widgets/common/error_widget.dart';
import '../../domain/entities/task.dart';
import '../providers/home_state.dart';

import 'task_edit_page.dart';
import 'task_detail_page.dart';
import 'analytics_page.dart';

class TaskStatusOption { 
  final TaskStatus? status;
  final String label;
  final IconData icon;

  TaskStatusOption(this.status, this.label, this.icon);
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchText = '';
  int _currentIndex = 0;

  final List<TaskStatusOption> _statusOptions = [
    TaskStatusOption(null, 'All', Icons.list_alt_rounded),
    TaskStatusOption(
        TaskStatus.pending, 'Pending', Icons.pending_actions_rounded),
    TaskStatusOption(
        TaskStatus.inProgress, 'In Progress', Icons.work_outline_rounded),
    TaskStatusOption(
        TaskStatus.completed, 'Completed', Icons.check_circle_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Loading tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeNotifierProvider.notifier).loadTasks();
    });

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
      ref
          .read(homeNotifierProvider.notifier)
          .searchTasks(_searchController.text);
    });

    // Add scroll listener for auto-loading more tasks
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Optimized scroll threshold for large datasets - trigger earlier loading
    // when user is within 500px of bottom (roughly 3-4 task cards)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      final hasMorePages = ref.read(hasMorePagesProvider);
      final isLoadingMore = ref.read(isLoadingMoreProvider);
      if (hasMorePages && !isLoadingMore) {
        ref.read(homeNotifierProvider.notifier).loadMoreTasks();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Clear search focus when returning to the app
      _searchFocusNode.unfocus();
    }
  }

  void _clearSearchFocus() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeNotifierProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingOverlay(
          isLoading: homeState.isLoading,
          message: 'Loading tasks...',
          child: SafeArea(
            child: _currentIndex == 0
                ? _buildTasksTab(context, homeState)
                : const AnalyticsPage(),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.onSurfaceVariant,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.task_alt_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: 'Analytics',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: AppColors.primary,
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => _navigateToCreateTask(context),
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text(
                    'New Task',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTasksTab(
      BuildContext context, AsyncValue<List<TaskEntity>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final filteredTasks = ref.watch(filteredTasksProvider);
        return filteredTasks.when(
          data: (filtered) {
            final paginatedTasks = ref.watch(paginatedTasksProvider);

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(homeNotifierProvider.notifier).refreshTasks(),
              color: AppColors.primary,
              backgroundColor: AppColors.background,
              strokeWidth: 3,
              child: CustomScrollView(
                controller: _scrollController,
                // Add cache extent for better performance with large lists
                cacheExtent: 1000.0, // Cache 1000px worth of widgets
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSearchAndFilters(context, filtered),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTasksHeaderDelegate(
                      height: 86.0,
                      child:
                          _buildTasksHeader(context, filtered, paginatedTasks),
                    ),
                  ),
                  _buildTaskListSliver(context, paginatedTasks),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => AppErrorWidget(
            title: 'Error Loading Tasks',
            message: error.toString(),
            actionText: 'Retry',
            onActionPressed: () =>
                ref.read(homeNotifierProvider.notifier).refreshTasks(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => AppErrorWidget(
        title: 'Error Loading Tasks',
        message: error.toString(),
        actionText: 'Retry',
        onActionPressed: () =>
            ref.read(homeNotifierProvider.notifier).refreshTasks(),
      ),
    );
  }

  // This widget now builds the content for the collapsible SliverAppBar
  Widget _buildSearchAndFilters(
      BuildContext context, List<TaskEntity> filteredTasks) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              hintStyle: const TextStyle(
                color: AppColors.onSurfaceVariant,
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _searchText.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchText = '';
                        });
                        ref.read(homeNotifierProvider.notifier).searchTasks('');
                        _clearSearchFocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(
                    color: AppColors.border.withOpacity(0.5), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: const TextStyle(
              color: AppColors.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          _buildCreativePriorityFilter(context, filteredTasks),
        ],
      ),
    );
  }

  Widget _buildCreativePriorityFilter(
      BuildContext context, List<TaskEntity> filteredTasks) {
    final priorityFilter = ref.watch(priorityFilterProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);

    return Row(
      children: [
        // Filter icon button
        GestureDetector(
          onTap: () {
            _clearSearchFocus();
            _showAdvancedFiltersBottomSheet(context);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _hasAdvancedFiltersActive()
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasAdvancedFiltersActive()
                    ? AppColors.primary
                    : AppColors.border.withOpacity(0.5),
                width: _hasAdvancedFiltersActive() ? 1.5 : 1,
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: _hasAdvancedFiltersActive()
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Priority filters
                _buildPriorityFilterChip(
                  'All',
                  null,
                  priorityFilter == null,
                  AppColors.primary,
                ),
                ...TaskPriority.values.map((priority) {
                  final isSelected = priorityFilter == priority;
                  return _buildPriorityFilterChip(
                    _getPriorityLabel(priority),
                    priority,
                    isSelected,
                    AppColors.primary,
                  );
                }),

                // Divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 24,
                  width: 1,
                  color: AppColors.border.withOpacity(0.3),
                ),

                // Date filters
                _buildDateFilterChip('Today', DateFilter.today,
                    dateFilter == DateFilter.today, AppColors.primary),
                _buildDateFilterChip('Tomorrow', DateFilter.tomorrow,
                    dateFilter == DateFilter.tomorrow, AppColors.primary),
                _buildDateFilterChip('This Week', DateFilter.thisWeek,
                    dateFilter == DateFilter.thisWeek, AppColors.primary),
                _buildDateFilterChip('Overdue', DateFilter.overdue,
                    dateFilter == DateFilter.overdue, AppColors.primary),
                _buildCustomDateFilterChip(context),
              ],
            ),
          ),
        ),
        if (priorityFilter != null ||
            statusFilter != null ||
            dateFilter != DateFilter.all ||
            _searchText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchText = '';
                });
                ref.read(priorityFilterProvider.notifier).state = null;
                ref.read(statusFilterProvider.notifier).state = null;
                ref.read(dateFilterProvider.notifier).state = DateFilter.all;
                ref.read(customStartDateProvider.notifier).state = null;
                ref.read(customEndDateProvider.notifier).state = null;
                _clearSearchFocus();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.clear_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPriorityFilterChip(
    String label,
    TaskPriority? priority,
    bool isSelected,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (priority == null && selected) {
            // "All" button - clear only priority and status filters, preserve date filter
            ref.read(priorityFilterProvider.notifier).state = null;
            ref.read(statusFilterProvider.notifier).state = null;
          } else {
            ref.read(priorityFilterProvider.notifier).state =
                selected ? priority : null;
          }
        },
        selectedColor: isSelected ? color : AppColors.surfaceVariant,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? color : AppColors.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
      ),
    );
  }

  // This widget now builds the content for the sticky SliverPersistentHeader.
  // It accepts the filtered task list to display the correct count.
  Widget _buildTasksHeader(BuildContext context, List<TaskEntity> filteredTasks,
      List<TaskEntity> paginatedTasks) {
    final statusFilter = ref.watch(statusFilterProvider);
    final currentOption = _statusOptions.firstWhere(
      (option) => option.status == statusFilter,
      orElse: () => _statusOptions.first,
    );

    final totalTasks = filteredTasks.length;
    final showingTasks = paginatedTasks.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalTasks == showingTasks
                      ? '$totalTasks tasks'
                      : 'Showing $showingTasks of $totalTasks tasks',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // // Sort Tasks Button
              // Consumer(
              //   builder: (context, ref, child) {
              //     return GestureDetector(
              //       onTap: () async {
              //         // Apply simple sorting
              //         await ref
              //             .read(homeNotifierProvider.notifier)
              //             .applySortingToCurrentTasks();

              //         if (mounted) {
              //           SnackbarUtils.showSuccess(
              //             context,
              //             'Tasks sorted by urgency and priority!',
              //           );
              //         }
              //       },
              //       child: Container(
              //         padding: const EdgeInsets.symmetric(
              //             horizontal: 8, vertical: 6),
              //         margin: const EdgeInsets.only(right: 8),
              //         decoration: BoxDecoration(
              //           color: AppColors.primary.withOpacity(0.1),
              //           borderRadius: BorderRadius.circular(6),
              //           border: Border.all(
              //             color: AppColors.primary,
              //             width: 1,
              //           ),
              //         ),
              //         child: const Row(
              //           mainAxisSize: MainAxisSize.min,
              //           children: [
              //             Icon(
              //               Icons.sort_rounded,
              //               size: 14,
              //               color: AppColors.primary,
              //             ),
              //             SizedBox(width: 4),
              //             Text(
              //               'Sort',
              //               style: TextStyle(
              //                 fontSize: 11,
              //                 fontWeight: FontWeight.w600,
              //                 color: AppColors.primary,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     );
              //   },
              // ),

              // Add refresh widget here 
              IconButton(
                onPressed: () {
                  ref.read(homeNotifierProvider.notifier).refreshTasks();
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh tasks',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.all(8),
                ),
              ),
              _buildStatusDropdown(currentOption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(TaskStatusOption currentOption) {
    final statusFilter = ref.watch(statusFilterProvider);

    return PopupMenuButton<TaskStatusOption>(
      onSelected: (TaskStatusOption option) {
        ref.read(homeNotifierProvider.notifier).filterByStatus(option.status);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      offset: const Offset(0, 8),
      elevation: 4,
      color: AppColors.surface,
      itemBuilder: (BuildContext context) {
        return _statusOptions.map((TaskStatusOption option) {
          final isSelected = statusFilter == option.status;
          return PopupMenuItem<TaskStatusOption>(
            value: option,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  option.icon,
                  size: 22,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          isSelected ? AppColors.primary : AppColors.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: AppColors.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentOption.icon,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              currentOption.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // --- 🔄 REFACTORED TASK LIST WIDGET WITH PAGINATION ---
  // This now returns a Sliver widget to be used inside the CustomScrollView.
  Widget _buildTaskListSliver(BuildContext context, List<TaskEntity> tasks) {
    final hasMorePages = ref.watch(hasMorePagesProvider);

    if (tasks.isEmpty) {
      // Use SliverFillRemaining to show the empty state in the center of the available space.
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: EmptyStateWidget(
            title: 'No Tasks Yet',
            message:
                'Create your first task to get started!\nTap the "New Task" button below.',
            icon: Icons.task_alt,
            actionText: 'Create Task',
            onActionPressed: () => _navigateToCreateTask(context),
          ),
        ),
      );
    }

    // Optimized SliverList for large datasets (1000+ tasks)
    return SliverPadding(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Show task card
            if (index < tasks.length) {
              final task = tasks[index];
              // Use RepaintBoundary for better performance with many items
              return RepaintBoundary(
                child: TaskCard(
                  key: ValueKey(task.id), // Stable key for better performance
                  task: task,
                  onTap: () => _navigateToTaskDetail(context, task.id),
                  onStatusChanged: (newStatus) =>
                      _updateTaskStatus(task, newStatus),
                  onEdit: () => _navigateToEditTask(context, task),
                  onDelete: () => _showDeleteConfirmation(context, task),
                ),
              );
            }

            // Show load more button or loading indicator
            if (index == tasks.length && hasMorePages) {
              return _buildLoadMoreWidget();
            }

            return null;
          },
          childCount: tasks.length + (hasMorePages ? 1 : 0),
          // Performance optimization: provide estimated item extent for better scrolling
          // TaskCard height is approximately 120-140px
          findChildIndexCallback: (Key key) {
            if (key is ValueKey<String>) {
              final taskId = key.value;
              return tasks.indexWhere((task) => task.id == taskId);
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildLoadMoreWidget() {
    final isLoadingMore = ref.watch(isLoadingMoreProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final paginatedTasks = ref.watch(paginatedTasksProvider);

    if (isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () =>
              ref.read(homeNotifierProvider.notifier).loadMoreTasks(),
          icon: const Icon(Icons.expand_more_rounded),
          label: filteredTasks.when(
            data: (filtered) => Text(
              'Load More (${filtered.length - paginatedTasks.length} remaining)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Load More'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceVariant,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border.withOpacity(0.5)),
            ),
          ),
        ),
      ),
    );
  }

  // Helper methods remain the same
  Future<void> _navigateToCreateTask(BuildContext context) async {
    _clearSearchFocus();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskEditPage(mode: TaskFormMode.create),
      ),
    );

    if (result != null) {
      if (result is TaskEntity) {
        // Optimistic update: add the new task immediately
        ref.read(homeNotifierProvider.notifier).addTaskOptimistically(result);
      } else if (result == true) {
        // Fallback: refresh all tasks
        ref.read(homeNotifierProvider.notifier).loadTasks();
      }
    }
  }

  Future<void> _navigateToEditTask(
      BuildContext context, TaskEntity task) async {
    _clearSearchFocus();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditPage(
          mode: TaskFormMode.edit,
          task: task,
        ),
      ),
    );

    if (result == true) {
      ref.read(homeNotifierProvider.notifier).loadTasks();
    }
  }

  void _navigateToTaskDetail(BuildContext context, String taskId) {
    _clearSearchFocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailPage(taskId: taskId),
      ),
    );
  }

  Future<void> _updateTaskStatus(TaskEntity task, TaskStatus newStatus) async {
    final success = await ref
        .read(homeNotifierProvider.notifier)
        .updateTaskStatus(task, newStatus);
    if (!success && mounted) {
      SnackbarUtils.showError(context, 'Failed to update task status');
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, TaskEntity task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(homeNotifierProvider.notifier).deleteTaskById(task.id);
      if (!success && mounted) {
        SnackbarUtils.showError(context, 'Failed to delete task');
      } else if (mounted) {
        SnackbarUtils.showSuccess(context, 'Task deleted successfully');
      }
    }
  }

  String _getPriorityLabel(TaskPriority priority) {
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

  Widget _buildDateFilterChip(
      String label, DateFilter filter, bool isSelected, Color chipColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            ref.read(dateFilterProvider.notifier).state = filter;
          } else {
            ref.read(dateFilterProvider.notifier).state = DateFilter.all;
          }
        },
        selectedColor: isSelected ? chipColor : AppColors.surfaceVariant,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? chipColor : AppColors.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 0,
      ),
    );
  }

  Widget _buildCustomDateFilterChip(BuildContext context) {
    final dateFilter = ref.watch(dateFilterProvider);
    final customStartDate = ref.watch(customStartDateProvider);
    final customEndDate = ref.watch(customEndDateProvider);
    final isSelected = dateFilter == DateFilter.custom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.date_range, size: 12),
            const SizedBox(width: 4),
            Text(isSelected && customStartDate != null && customEndDate != null
                ? '${customStartDate.day}/${customStartDate.month} - ${customEndDate.day}/${customEndDate.month}'
                : 'Custom'),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _clearSearchFocus();
            _showDateRangePicker(context);
          } else {
            ref.read(dateFilterProvider.notifier).state = DateFilter.all;
            ref.read(customStartDateProvider.notifier).state = null;
            ref.read(customEndDateProvider.notifier).state = null;
          }
        },
        selectedColor:
            isSelected ? AppColors.primary : AppColors.surfaceVariant,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : AppColors.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        elevation: 0,
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 7)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.surface,
                  onSurface: AppColors.onSurface,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(dateFilterProvider.notifier).state = DateFilter.custom;
      ref.read(customStartDateProvider.notifier).state = picked.start;
      ref.read(customEndDateProvider.notifier).state = picked.end;
    }
  }

  bool _hasAdvancedFiltersActive() {
    final statusFilter = ref.watch(statusFilterProvider);
    final priorityFilter = ref.watch(priorityFilterProvider);
    final dateFilter = ref.watch(dateFilterProvider);
    return statusFilter != null ||
        priorityFilter != null ||
        dateFilter != DateFilter.all;
  }

  void _showAdvancedFiltersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedFiltersBottomSheet(ref: ref),
    );
  }
}

// A custom delegate for creating the sticky header.
class _SliverTasksHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverTasksHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_SliverTasksHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _AdvancedFiltersBottomSheet extends StatefulWidget {
  final WidgetRef ref;

  const _AdvancedFiltersBottomSheet({required this.ref});

  @override
  State<_AdvancedFiltersBottomSheet> createState() =>
      _AdvancedFiltersBottomSheetState();
}

class _AdvancedFiltersBottomSheetState
    extends State<_AdvancedFiltersBottomSheet> {
  late String? selectedCategory;
  late TaskStatus? selectedStatus;
  late DateFilter selectedTimeFilter;
  late DateTime? customStartDate;
  late DateTime? customEndDate;

  @override
  void initState() {
    super.initState();
    selectedCategory = null;
    selectedStatus = widget.ref.read(statusFilterProvider);
    selectedTimeFilter = DateFilter.all;
    customStartDate = null;
    customEndDate = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Text(
                      'Advanced Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = null;
                          selectedStatus = null;
                          selectedTimeFilter = DateFilter.all;
                          customStartDate = null;
                          customEndDate = null;
                        });
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Status Section
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TaskStatusOption(TaskStatus.pending, 'Pending',
                            Icons.pending_actions_rounded),
                        TaskStatusOption(TaskStatus.inProgress, 'In Progress',
                            Icons.work_outline_rounded),
                        TaskStatusOption(TaskStatus.completed, 'Completed',
                            Icons.check_circle_outline_rounded),
                      ].map((statusOption) {
                        final isSelected =
                            selectedStatus == statusOption.status;
                        return _buildStatusFilterChip(
                          label: statusOption.label,
                          icon: statusOption.icon,
                          color: AppColors.primary,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedStatus =
                                  isSelected ? null : statusOption.status;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 120), // Space for the button
                  ],
                ),
              ),
              // Apply Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Apply all selected filters
                      widget.ref
                          .read(homeNotifierProvider.notifier)
                          .filterByStatus(selectedStatus);

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
