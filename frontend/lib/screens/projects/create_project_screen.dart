import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/project_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_text_field.dart';
import 'package:frontend/widgets/member_selection.dart';
import 'package:provider/provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _deadline;
  List<User> _selectedMembers = [];

  bool _isLoading = false;
  String? _error;

  final ProjectService _projectService = ProjectService();

  @override
  void initState() {
    super.initState();
    // Add current user as a member by default
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      _selectedMembers = [authProvider.user!];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token!;

        final projectData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'deadline': _deadline?.toIso8601String(),
          'members': _selectedMembers.map((member) => member.id).toList(),
        };

        // Debug print
        print('Creating project with data: $projectData');
        print('Using token: $token');

        await _projectService.createProject(token, projectData);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        print('Error creating project: $e');
        setState(() {
          _error = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                labelText: 'Project Title',
                hintText: 'Enter project title',
                prefixIcon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Enter project description (optional)',
                prefixIcon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deadline',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _deadline == null
                                  ? 'No deadline set'
                                  : 'Deadline: ${_deadline!.toLocal().toString().split(' ')[0]}',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              _deadline == null ? 'Set Deadline' : 'Change',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MemberSelection(
                    selectedMembers: _selectedMembers,
                    onMembersChanged: (members) {
                      setState(() {
                        _selectedMembers = members;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              CustomButton(
                text: 'Create Project',
                isLoading: _isLoading,
                onPressed: _createProject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
