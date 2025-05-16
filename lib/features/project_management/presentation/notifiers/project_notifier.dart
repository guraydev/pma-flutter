import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/project_management/data/repositories/project_repository.dart';
// Import the generated project types
import 'package:frontend/core/api/generated/projects.graphql.dart'; // For list type
// For single project, the type is QueryGetProjectById$projectById
// (already implicitly available via projects.graphql.dart if it includes that query)

// Existing ProjectListNotifier class (keep as is)
class ProjectListNotifier extends AsyncNotifier<List<QueryGetMyProjects$myProjects>> {
  @override
  Future<List<QueryGetMyProjects$myProjects>> build() async {
    return _fetchProjects();
  }

  Future<List<QueryGetMyProjects$myProjects>> _fetchProjects() async {
    final projectRepository = ref.read(projectRepositoryProvider);
    return await projectRepository.getMyProjects();
  }

  Future<void> refreshProjects() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProjects());
  }

  Future<void> createProject({
    required String name,
    String? description,
  }) async {
    final projectRepository = ref.read(projectRepositoryProvider);
    try {
      await projectRepository.createProject(name: name, description: description);
      await refreshProjects();
    } catch (e) {
      print("Error creating project: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateProjectDetails({
    required String id,
    String? name,
    String? description,
  }) async {
    final projectRepository = ref.read(projectRepositoryProvider);
    try {
      await projectRepository.updateProject(id: id, name: name, description: description);
      await refreshProjects();
    } catch (e) {
      print("Error updating project: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteProjectById(String id) async {
    final projectRepository = ref.read(projectRepositoryProvider);
    try {
      await projectRepository.deleteProject(id);
      await refreshProjects();
    } catch (e) {
      print("Error deleting project: $e");
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final projectListNotifierProvider =
    AsyncNotifierProvider<ProjectListNotifier, List<QueryGetMyProjects$myProjects>>(() {
  return ProjectListNotifier();
});

// NEW: Notifier and Provider for a single project's details
// The state is the project details type, potentially nullable if not found.
// We use QueryGetProjectById$projectById from the generated files.
class SingleProjectNotifier extends FamilyAsyncNotifier<QueryGetProjectById$projectById?, String> {
  // 'arg' will be the projectId
  @override
  Future<QueryGetProjectById$projectById?> build(String projectId) async {
    return _fetchProjectDetails(projectId);
  }

  Future<QueryGetProjectById$projectById?> _fetchProjectDetails(String projectId) async {
    if (projectId.isEmpty) return null; // Or throw error
    final projectRepository = ref.read(projectRepositoryProvider);
    return await projectRepository.getProjectById(projectId);
  }

  Future<void> refreshProjectDetails() async {
    // 'arg' is the family parameter (projectId)
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProjectDetails(arg));
  }
}

final singleProjectNotifierProvider = AsyncNotifierProviderFamily<
    SingleProjectNotifier, QueryGetProjectById$projectById?, String>(() {
  return SingleProjectNotifier();
});