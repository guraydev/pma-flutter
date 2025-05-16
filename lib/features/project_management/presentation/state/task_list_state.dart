import 'package:freezed_annotation/freezed_annotation.dart';
// Import the generated GraphQL task type from your GetTasksForProject query
import 'package:frontend/core/api/generated/tasks.graphql.dart';

part 'task_list_state.freezed.dart';

// Define a type alias for the specific task type we get from the query
// This makes it easier to use in the state and notifier.
// Ensure QueryGetTasksForProject$tasksByProjectId is the correct generated name.
typedef TaskGraphqlItemType = QueryGetTasksForProject$tasksByProjectId;

@freezed
sealed class TaskListState with _$TaskListState {
  const factory TaskListState.initial() = _Initial;
  const factory TaskListState.loading() = _Loading;
  const factory TaskListState.loaded(List<TaskGraphqlItemType> tasks) = _Loaded;
  const factory TaskListState.error(String message) = _Error;
}