import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/project_management/presentation/notifiers/project_notifier.dart'; // For singleProjectNotifierProvider
import 'package:frontend/features/project_management/presentation/notifiers/task_list_notifier.dart'; // For taskListNotifierProvider
// Import generated types
import 'package:frontend/core/api/generated/projects.graphql.dart' show QueryGetProjectById$projectById;
import 'package:frontend/core/api/generated/tasks.graphql.dart' show TaskGraphqlItem, EnumTaskStatus, EnumTaskPriority; // Make sure Enum names are correct

class ProjectDetailsScreen extends ConsumerWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  // Helper method to show a dialog for creating a new task
  Future<void> _showCreateTaskDialog(BuildContext context, WidgetRef ref, String currentProjectId) async {
    final formKey = GlobalKey<FormState>();
    String taskTitle = '';
    String taskDescription = '';
    EnumTaskStatus selectedStatus = EnumTaskStatus.TODO; // Default, ensure this enum name is correct
    EnumTaskPriority selectedPriority = EnumTaskPriority.MEDIUM; // Default
    // Add controllers for other fields like dueDate, assigneeId if needed

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Create New Task'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Task Title'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a task title';
                      }
                      if (value.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      return null;
                    },
                    onSaved: (value) => taskTitle = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description (Optional)'),
                    maxLines: 3,
                    onSaved: (value) => taskDescription = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  // Dropdown for Status
                  DropdownButtonFormField<EnumTaskStatus>(
                    decoration: const InputDecoration(labelText: 'Status'),
                    value: selectedStatus,
                    items: EnumTaskStatus.values.map((EnumTaskStatus status) { // Ensure EnumTaskStatus.values is correct
                      return DropdownMenuItem<EnumTaskStatus>(
                        value: status,
                        child: Text(status.name.replaceAll('_', ' ')), // Display formatted name
                      );
                    }).toList(),
                    onChanged: (EnumTaskStatus? newValue) {
                      if (newValue != null) {
                        // This needs to be in a StatefulWidget or manage state with local provider for dialog
                        // For simplicity in AlertDialog, we might need to wrap Form in a StatefulBuilder
                        // Or, update a local variable and rely on formKey.save()
                        selectedStatus = newValue;
                      }
                    },
                    onSaved: (value) => selectedStatus = value ?? EnumTaskStatus.TODO,
                  ),
                  const SizedBox(height: 16),
                  // Dropdown for Priority
                  DropdownButtonFormField<EnumTaskPriority>(
                    decoration: const InputDecoration(labelText: 'Priority'),
                    value: selectedPriority,
                    items: EnumTaskPriority.values.map((EnumTaskPriority priority) { // Ensure EnumTaskPriority.values is correct
                      return DropdownMenuItem<EnumTaskPriority>(
                        value: priority,
                        child: Text(priority.name.replaceAll('_', ' ')),
                      );
                    }).toList(),
                    onChanged: (EnumTaskPriority? newValue) {
                       if (newValue != null) {
                        selectedPriority = newValue;
                      }
                    },
                    onSaved: (value) => selectedPriority = value ?? EnumTaskPriority.MEDIUM,
                  ),
                  // TODO: Add fields for Due Date (e.g., DatePicker), Assignee (e.g., Dropdown from users list)
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
              child: const Text('Create Task'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  ref.read(taskListNotifierProvider(currentProjectId).notifier).createTask(
                        title: taskTitle.trim(),
                        // projectId is implicit via the notifier family argument
                        description: taskDescription.trim().isNotEmpty ? taskDescription.trim() : null,
                        status: selectedStatus,
                        priority: selectedPriority,
                        // dueDate: ...
                        // assigneeId: ...
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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectAsyncValue = ref.watch(singleProjectNotifierProvider(projectId));
    final taskListAsyncValue = ref.watch(taskListNotifierProvider(projectId)); // Watch tasks for this project

    return Scaffold(
      appBar: AppBar(
        title: projectAsyncValue.when(
          data: (project) => Text(project?.name ?? 'Project Details'),
          loading: () => const Text('Loading Project...'),
          error: (_, __) => const Text('Project Error'),
        ),
        actions: [
          if (projectAsyncValue is! AsyncLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(singleProjectNotifierProvider(projectId).notifier).refreshProjectDetails();
                ref.read(taskListNotifierProvider(projectId).notifier).refresh(); // Refresh tasks too
              },
              tooltip: 'Refresh All Details',
            ),
        ],
      ),
      body: projectAsyncValue.when(
        data: (projectData) {
          if (projectData == null) {
            return const Center(child: Text('Project not found.'));
          }
          // Display Project Details
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectData.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8.0),
                    Text(projectData.description ?? 'No description for this project.'),
                    const SizedBox(height: 8.0),
                    Text('Created: ${projectData.createdAt}', style: Theme.of(context).textTheme.bodySmall), // Format date
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Tasks', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: taskListAsyncValue.when(
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const Center(child: Text('No tasks yet. Add one!'));
                    }
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return ListTile(
                          title: Text(task.title),
                          subtitle: Text(task.description ?? 'No description'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(task.status.name.replaceAll('_', ' '), style: TextStyle(fontSize: 12, color: Colors.grey[600])), // Ensure task.status.name is correct
                              const SizedBox(width: 8),
                              // TODO: Add Edit/Delete Task buttons
                              IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {
                                // _showEditTaskDialog(context, ref, projectId, task);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit task ${task.title} TBD')));
                              }),
                            ],
                          ),
                          // onTap: () { /* Navigate to task details if needed */},
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading tasks: $err'),
                        ElevatedButton(
                          onPressed: () => ref.read(taskListNotifierProvider(projectId).notifier).refresh(),
                          child: const Text('Retry Tasks'),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading project details: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context, ref, projectId),
        tooltip: 'Add Task',
        child: const Icon(Icons.add_task),
      ),
    );
  }
}