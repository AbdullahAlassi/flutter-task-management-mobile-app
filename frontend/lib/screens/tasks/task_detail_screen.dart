import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/task_service.dart';
import 'package:frontend/core/services/subtask_service.dart';
import 'package:frontend/widgets/user_avatar.dart';
import 'package:frontend/core/services/user_service.dart';
import 'package:frontend/widgets/subtask_card.dart';
import 'package:frontend/screens/attachments/attachment_preview_screen.dart';
import 'package:frontend/widgets/member_selection.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();
  final SubtaskService _subtaskService = SubtaskService();
  bool _isLoading = false;
  String? _error;
  late Task _task;
  List<Map<String, dynamic>> _subtasks = [];
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _loadSubtasks();
    // Use the actual attachments from the task instead of hardcoded example
    _attachments =
        _task.attachments
            .map(
              (attachment) => {
                'name': attachment.name,
                'type': attachment.type,
                'url': attachment.url,
                'uploadedAt': attachment.uploadedAt.toIso8601String(),
              },
            )
            .toList();
  }

  Future<void> _loadSubtasks() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Authentication token is missing');
      }

      final subtasks = await _subtaskService.getSubtasksByTask(
        authProvider.token!,
        _task.id,
      );

      setState(() {
        _subtasks = subtasks;
      });
    } catch (e) {
      debugPrint('Error loading subtasks: $e');
    }
  }

  Future<void> _updateTaskStatus(String status) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Authentication token is missing');
      }

      final updatedTask = await _taskService.updateTask(
        authProvider.token!,
        _task.id,
        {'status': status},
      );

      setState(() {
        _task = updatedTask;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating task: $_error')));
    }
  }

  Future<void> _addMemberToTask() async {
    // Show a bottom sheet to select members
    final result = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true, // Makes the bottom sheet expandable
      backgroundColor:
          Colors.transparent, // Transparent background for rounded corners
      builder: (context) => _buildAddMemberBottomSheet(),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token == null) {
          throw Exception('Authentication token is missing');
        }

        // Check if member is already in the task
        if (_task.assignees.any((user) => user.id == result.id)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This member is already assigned to the task'),
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Create a new list with the added member
        final updatedAssignees = [..._task.assignees, result];

        // Debug log to check what we're sending
        print(
          'Updating task ${_task.id} with assignees: ${updatedAssignees.map((user) => user.id).toList()}',
        );

        // Update the task with the new assignees
        final updatedTask = await _taskService.updateTask(
          authProvider.token!,
          _task.id,
          {'assignees': updatedAssignees.map((user) => user.id).toList()},
        );

        // Debug log to check the response
        print(
          'Server response: ${updatedTask.assignees.map((user) => user.id).toList()}',
        );

        setState(() {
          _task = updatedTask;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result.name} added to the task')),
        );
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding member: $_error')));
      }
    }
  }

  Widget _buildAddMemberBottomSheet() {
    final TextEditingController searchController = TextEditingController();
    final UserService userService = UserService();

    return StatefulBuilder(
      builder: (context, setState) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, // Initial height (70% of screen)
          minChildSize: 0.5, // Minimum height (50% of screen)
          maxChildSize: 0.9, // Maximum height (90% of screen)
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Team Member',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by email',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        // Trigger search on text change
                        setState(() {
                          // This will rebuild the StatefulBuilder with the new search term
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Results list
                  Expanded(
                    child: FutureBuilder<List<User>>(
                      future:
                          searchController.text.isEmpty
                              ? Future.value([])
                              : _searchUsers(searchController.text),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final users = snapshot.data ?? [];

                        if (users.isEmpty && searchController.text.isNotEmpty) {
                          return const Center(child: Text('No users found'));
                        }

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return ListTile(
                              leading: UserAvatar(user: user, size: 40),
                              title: Text(user.name),
                              subtitle: Text(user.email),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop(user);
                                },
                              ),
                              onTap: () {
                                Navigator.of(context).pop(user);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<User>> _searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Authentication token is missing');
      }

      final userService = UserService();
      final results = await userService.searchUsersByEmail(
        authProvider.token!,
        query,
      );

      // Filter out users that are already assigned
      return results
          .where(
            (user) =>
                !_task.assignees.any((assignee) => assignee.id == user.id),
          )
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  Future<void> _addAttachment() async {
    // Show a dialog to add a new attachment
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildAddAttachmentDialog(),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token == null) {
          throw Exception('Authentication token is missing');
        }

        // Create a new list with the added attachment
        final updatedAttachments = [
          ..._task.attachments,
          Attachment(
            name: result['name'],
            type: result['type'],
            url: result['url'],
            uploadedAt: DateTime.now(),
          ),
        ];

        // Update the task with the new attachments
        final updatedTask = await _taskService.updateTask(
          authProvider.token!,
          _task.id,
          {'attachments': updatedAttachments.map((a) => a.toJson()).toList()},
        );

        if (mounted) {
          setState(() {
            _task = updatedTask;
            _attachments =
                updatedTask.attachments
                    .map(
                      (a) => {
                        'name': a.name,
                        'type': a.type,
                        'url': a.url,
                        'uploadedAt': a.uploadedAt.toIso8601String(),
                      },
                    )
                    .toList();
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attachment added successfully')),
          );
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding attachment: $_error')),
        );
      }
    }
  }

  Widget _buildAddAttachmentDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    String selectedType = 'pdf';

    return AlertDialog(
      title: const Text('Add Attachment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Attachment Name',
              hintText: 'Enter attachment name',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'Enter attachment URL',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
              DropdownMenuItem(value: 'doc', child: Text('Document')),
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (value) {
              selectedType = value!;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (nameController.text.isNotEmpty &&
                urlController.text.isNotEmpty) {
              Navigator.of(context).pop({
                'name': nameController.text,
                'type': selectedType,
                'url': urlController.text,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attachments (${_attachments.length})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addAttachment,
              tooltip: 'Add Attachment',
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_attachments.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _attachments.map((attachment) {
                  // Check if it's an image by looking at the type string
                  final isImage =
                      attachment['type']?.toString().toLowerCase().startsWith(
                        'image',
                      ) ??
                      false;

                  return InkWell(
                    onTap: () {
                      String url = attachment['url'] ?? '';
                      // Convert local file path to file:// URL if it's a local path
                      if (url.startsWith('/') || url.contains(':\\')) {
                        url = 'file://$url';
                      }

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (_) => AttachmentPreviewScreen(
                                attachmentUrl: url,
                                fileName: attachment['name'] ?? 'Unknown file',
                                fileType:
                                    attachment['type'] ??
                                    'application/octet-stream',
                                onDelete: () async {
                                  try {
                                    final authProvider =
                                        Provider.of<AuthProvider>(
                                          context,
                                          listen: false,
                                        );
                                    if (authProvider.token == null) {
                                      throw Exception(
                                        'Authentication token is missing',
                                      );
                                    }

                                    // Create a new list without the deleted attachment
                                    final updatedAttachments =
                                        _task.attachments
                                            .where(
                                              (a) =>
                                                  a.url != attachment['url'] &&
                                                  a.name != attachment['name'],
                                            )
                                            .toList();

                                    // Update the task with the new attachments list
                                    final updatedTask = await _taskService
                                        .updateTask(
                                          authProvider.token!,
                                          _task.id,
                                          {
                                            'attachments':
                                                updatedAttachments
                                                    .map((a) => a.toJson())
                                                    .toList(),
                                          },
                                        );

                                    // Update both the task and the local attachments list
                                    if (mounted) {
                                      setState(() {
                                        _task = updatedTask;
                                        _attachments =
                                            _attachments
                                                .where(
                                                  (a) =>
                                                      a['url'] !=
                                                          attachment['url'] &&
                                                      a['name'] !=
                                                          attachment['name'],
                                                )
                                                .toList();
                                      });
                                    }

                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Attachment deleted successfully',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error deleting attachment: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          isImage
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  attachment['url'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Error loading image',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              )
                              : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getFileIcon(attachment['type']),
                                    size: 32,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      attachment['name'] ?? 'Unknown file',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  IconData _getFileIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;

    final type = fileType.toLowerCase();
    if (type.startsWith('image/') || type.contains('image')) {
      return Icons.image;
    } else if (type.startsWith('video/') || type.contains('video')) {
      return Icons.video_file;
    } else if (type.startsWith('audio/') || type.contains('audio')) {
      return Icons.audio_file;
    } else if (type.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (type.contains('word') || type.contains('doc')) {
      return Icons.description;
    } else if (type.contains('excel') || type.contains('sheet')) {
      return Icons.table_chart;
    } else if (type.contains('powerpoint') || type.contains('presentation')) {
      return Icons.slideshow;
    } else if (type.contains('zip') || type.contains('compressed')) {
      return Icons.archive;
    }
    return Icons.insert_drive_file;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  Future<void> _showStatusEditDialog() async {
    final statuses = ['To Do', 'In Progress', 'In Review', 'Done'];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Task Status'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  statuses.map((status) {
                    return RadioListTile<String>(
                      title: Text(status),
                      value: status,
                      groupValue: _task.status,
                      onChanged: (value) async {
                        if (value != null) {
                          await _updateTaskStatus(value);
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _task.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showStatusEditDialog,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colorful gradient banner
                    _buildGradientBanner(),

                    const SizedBox(height: 16),

                    // Task description
                    Text(
                      _task.description ??
                          'Discussion and looking for project references.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                    ),

                    const SizedBox(height: 24),

                    // Team section
                    _buildInfoRow(
                      icon: Icons.people_outline,
                      title: 'Team',
                      child: _buildTeamMembers(_task.assignees),
                    ),

                    const SizedBox(height: 16),

                    // Leader section
                    _buildInfoRow(
                      icon: Icons.person_outline,
                      title: 'Leader',
                      child: _buildLeader(),
                    ),

                    const SizedBox(height: 16),

                    // Status section
                    _buildInfoRow(
                      icon: Icons.check_circle_outline,
                      title: 'Status',
                      child: _buildStatusSelector(),
                    ),

                    const SizedBox(height: 16),

                    // Due Date section
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'Due Date',
                      child: _buildDueDate(),
                    ),

                    const SizedBox(height: 16),

                    // Attachment section
                    _buildAttachmentsSection(),

                    const SizedBox(height: 24),

                    // Sub-Tasks section
                    _buildSubTasksSection(),

                    const SizedBox(height: 16),

                    // Add New Sub-Task button
                    _buildAddSubTaskButton(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }

  Widget _buildGradientBanner() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade300,
                Colors.purple.shade500,
                Colors.pink.shade400,
                Colors.red.shade300,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                // Implement edit banner functionality
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMembers(List<User> members) {
    return SizedBox(
      width:
          MediaQuery.of(context).size.width -
          72, // Account for padding and icon
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: members.length + 1, // +1 for the add button
                itemBuilder: (context, index) {
                  if (index == members.length) {
                    return GestureDetector(
                      onTap: _addMemberToTask,
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  }
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: UserAvatar(user: members[index], size: 40),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeader() {
    // In a real app, you would get the project manager
    // For now, we'll use the first assignee or a placeholder
    final leader = _task.assignees.isNotEmpty ? _task.assignees[0] : null;

    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child:
              leader != null
                  ? UserAvatar(user: leader, size: 40)
                  : const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
        ),
        Text(
          leader != null ? '${leader.name} (you)' : 'Daniel Austin (you)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        _task.status,
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDueDate() {
    final formattedDate =
        _task.deadline != null
            ? DateFormat('MMM d, yyyy').format(_task.deadline!)
            : 'No deadline set';

    return Row(
      children: [
        Text(
          'Due date: $formattedDate',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          onPressed: _editDueDate,
        ),
      ],
    );
  }

  Future<void> _editDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _task.deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // Allow selecting dates from a year ago
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 2),
      ), // Allow selecting dates up to 2 years in the future
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Calendar text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && (pickedDate != _task.deadline)) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token == null) {
          throw Exception('Authentication token is missing');
        }

        // Update the task with the new deadline
        final updatedTask = await _taskService.updateTask(
          authProvider.token!,
          _task.id,
          {'deadline': pickedDate.toIso8601String()},
        );

        setState(() {
          _task = updatedTask;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Due date updated successfully')),
        );
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating due date: $_error')),
        );
      }
    }
  }

  Widget _buildSubTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sub-Task (${_subtasks.length})',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (_subtasks.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _subtasks.length,
            itemBuilder: (context, index) {
              final subtask = _subtasks[index];
              return SubtaskCard(
                title: subtask['title'],
                deadline:
                    subtask['deadline'] != null
                        ? DateTime.parse(subtask['deadline'])
                        : null,
                isCompleted: subtask['isCompleted'] ?? false,
                onStatusChanged: (completed) async {
                  try {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    if (authProvider.token == null) {
                      throw Exception('Authentication token is missing');
                    }

                    await _subtaskService.updateSubtask(
                      authProvider.token!,
                      subtask['_id'],
                      {'isCompleted': completed},
                    );

                    _loadSubtasks(); // Refresh the subtasks list
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating subtask: $e')),
                    );
                  }
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _showAddSubtaskDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddSubtaskDialog(taskAssignees: _task.assignees),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.token == null) {
          throw Exception('Authentication token is missing');
        }

        await _subtaskService.createSubtask(
          authProvider.token!,
          _task.id,
          result,
        );

        _loadSubtasks(); // Refresh the subtasks list

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subtask added successfully')),
        );
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subtask: $_error')),
        );
      }
    }
  }

  Widget _buildAddSubTaskButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextButton.icon(
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add New Sub-Task',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onPressed: _showAddSubtaskDialog,
      ),
    );
  }
}

class _AddSubtaskDialog extends StatefulWidget {
  final List<User> taskAssignees;

  const _AddSubtaskDialog({required this.taskAssignees});

  @override
  State<_AddSubtaskDialog> createState() => _AddSubtaskDialogState();
}

class _AddSubtaskDialogState extends State<_AddSubtaskDialog> {
  final _titleController = TextEditingController();
  DateTime? _deadline;
  List<User> _selectedAssignees = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Sub-Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter subtask title',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Deadline: ${_deadline != null ? DateFormat('MMM d, y').format(_deadline!) : 'Not set'}',
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _deadline = date;
                      });
                    }
                  },
                  child: const Text('Set Deadline'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Assign to:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.taskAssignees.map((user) {
                    final isSelected = _selectedAssignees.contains(user);
                    return FilterChip(
                      label: Text(user.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAssignees.add(user);
                          } else {
                            _selectedAssignees.remove(user);
                          }
                        });
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.trim().isNotEmpty) {
              Navigator.of(context).pop({
                'title': _titleController.text.trim(),
                'deadline': _deadline?.toIso8601String(),
                'assignees': _selectedAssignees.map((user) => user.id).toList(),
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
