import 'package:freezed_annotation/freezed_annotation.dart';
// Import the generated GraphQL project type
// Adjust path if your generated files are elsewhere or named differently
import 'package:frontend/core/api/generated/projects.graphql.dart';

part 'project_state.freezed.dart';

// Using the generated QueryGetMyProjects$myProjects as our Project item type directly
// Alternatively, you could define a simpler domain ProjectEntity and map to it.
typedef ProjectGraphqlType = QueryGetMyProjects$myProjects;

@freezed
sealed class ProjectState with _$ProjectState {
  const factory ProjectState.initial() = _Initial;
  const factory ProjectState.loading() = _Loading;
  const factory ProjectState.loaded(List<ProjectGraphqlType> projects) = _Loaded;
  const factory ProjectState.error(String message) = _Error;
}