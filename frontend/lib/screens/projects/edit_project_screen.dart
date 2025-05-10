import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/models/project.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/project_service.dart';
import 'package:frontend/core/services/user_service.dart';
import 'package:intl/intl.dart';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _searchController;
  late DateTime? _deadline;
  late User _selectedManager;
  List<User> _availableMembers = [];
  List<User> _selectedMembers = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;
      final userRole = authProvider.user?.role.toLowerCase();
      final isOwner = currentUserId == widget.project.manager;
      final isAdmin = userRole == 'admin';
      if (!isOwner && !isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Only owners or admins can edit the project.')),
        );
        Navigator.of(context).pop();
      }
    });
    _titleController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );
    _searchController = TextEditingController();
    _deadline = widget.project.deadline;
    _selectedMembers = widget.project.members.map((u) {
      if (u.role.isEmpty) {
        return User(
          id: u.id,
          name: u.name,
          email: u.email,
          role: 'viewer',
          profilePicture: u.profilePicture,
          contactInfo: u.contactInfo,
          createdAt: u.createdAt,
          updatedAt: u.updatedAt,
        );
      }
      return u;
    }).toList();
    // Ensure the manager is present in the available members list
    final managerId = widget.project.manager;
    final managerExists = _selectedMembers.any((u) => u.id == managerId);
    if (!managerExists) {
      final managerUser = User(
        id: managerId,
        name: 'Manager', // Optionally fetch the real name
        email: '',
        role: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _selectedMembers.insert(0, managerUser);
    }
    _availableMembers = List.from(_selectedMembers);
    if (_availableMembers.any((u) => u.id == managerId)) {
      _selectedManager = _availableMembers.firstWhere((u) => u.id == managerId);
    } else {
      _selectedManager = _availableMembers.isNotEmpty
          ? _availableMembers.first
          : User(
              id: '',
              name: '',
              email: '',
              role: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
    }
    // Parse the project color
    try {
      _selectedColor =
          Color(int.parse(widget.project.color.replaceAll('#', '0xFF')));
    } catch (e) {
      _selectedColor = Colors.blue; // Default color if parsing fails
    }
    // Debug prints to check project data and members
    print(
        'EditProjectScreen initState - Project data: ${widget.project.toJson()}');
    print(
        'EditProjectScreen initState - Members data: ${widget.project.members}');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token != null) {
        final userService = UserService();
        final users = await userService.getAllUsers(authProvider.token!);

        // Filter out current members and search by name
        final results = users
            .where(
              (user) =>
                  !_selectedMembers.any((m) => m.id == user.id) &&
                  user.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
      }
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.token != null) {
      try {
        final projectService = ProjectService();
        final projectData = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'deadline': _deadline?.toIso8601String(),
          'manager': _selectedManager.id,
          'members': _selectedMembers
              .map((m) => {
                    'userId': m.id,
                    'role': m.role.isNotEmpty ? m.role : 'member',
                  })
              .toList(),
          'status': widget.project.status,
          'color': widget.project.color,
        };

        // Debug print
        print('Saving project with data: $projectData');

        await projectService.updateProject(
          authProvider.token!,
          widget.project.id,
          projectData,
        );

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating project: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug print for member roles
    print('DEBUG: _selectedMembers = ' +
        _selectedMembers.map((m) => m.name + ':' + m.role).join(', '));
    final roles = ['owner', 'admin', 'member', 'viewer'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProject,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Deadline'),
                      subtitle: Text(
                        _deadline != null
                            ? DateFormat('MMM dd, yyyy').format(_deadline!)
                            : 'No deadline set',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Project Manager',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedManager.id,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _availableMembers.map((user) {
                        return DropdownMenuItem(
                          value: user.id,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedManager = _availableMembers.firstWhere(
                              (u) => u.id == value,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Project Members',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    // Current members list
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedMembers.map((member) {
                        // Debug print for each member
                        print('DEBUG: Rendering member ' +
                            member.name +
                            ' with role ' +
                            member.role);
                        final currentRole = roles.contains(member.role)
                            ? member.role
                            : 'viewer';
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(member.name.isNotEmpty
                                  ? member.name
                                  : 'Loading...'),
                              deleteIcon: const Icon(
                                Icons.remove_circle_outline,
                              ),
                              onDeleted: () {
                                setState(() {
                                  _selectedMembers.remove(member);
                                  if (_selectedManager.id == member.id) {
                                    _selectedManager = _selectedMembers.first;
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 120,
                              child: DropdownButton<String>(
                                value: currentRole,
                                items: roles
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role,
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 16),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (newRole) {
                                  setState(() {
                                    member.role = newRole!;
                                  });
                                },
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Search bar for new members
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search users to add',
                        border: const OutlineInputBorder(),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => _searchUsers(
                                  _searchController.text,
                                ),
                              ),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _searchResults = [];
                          });
                        }
                      },
                      onSubmitted: _searchUsers,
                    ),
                    const SizedBox(height: 8),
                    // Search results
                    if (_searchResults.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _selectedMembers.add(User(
                                    id: user.id,
                                    name: user.name,
                                    email: user.email,
                                    role: 'viewer',
                                    profilePicture: user.profilePicture,
                                    contactInfo: user.contactInfo,
                                    createdAt: user.createdAt,
                                    updatedAt: user.updatedAt,
                                  ));
                                  _searchResults.remove(user);
                                  _searchController.clear();
                                });
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }
}
