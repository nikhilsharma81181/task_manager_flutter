import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/constants/task_categories.dart';
import '../../domain/entities/task.dart';

class TaskFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final FocusNode? titleFocusNode;
  final FocusNode? descriptionFocusNode;
  final TaskPriority priority;
  final TaskStatus? status;
  final DateTime? dueDate;
  final String categoryId;
  final Function(TaskPriority) onPriorityChanged;
  final Function(TaskStatus)? onStatusChanged;
  final Function(DateTime?) onDueDateChanged;
  final Function(String) onCategoryChanged;
  final bool showStatus;

  const TaskFormFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priority,
    required this.onPriorityChanged,
    required this.onDueDateChanged,
    required this.categoryId,
    required this.onCategoryChanged,
    this.titleFocusNode,
    this.descriptionFocusNode,
    this.status,
    this.onStatusChanged,
    this.dueDate,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleController,
          focusNode: titleFocusNode,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Task Title *',
            labelStyle: AppTextStyles.inputLabel,
            hintText: 'Enter task title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a task title';
            }
            if (value.trim().length < 3) {
              return 'Title must be at least 3 characters';
            }
            if (value.length > 100) {
              return 'Title cannot exceed 100 characters';
            }
            return null;
          },
          maxLines: 1,
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: descriptionController,
          focusNode: descriptionFocusNode,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            labelText: 'Description',
            labelStyle: AppTextStyles.inputLabel,
            hintText: 'Enter task description (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            alignLabelWithHint: true,
          ),
          validator: (value) {
            if (value != null && value.length > 500) {
              return 'Description cannot exceed 500 characters';
            }
            return null;
          },
          maxLines: 3,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),

        const SizedBox(height: 16),

        const Text(
          'Category',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TaskCategories.categories.map((category) {
            final isSelected = category.id == categoryId;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: isSelected ? AppColors.onPrimary : category.color,
                  ),
                  const SizedBox(width: 4),
                  Text(category.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategoryChanged(category.id);
                  FocusScope.of(context).unfocus();
                }
              },
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: category.color,
              checkmarkColor: AppColors.onPrimary,
              labelStyle: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? category.color
                    : AppColors.border.withOpacity(0.5),
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        const Text(
          'Priority',
          style: AppTextStyles.inputLabel,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TaskPriority.values.map((p) {
            final isSelected = p == priority;
            return ChoiceChip(
              label: Text(_getPriorityLabel(p)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPriorityChanged(p);
                  FocusScope.of(context).unfocus();
                }
              },
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: _getPriorityColor(p),
              checkmarkColor: AppColors.onPrimary,
              labelStyle: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              side: BorderSide(
                color: isSelected
                    ? _getPriorityColor(p)
                    : AppColors.border.withOpacity(0.5),
                width: isSelected ? 1.5 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        if (showStatus && status != null) ...[
          const Text(
            'Status',
            style: AppTextStyles.inputLabel,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: TaskStatus.values.map((s) {
              final isSelected = s == status;
              return ChoiceChip(
                label: Text(_getStatusLabel(s)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onStatusChanged?.call(s);
                    FocusScope.of(context).unfocus();
                  }
                },
                backgroundColor: AppColors.surfaceVariant,
                selectedColor: _getStatusColor(s),
                checkmarkColor: AppColors.onPrimary,
                labelStyle: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                side: BorderSide(
                  color: isSelected
                      ? _getStatusColor(s)
                      : AppColors.border.withOpacity(0.5),
                  width: isSelected ? 1.5 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        Row(
          children: [
            const Expanded(
              child: Text(
                'Due Date',
                style: AppTextStyles.inputLabel,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                FocusScope.of(context).unfocus();
                _selectDueDate(context);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                dueDate != null
                    ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                    : 'Select Date',
              ),
            ),
            if (dueDate != null)
              IconButton(
                onPressed: () => onDueDateChanged(null),
                icon: const Icon(Icons.clear),
                tooltip: 'Clear date',
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != dueDate) {
      onDueDateChanged(picked);
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppColors.priorityLow;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppColors.onSurfaceVariant;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.completed:
        return AppColors.success;
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
}
