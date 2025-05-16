import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:frontend/core/api/graphql_client.dart'; // Your GraphQLClient provider

// Import the generated files for task operations.
// Adjust the import path if your generated files are structured differently.
import 'package:frontend/core/api/generated/tasks.graphql.dart';
// You might also need schema types if they are in a separate file, e.g.:
// import 'package:frontend/core/api/generated/schema.graphql.dart';

class TaskRepository {
  final GraphQLClient _client;

  TaskRepository(this._client);

  // Fetch tasks for a specific project
  Future<List<QueryGetTasksForProject$tasksByProjectId>> getTasksForProject(String projectId) async {
    final options = OptionsQueryGetTasksForProject(
      variables: VariablesQueryGetTasksForProject(projectId: projectId),
    );
    final result = await _client.query(options);

    if (result.hasException) {
      print('GetTasksForProject Exception: ${result.exception.toString()}');
      throw Exception('Failed to fetch tasks for project');
    }

    final tasks = result.data?.tasksByProjectId;
    if (tasks == null) {
      return [];
    }
    // Filter out any null tasks if the list itself can contain nulls, and cast
    return tasks.where((t) => t != null).cast<QueryGetTasksForProject$tasksByProjectId>().toList();
  }

  // Fetch a single task by its ID
  Future<QueryGetTaskById$taskById?> getTaskById(String taskId) async {
    final options = OptionsQueryGetTaskById(
      variables: VariablesQueryGetTaskById(taskId: taskId),
    );
    final result = await _client.query(options);

    if (result.hasException) {
      print('GetTaskById Exception: ${result.exception.toString()}');
      throw Exception('Failed to fetch task details');
    }
    return result.data?.taskById;
  }

  // Create a new task
  Future<MutationCreateTask$createTask> createTask({
    required String title,
    required String projectId,
    String? description,
    EnumTaskStatus? status, // Use generated EnumTaskStatus
    EnumTaskPriority? priority, // Use generated EnumTaskPriority
    String? dueDate, // Assuming DateTime scalar maps to String (ISO8601) for input
    String? assigneeId,
  }) async {
    final options = OptionsMutationCreateTask(
      variables: VariablesMutationCreateTask(
        title: title,
        projectId: projectId,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate, // Pass directly if it's String or correct scalar type
        assigneeId: assigneeId,
      ),
    );
    final result = await _client.mutate(options);

    if (result.hasException) {
      print('CreateTask Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Failed to create task');
    }

    final createdTask = result.data?.createTask;
    if (createdTask == null) {
      throw Exception('Failed to create task: No data returned.');
    }
    return createdTask;
  }

  // Update an existing task
  Future<MutationUpdateTask$updateTask?> updateTask({
    required String taskId,
    String? title,
    String? description,
    EnumTaskStatus? status,
    EnumTaskPriority? priority,
    String? dueDate, // Allow null to clear if backend DTO handles it
    String? assigneeId, // Allow null to unassign
  }) async {
    final options = OptionsMutationUpdateTask(
      variables: VariablesMutationUpdateTask(
        taskId: taskId,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        assigneeId: assigneeId,
      ),
    );
    final result = await _client.mutate(options);

    if (result.hasException) {
      print('UpdateTask Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Failed to update task');
    }
    return result.data?.updateTask;
  }

  // Delete a task
  Future<MutationDeleteTask$deleteTask?> deleteTask(String taskId) async {
    final options = OptionsMutationDeleteTask(
      variables: VariablesMutationDeleteTask(taskId: taskId),
    );
    final result = await _client.mutate(options);

    if (result.hasException) {
      print('DeleteTask Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Failed to delete task');
    }
    return result.data?.deleteTask;
  }
}

// Riverpod provider for TaskRepository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final client = ref.watch(graphqlClientProvider); // Get the GraphQLClient instance
  return TaskRepository(client);
});