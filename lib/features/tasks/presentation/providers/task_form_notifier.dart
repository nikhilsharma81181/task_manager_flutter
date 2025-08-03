import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/update_task.dart';
import 'task_form_state.dart';

enum TaskFormMode { create, edit }

class TaskFormNotifier extends StateNotifier<TaskFormState> {
  final CreateTask createTask;
  final UpdateTask updateTask;
  final TaskFormMode mode;
  final TaskEntity? initialTask;

  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  
  // Focus nodes
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode descriptionFocusNode = FocusNode();

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending;
  DateTime? _dueDate;
  String _categoryId = 'default';

  // Form keys for validation
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TaskFormNotifier({
    required this.createTask,
    required this.updateTask,
    required this.mode,
    this.initialTask,
  }) : super(const TaskFormState()) {
    // Initialize form with existing task data if in edit mode
    if (initialTask != null && mode == TaskFormMode.edit) {
      _initializeWithTask(initialTask!);
      state = TaskFormState(task: initialTask, isValid: true);
    }
    
    // Listen to form changes for validation
    titleController.addListener(_validateForm);
    descriptionController.addListener(_validateForm);
  }

  TaskPriority get priority => _priority;
  TaskStatus get status => _status;
  DateTime? get dueDate => _dueDate;
  String get categoryId => _categoryId;

  void _initializeWithTask(TaskEntity task) {
    titleController.text = task.title;
    descriptionController.text = task.description;
    _priority = task.priority;
    _status = task.status;
    _dueDate = task.dueDate;
    _categoryId = task.categoryId;
  }

  void setPriority(TaskPriority priority) {
    _priority = priority;
    _validateForm();
  }

  void setStatus(TaskStatus status) {
    _status = status;
    _validateForm();
  }

  void setDueDate(DateTime? date) {
    _dueDate = date;
    _validateForm();
  }

  void setCategoryId(String categoryId) {
    _categoryId = categoryId;
    _validateForm();
  }

  void _validateForm() {
    state = state.copyWith(isValid: isFormValid);
  }

  bool get isFormValid {
    final title = titleController.text.trim();
    return title.isNotEmpty && title.length >= 3;
  }

  /// Submit form with TaskFormState management
  Future<bool> submitForm() async {
    if (!formKey.currentState!.validate() || !isFormValid) {
      state = state.copyWith(error: 'Form validation failed');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      if (mode == TaskFormMode.create) {
        return await _createTask();
      } else {
        return await _updateTask();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> _createTask() async {
    final params = CreateTaskParams(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      categoryId: _categoryId,
    );

    final result = await createTask(params);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (task) {
        state = state.copyWith(isLoading: false, task: task);
        return true;
      },
    );
  }

  Future<bool> _updateTask() async {
    final currentTask = state.task;
    if (currentTask == null) {
      state = state.copyWith(isLoading: false, error: 'No task to update');
      return false;
    }

    final params = UpdateTaskParams(
      id: currentTask.id,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      categoryId: _categoryId,
    );

    final result = await updateTask(params);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (task) {
        state = state.copyWith(isLoading: false, task: task);
        return true;
      },
    );
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void clearFocus() {
    if (titleFocusNode.hasFocus) {
      titleFocusNode.unfocus();
    }
    if (descriptionFocusNode.hasFocus) {
      descriptionFocusNode.unfocus();
    }
  }

  void disposeControllers() {
    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    descriptionFocusNode.dispose();
  }
}