import 'package:flutter/material.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/constants/task_categories.dart';
import '../../../../core/utils/task_formatters.dart';
import '../../domain/entities/task.dart';
import 'priority_indicator.dart';

class TaskCard extends StatefulWidget {
  final TaskEntity task;
  final VoidCallback? onTap;
  final Function(TaskStatus)? onStatusChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onStatusChanged,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with TickerProviderStateMixin {
  bool _isUpdatingStatus = false;
  late AnimationController _completionController;
  late AnimationController _statusChangeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _statusIndicatorPulse;

  @override
  void initState() {
    super.initState();
    _completionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _statusChangeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _completionController,
      curve: Curves.easeOut,
    ));

    _statusIndicatorPulse = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _statusChangeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _completionController.dispose();
    _statusChangeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.task.status != TaskStatus.completed &&
        widget.task.status == TaskStatus.completed) {
      _completionController.forward();
    } else if (oldWidget.task.status == TaskStatus.completed &&
        widget.task.status != TaskStatus.completed) {
      _completionController.reverse();
    }

    if (oldWidget.task.status != widget.task.status &&
        widget.task.status == TaskStatus.inProgress) {
      _statusChangeController.forward().then((_) {
        _statusChangeController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          Listenable.merge([_completionController, _statusChangeController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedOpacity(
            opacity: _fadeAnimation.value,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.2),
                        width: 0.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildStatusIndicator(),
                                  const SizedBox(width: 12),
                                  PriorityIndicator(
                                    priority: widget.task.priority,
                                    isCompact: true,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildCategoryChip(),
                                  const Spacer(),
                                  if (widget.showActions)
                                    _buildActionButtons(context),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.task.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onSurface,
                                  decoration:
                                      widget.task.status == TaskStatus.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.task.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  widget.task.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.onSurfaceVariant,
                                    height: 1.3,
                                    decoration: widget.task.status ==
                                            TaskStatus.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if (widget.task.dueDate != null) ...[
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: TaskFormatters.getDueDateColor(
                                          widget.task.dueDate),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      TaskFormatters.formatDueDate(
                                          widget.task.dueDate),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: TaskFormatters.getDueDateColor(
                                            widget.task.dueDate),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  const Spacer(),
                                  _buildStatusDropdown(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator() {
    return Transform.scale(
      scale: _statusIndicatorPulse.value,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: TaskFormatters.getStatusColor(widget.task.status),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: TaskFormatters.getStatusColor(widget.task.status)
                  .withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryChip() {
    final categoryColor =
        TaskCategories.getCategoryColor(widget.task.categoryId);
    final categoryIcon = TaskCategories.getCategoryIcon(widget.task.categoryId);
    final categoryName = TaskCategories.getCategoryName(widget.task.categoryId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            categoryIcon,
            size: 12,
            color: categoryColor,
          ),
          const SizedBox(width: 4),
          Text(
            categoryName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_rounded,
          onTap: widget.onEdit ?? () {},
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.delete_rounded,
          onTap: widget.onDelete ?? () {},
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    if (_isUpdatingStatus) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: widget.task.status,
          onChanged: widget.onStatusChanged != null
              ? (TaskStatus? newStatus) async {
                  if (newStatus != null && newStatus != widget.task.status) {
                    setState(() {
                      _isUpdatingStatus = true;
                    });

                    widget.onStatusChanged!(newStatus);

                    await Future.delayed(const Duration(milliseconds: 500));
                    if (mounted) {
                      setState(() {
                        _isUpdatingStatus = false;
                      });
                    }
                  }
                }
              : null,
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: Colors.white,
          ),
          selectedItemBuilder: (BuildContext context) {
            return TaskStatus.values.map<Widget>((TaskStatus status) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      TaskFormatters.getStatusIcon(status),
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      TaskFormatters.getStatusLabel(status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: TaskStatus.values
              .map<DropdownMenuItem<TaskStatus>>((TaskStatus status) {
            return DropdownMenuItem<TaskStatus>(
              value: status,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: TaskFormatters.getStatusColor(status),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TaskFormatters.getStatusColor(status)
                                .withOpacity(0.3),
                            blurRadius: 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      TaskFormatters.getStatusIcon(status),
                      size: 14,
                      color: TaskFormatters.getStatusColor(status),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      TaskFormatters.getStatusLabel(status),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
