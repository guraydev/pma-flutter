import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:frontend/features/project_management/presentation/notifiers/project_notifier.dart';
import 'package:frontend/core/api/generated/projects.graphql.dart'; // Your generated Project type
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Method to show Create Project Dialog (already exists, ensure it's there)
  Future<void> _showCreateProjectDialog(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    String projectName = '';
    String projectDescription = '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Create New Project'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Project Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a project name';
                      }
                      if (value.trim().length < 3) {
                        return 'Project name must be at least 3 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => projectName = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    maxLines: 3,
                    onSaved: (value) => projectDescription = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  ref.read(projectListNotifierProvider.notifier).createProject(
                        name: projectName.trim(),
                        description: projectDescription.trim().isNotEmpty ? projectDescription.trim() : null,
                      );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // NEW METHOD: Show Edit Project Dialog
  Future<void> _showEditProjectDialog(BuildContext context, WidgetRef ref, ProjectGraphqlType projectToEdit) async {
    final formKey = GlobalKey<FormState>();
    // Pre-fill with existing project data
    String projectName = projectToEdit.name;
    String projectDescription = projectToEdit.description ?? '';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit Project: ${projectToEdit.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    initialValue: projectName, // Pre-fill
                    decoration: const InputDecoration(labelText: 'Project Name'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a project name';
                      }
                      if (value.trim().length < 3) {
                        return 'Project name must be at least 3 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => projectName = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: projectDescription, // Pre-fill
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    maxLines: 3,
                    onSaved: (value) => projectDescription = value ?? '',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save Changes'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  ref.read(projectListNotifierProvider.notifier).updateProjectDetails(
                        id: projectToEdit.id, // Pass the project ID
                        name: projectName.trim(),
                        description: projectDescription.trim().isNotEmpty ? projectDescription.trim() : null,
                      );
                  Navigator.of(dialogContext).pop(); // Close the dialog
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsyncValue = ref.watch(projectListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home - My Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Projects',
            onPressed: () {
              ref.read(projectListNotifierProvider.notifier).refreshProjects();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: projectListAsyncValue.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No projects found.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showCreateProjectDialog(context, ref),
                    child: const Text('Create Your First Project'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                elevation: 2.0,
                child: ListTile(
                  title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(project.description ?? 'No description available.'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Project',
                        onPressed: () {
                          // Call the new edit dialog
                          _showEditProjectDialog(context, ref, project);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Project',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: Text('Are you sure you want to delete project "${project.name}"?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () => Navigator.of(dialogContext).pop(false),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                    onPressed: () => Navigator.of(dialogContext).pop(true),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            ref.read(projectListNotifierProvider.notifier).deleteProjectById(project.id);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('View details for "${project.name}" not implemented yet.')),
                    );
                    context.goNamed(
                      'projectDetails', // Use the route name
                      pathParameters: {'projectId': project.id},
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading projects: ${error.toString()}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(projectListNotifierProvider.notifier).refreshProjects();
                },
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context, ref),
        tooltip: 'New Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}