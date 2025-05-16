import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/project_management/data/repositories/task_repository.dart';
// Import the generated task item type and enums
import 'package:frontend/core/api/generated/tasks.graphql.dart'; // For TaskGraphqlItemType and enums
// Import schema types if enums are there, e.g.,
// import 'package:frontend/core/api/generated/schema.graphql.dart';


// Type alias for better readability
typedef TaskGraphqlItem = QueryGetTasksForProject$tasksByProjectId;

class TaskListNotifier extends FamilyAsyncNotifier<List<TaskGraphqlItem>, String> {
  // The 'arg' will be the projectId
  @override
  Future<List<TaskGraphqlItem>> build(String projectId) async {
    if (projectId.isEmpty) {
      // Or handle this case more gracefully, perhaps return empty list or specific error
      throw ArgumentError('Project ID cannot be empty when fetching tasks.');
    }
    // Initial fetch of tasks for the given projectId.
    return _fetchTasks(projectId);
  }

  Future<List<TaskGraphqlItem>> _fetchTasks(String projectId) async {
    final taskRepository = ref.read(taskRepositoryProvider);
    return await taskRepository.getTasksForProject(projectId);
  }

  Future<void> refresh() async {
    final projectId = arg; // Access the family argument (projectId)
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTasks(projectId));
  }

  Future<void> createTask({
    required String title,
    String? description,
    EnumTaskStatus? status, // Use generated EnumTaskStatus
    EnumTaskPriority? priority,
    String? dueDate,
    String? assigneeId,
  }) async {
    final projectId = arg; // The projectID for which this notifier instance is created
    final taskRepository = ref.read(taskRepositoryProvider);

    // Show loading state for the list while creating
    // More advanced: optimistic update, then confirm or revert
    state = const AsyncValue.loading(); 
    try {
      await taskRepository.createTask(
        title: title,
        projectId: projectId,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        assigneeId: assigneeId,
      );
      await refresh(); // Refetch the list to include the new task
    } catch (e) {
      print("Error creating task: $e");
      // Set an error state or revert to previous state if optimistic update was done
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateTaskInList({
    required String taskId,
    String? title,
    String? description,
    EnumTaskStatus? status,
    EnumTaskPriority? priority,
    String? dueDate,
    String? assigneeId,
  }) async {
    final taskRepository = ref.read(taskRepositoryProvider);
    // Optimistic update or refresh list
    state = const AsyncValue.loading();
    try {
      await taskRepository.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        assigneeId: assigneeId,
      );
      await refresh();
    } catch (e) {
      print("Error updating task: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTaskFromList(String taskId) async {
    final taskRepository = ref.read(taskRepositoryProvider);
    // Optimistic update or refresh list
    state = const AsyncValue.loading();
    try {
      await taskRepository.deleteTask(taskId);
      await refresh();
    } catch (e) {
      print("Error deleting task: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Provider for the TaskListNotifier
// It's a FamilyAsyncNotifierProvider because it takes an argument (projectId as String)
final taskListNotifierProvider = AsyncNotifierProviderFamily<
    TaskListNotifier, List<TaskGraphqlItem>, String>(() {
  return TaskListNotifier();
});