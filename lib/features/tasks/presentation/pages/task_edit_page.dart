import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_form_notifier.dart';
import 'package:task_manager_flutter/features/tasks/presentation/providers/task_providers.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/common/custom_app_bar.dart';
import '../../../../core/widgets/common/loading_overlay.dart';
import '../../domain/entities/task.dart';
import '../providers/task_form_state.dart' as task_form_state;
import '../widgets/task_form_fields.dart';

class TaskEditPage extends ConsumerStatefulWidget {
  final TaskFormMode mode;
  final TaskEntity? task;

  const TaskEditPage({
    super.key, 
    required this.mode,
    this.task,
  });

  @override
  ConsumerState<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends ConsumerState<TaskEditPage> with WidgetsBindingObserver {
  late TaskFormParams _formParams;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _formParams = TaskFormParams(
      mode: widget.mode,
      initialTask: widget.task,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Clear form focus when returning to the app
      final formNotifier = ref.read(taskFormNotifierProvider(_formParams).notifier);
      formNotifier.clearFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.mode == TaskFormMode.create ? 'Create Task' : 'Edit Task';
    final formState = ref.watch(taskFormNotifierProvider(_formParams));
    final formNotifier =
        ref.read(taskFormNotifierProvider(_formParams).notifier);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: title,
        ),
        body: LoadingOverlay(
          isLoading: formState.isLoading,
          message: widget.mode == TaskFormMode.create
              ? 'Creating task...'
              : 'Updating task...',
          child: _buildForm(context, formState, formNotifier),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, task_form_state.TaskFormState state,
      TaskFormNotifier notifier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: notifier.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => notifier.clearError(),
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            TaskFormFields(
              titleController: notifier.titleController,
              descriptionController: notifier.descriptionController,
              titleFocusNode: notifier.titleFocusNode,
              descriptionFocusNode: notifier.descriptionFocusNode,
              priority: notifier.priority,
              status: widget.mode == TaskFormMode.edit ? notifier.status : null,
              dueDate: notifier.dueDate,
              categoryId: notifier.categoryId,
              onPriorityChanged: notifier.setPriority,
              onStatusChanged: notifier.setStatus,
              onDueDateChanged: notifier.setDueDate,
              onCategoryChanged: notifier.setCategoryId,
              showStatus: widget.mode == TaskFormMode.edit,
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Clear focus before navigation
                      final formNotifier = ref.read(taskFormNotifierProvider(_formParams).notifier);
                      formNotifier.clearFocus();
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isValid && !state.isLoading
                        ? () => _submitForm(context, notifier)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.mode == TaskFormMode.create
                          ? 'Create Task'
                          : 'Update Task',
                    ),
                  ),
                ),
              ],
            ),

            // Delete button (only for edit mode)
            if (widget.mode == TaskFormMode.edit) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () => _showDeleteConfirmation(context),
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  label: Text(
                    'Delete Task',
                    style:
                        AppTextStyles.button.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm(
      BuildContext context, TaskFormNotifier notifier) async {
    if (!notifier.formKey.currentState!.validate()) {
      return;
    }

    // Clear focus before submission
    notifier.clearFocus();

    final success = await notifier.submitForm();

    if (success && mounted) {
      // Return the created/updated task for optimistic updates
      final formState = ref.read(taskFormNotifierProvider(_formParams));
      final result = widget.mode == TaskFormMode.create ? formState.task : true;
      Navigator.of(context).pop(result);

      final message = widget.mode == TaskFormMode.create
          ? 'Task created successfully'
          : 'Task updated successfully';

      SnackbarUtils.showSuccess(context, message);
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    if (widget.task == null) return;

    // Clear focus before showing dialog
    final formNotifier = ref.read(taskFormNotifierProvider(_formParams).notifier);
    formNotifier.clearFocus();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content:
            Text('Are you sure you want to delete "${widget.task!.title}"?'),
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
      final success = await ref
          .read(homeNotifierProvider.notifier)
          .deleteTaskById(widget.task!.id);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          SnackbarUtils.showSuccess(context, 'Task deleted successfully');
        } else {
          SnackbarUtils.showError(context, 'Failed to delete task');
        }
      }
    }
  }
}
