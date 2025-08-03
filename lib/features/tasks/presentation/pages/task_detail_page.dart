import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_form_notifier.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_providers.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/common/custom_app_bar.dart';
import '../../../../core/widgets/common/error_widget.dart';
import '../widgets/priority_indicator.dart';
import '../../domain/entities/task.dart';
import 'task_edit_page.dart';

class TaskDetailPage extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailPage({
    super.key, 
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends ConsumerState<TaskDetailPage> {
  bool _isUpdatingStatus = false;

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailProvider(widget.taskId));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Task Details',
        actions: _buildAppBarActions(context, taskAsync),
      ),
      body: taskAsync.when(
        data: (task) => _buildContent(context, task),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => AppErrorWidget(
          title: 'Error Loading Task',
          message: error.toString(),
          actionText: 'Retry',
          onActionPressed: () => ref.refresh(taskDetailProvider(widget.taskId)),
        ),
      ),
    );
  }

  List<Widget>? _buildAppBarActions(
      BuildContext context, AsyncValue<TaskEntity> taskAsync) {
    return null;
  }

  Widget _buildContent(BuildContext context, TaskEntity task) {
    return _buildTaskDetail(context, task);
  }

  Widget _buildTaskDetail(BuildContext context, TaskEntity task) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Title and Status
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: AppTextStyles.h4.copyWith(
                            decoration: task.status == TaskStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == TaskStatus.completed
                                ? AppColors.onSurfaceVariant
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      PriorityIndicator(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatusChip(task.status),
                      const Spacer(),
                      if (task.dueDate != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: _getDueDateColor(task.dueDate!),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(task.dueDate!),
                          style: AppTextStyles.caption.copyWith(
                            color: _getDueDateColor(task.dueDate!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Description
          if (task.description.isNotEmpty) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: AppTextStyles.h6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.description,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Task Info
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Information',
                    style: AppTextStyles.h6,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Created', _formatDateTime(task.createdAt)),
                  _buildInfoRow(
                      'Last Modified', _formatDateTime(task.lastModified)),
                  if (task.dueDate != null)
                    _buildInfoRow('Due Date', _formatDateTime(task.dueDate!)),
                  _buildInfoRow('Priority', PriorityIndicator.getPriorityLabel(task.priority)),
                  _buildInfoRow('Status', _getStatusLabel(task.status)),
                ],
              ),
            ),
          ),
          // Status Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: AppTextStyles.h6,
                ),
                const SizedBox(height: 12),
                _buildStatusChoiceChips(context, task),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEdit(context, task),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteConfirmation(context, task),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChoiceChips(BuildContext context, TaskEntity task) {
    if (_isUpdatingStatus) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      children: TaskStatus.values.map((status) {
        final isSelected = status == task.status;
        return ChoiceChip(
          label: Text(_getStatusLabel(status)),
          selected: isSelected,
          onSelected: (selected) async {
            if (selected && status != task.status) {
              await _updateTaskStatus(context, task, status);
            }
          },
          backgroundColor: AppColors.surfaceVariant,
          selectedColor: _getStatusColor(status),
          checkmarkColor: AppColors.onPrimary,
          labelStyle: AppTextStyles.caption.copyWith(
            color:
                isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: isSelected
                ? _getStatusColor(status)
                : AppColors.border.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateTaskStatus(
      BuildContext context, TaskEntity task, TaskStatus newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    final success = await ref
        .read(homeNotifierProvider.notifier)
        .updateTaskStatus(task, newStatus);

    if (mounted) {
      setState(() {
        _isUpdatingStatus = false;
      });

      if (success) {
        ref.refresh(taskDetailProvider(widget.taskId));
        SnackbarUtils.showSuccess(context, 'Task status updated');
      } else {
        SnackbarUtils.showError(context, 'Failed to update task status');
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context, TaskEntity task) async {
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
      ref.refresh(taskDetailProvider(widget.taskId));
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, TaskEntity task) async {
    final navigator = Navigator.of(context);

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
      if (success && mounted) {
        navigator.pop();
        SnackbarUtils.showSuccess(context, 'Task deleted successfully');
      } else if (mounted) {
        SnackbarUtils.showError(context, 'Failed to delete task');
      }
    }
  }

  // Helper methods
  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (due.isBefore(today)) {
      return AppColors.error;
    } else if (due.isAtSameMomentAs(today)) {
      return AppColors.warning;
    } else {
      return AppColors.onSurfaceVariant;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (due.isAtSameMomentAs(today)) {
      return 'Due Today';
    } else if (due.isAtSameMomentAs(tomorrow)) {
      return 'Due Tomorrow';
    } else if (due.isBefore(today)) {
      final difference = today.difference(due).inDays;
      return '$difference days overdue';
    } else {
      final difference = due.difference(today).inDays;
      if (difference <= 7) {
        return 'Due in $difference days';
      } else {
        return 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}';
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.statusPending;
      case TaskStatus.inProgress:
        return AppColors.statusInProgress;
      case TaskStatus.completed:
        return AppColors.statusCompleted;
    }
  }

  String _getStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending_actions;
      case TaskStatus.inProgress:
        return Icons.work_outline;
      case TaskStatus.completed:
        return Icons.check_circle;
    }
  }

}
