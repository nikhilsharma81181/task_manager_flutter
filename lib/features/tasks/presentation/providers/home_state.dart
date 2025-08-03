import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

enum DateFilter {
  all,
  today,
  tomorrow,
  thisWeek,
  thisMonth,
  overdue,
  custom,
}

abstract class HomeState extends Equatable {
  const HomeState();
}

class HomeInitial extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeLoading extends HomeState {
  @override
  List<Object> get props => [];
}

class HomeLoaded extends HomeState {
  final List<TaskEntity> tasks;
  final List<TaskEntity> filteredTasks;
  final List<TaskEntity> paginatedTasks;
  final String searchQuery;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final String? categoryFilter;
  final DateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final int currentPage;
  final int itemsPerPage;
  final bool hasMorePages;
  final bool isLoadingMore;

  const HomeLoaded({
    required this.tasks,
    required this.filteredTasks,
    required this.paginatedTasks,
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
    this.categoryFilter,
    this.dateFilter = DateFilter.all,
    this.customStartDate,
    this.customEndDate,
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.hasMorePages = false,
    this.isLoadingMore = false,
  });

  HomeLoaded copyWith({
    List<TaskEntity>? tasks,
    List<TaskEntity>? filteredTasks,
    List<TaskEntity>? paginatedTasks,
    String? searchQuery,
    TaskStatus? statusFilter,
    TaskPriority? priorityFilter,
    String? categoryFilter,
    DateFilter? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    int? currentPage,
    int? itemsPerPage,
    bool? hasMorePages,
    bool? isLoadingMore,
    bool clearStatusFilter = false,
    bool clearPriorityFilter = false,
    bool clearCategoryFilter = false,
    bool clearDateFilter = false,
    bool clearCustomDates = false,
  }) {
    return HomeLoaded(
      tasks: tasks ?? this.tasks,
      filteredTasks: filteredTasks ?? this.filteredTasks,
      paginatedTasks: paginatedTasks ?? this.paginatedTasks,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      priorityFilter:
          clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      dateFilter: clearDateFilter ? DateFilter.all : (dateFilter ?? this.dateFilter),
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        tasks,
        filteredTasks,
        paginatedTasks,
        searchQuery,
        statusFilter,
        priorityFilter,
        categoryFilter,
        dateFilter,
        customStartDate,
        customEndDate,
        currentPage,
        itemsPerPage,
        hasMorePages,
        isLoadingMore,
      ];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
