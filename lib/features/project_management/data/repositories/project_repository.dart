import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:frontend/core/api/graphql_client.dart'; // Your GraphQLClient provider

// Import the generated files. The exact path and file names might need adjustment
// based on your `build.yaml` output setting and the generator's behavior.
// Assuming output is 'lib/core/api/generated/' and it generates based on operation file names.
import 'package:frontend/core/api/generated/projects.graphql.dart';
// You might also need types from a schema-specific generated file if not all are in projects.graphql.dart
// import 'package:frontend/core/api/generated/schema.graphql.dart'; // If types are separate

// Define a simpler Project model for the UI/domain layer if needed,
// or use the generated GraphQL types directly. For now, let's assume we'll map
// the generated GraphQL types to a simpler domain/UI model or use them directly.
// For simplicity, we'll directly return generated types or a list of them.

class ProjectRepository {
  final GraphQLClient _client;

  ProjectRepository(this._client);

  // Fetch all projects for the current user
  Future<List<QueryGetMyProjects$myProjects>> getMyProjects() async {
    final options = OptionsQueryGetMyProjects(); // Generated options class
    final result = await _client.query(options);

    if (result.hasException) {
      print('GetMyProjects Exception: ${result.exception.toString()}');
      throw Exception('Failed to fetch projects');
    }

    final projects = result.data?.myProjects;
    if (projects == null) {
      return []; // Return empty list if no projects or data is null
    }
    // The generator might make myProjects nullable, or the items within nullable.
    // Filter out nulls if necessary, or adjust your GraphQL schema/query for non-nullability.
    return projects.where((p) => p != null).cast<QueryGetMyProjects$myProjects>().toList();
  }

  // Fetch a single project by ID
  Future<QueryGetProjectById$projectById?> getProjectById(String id) async {
    final options = OptionsQueryGetProjectById(
      variables: VariablesQueryGetProjectById(id: id),
    );
    final result = await _client.query(options);

    if (result.hasException) {
      print('GetProjectById Exception: ${result.exception.toString()}');
      throw Exception('Failed to fetch project details');
    }
    return result.data?.projectById;
  }

  // Create a new project
  Future<MutationCreateProject$createProject> createProject({
    required String name,
    String? description,
  }) async {
    final options = OptionsMutationCreateProject(
      variables: VariablesMutationCreateProject(
        name: name,
        description: description,
      ),
    );
    final result = await _client.mutate(options);

    if (result.hasException) {
      print('CreateProject Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Failed to create project');
    }

    final createdProject = result.data?.createProject;
    if (createdProject == null) {
      throw Exception('Failed to create project: No data returned.');
    }
    return createdProject;
  }

  // Update an existing project
  Future<MutationUpdateProject$updateProject?> updateProject({
    required String id,
    String? name,
    String? description,
  }) async {
    final options = OptionsMutationUpdateProject(
      variables: VariablesMutationUpdateProject(
        id: id,
        name: name, // Pass null if not updating, generated types handle optionality
        description: description,
      ),
    );
    final result = await _client.mutate(options);

    if (result.hasException) {
      print('UpdateProject Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Failed to update project');
    }
    return result.data?.updateProject;
  }

  // Delete a project
  Future<MutationDeleteProject$deleteProject?> deleteProject(String id) async {
    final options = OptionsMutationDeleteProject(
      variables: VariablesMutationDeleteProject(id: id),
    );
    final result = await _client.mutate(options);

    if (result.hasException) {
      print('DeleteProject Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Failed to delete project');
    }
    return result.data?.deleteProject;
  }
}

// Riverpod provider for ProjectRepository
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final client = ref.watch(graphqlClientProvider); // Get the GraphQLClient instance
  return ProjectRepository(client);
});