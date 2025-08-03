import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/widgets/animations/progress_ring.dart';
import '../../../../core/widgets/animations/animated_linear_progress.dart';
import '../providers/task_providers.dart';
import '../../domain/entities/task.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(homeNotifierProvider);
 
    return tasksAsync.when(
      data: (tasks) => _buildAnalyticsContent(context, tasks),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, stack) => Center(
        child: Text('Error loading analytics: $error'),
      ),
    );
  }

  Widget _buildAnalyticsContent(BuildContext context, List<TaskEntity> tasks) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Task Analytics',
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          _buildOverviewCards(tasks),
          const SizedBox(height: 2),
          _buildProgressSection(tasks),
          const SizedBox(height: 2),
          _buildPriorityBreakdown(tasks),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(List<TaskEntity> tasks) {
    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final inProgressTasks =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final pendingTasks =
        tasks.where((t) => t.status == TaskStatus.pending).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview',
              style: AppTextStyles.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildOverviewListItem('Total Tasks', totalTasks.toString(),
                Icons.task_alt_rounded, AppColors.primary),
            _buildOverviewListItem('Completed', completedTasks.toString(),
                Icons.check_circle_rounded, AppColors.success),
            _buildOverviewListItem('In Progress', inProgressTasks.toString(),
                Icons.work_outline_rounded, AppColors.statusInProgress),
            _buildOverviewListItem('Pending', pendingTasks.toString(),
                Icons.pending_actions_rounded, AppColors.statusPending),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewListItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(List<TaskEntity> tasks) {
    final totalTasks = tasks.length;
    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completion Progress',
              style: AppTextStyles.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ProgressRing(
                  progress: completionRate,
                  size: 100,
                  color: AppColors.success,
                  centerText: '', // This will show animated percentage
                  animate: true,
                  animationDuration: const Duration(milliseconds: 1000),
                  animationCurve: Curves.easeOutCubic,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedTasks of $totalTasks tasks completed',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep going! You\'re doing great!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBreakdown(List<TaskEntity> tasks) {
    final lowTasks = tasks.where((t) => t.priority == TaskPriority.low).length;
    final mediumTasks =
        tasks.where((t) => t.priority == TaskPriority.medium).length;
    final highTasks =
        tasks.where((t) => t.priority == TaskPriority.high).length;
    final urgentTasks =
        tasks.where((t) => t.priority == TaskPriority.urgent).length;
    final totalTasks = tasks.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority Breakdown',
              style: AppTextStyles.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildPriorityListItem('Low', lowTasks, totalTasks,
                AppColors.priorityLow, Icons.keyboard_arrow_down, 0),
            _buildPriorityListItem('Medium', mediumTasks, totalTasks,
                AppColors.priorityMedium, Icons.remove, 1),
            _buildPriorityListItem('High', highTasks, totalTasks,
                AppColors.priorityHigh, Icons.keyboard_arrow_up, 2),
            _buildPriorityListItem('Urgent', urgentTasks, totalTasks,
                AppColors.priorityUrgent, Icons.priority_high, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityListItem(
      String label, int count, int total, Color color, IconData icon, int index) {
    final percentage = total > 0 ? (count / total * 100).toInt() : 0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              '$count tasks',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedLinearProgress(
                                value: total > 0 ? count / total : 0.0,
                                backgroundColor: color.withOpacity(0.2),
                                valueColor: color,
                                minHeight: 4,
                                animate: true,
                                animationDuration: Duration(milliseconds: 1000 + (index * 100)),
                                animationCurve: Curves.easeOutCubic,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$percentage%',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
