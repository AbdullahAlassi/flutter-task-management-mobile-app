import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/models/project.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/core/config/environment.dart';
import 'package:frontend/core/models/user.dart';

class ManageMembersScreen extends StatefulWidget {
  final Project project;
  final Function()? onMembersUpdated;

  const ManageMembersScreen({
    Key? key,
    required this.project,
    this.onMembersUpdated,
  }) : super(key: key);

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  bool _isUpdating = false;
  final List<String> projectRoles = ['member', 'admin', 'viewer'];
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  Future<void> searchUsers(String query) async {
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
      final response = await http.get(
        Uri.parse('${Environment.apiUrl}/api/users/search?q=$query'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['users'] ?? [];
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> addNewMember(String userId, String role) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.post(
        Uri.parse(
            '${Environment.apiUrl}/api/teams/project/${widget.project.id}/members'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'role': role,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Member added successfully')),
        );
        if (widget.onMembersUpdated != null) {
          widget.onMembersUpdated!();
        }
        setState(() {
          _searchResults = [];
          _searchController.clear();
        });
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to add member: ${error['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding member: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> updateMemberRole(String userId, String newRole) async {
    setState(() {
      _isUpdating = true;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await http.patch(
        Uri.parse(
            '${Environment.apiUrl}/api/projects/${widget.project.id}/members/$userId/role'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated successfully')),
        );
        if (widget.onMembersUpdated != null) {
          widget.onMembersUpdated!();
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to update role: ${error['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating role: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.user?.role?.toLowerCase() ?? 'viewer';

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Members'),
      ),
      body: _isUpdating
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search users to add',
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: searchUsers,
                  ),
                ),
                if (_isSearching)
                  Center(child: CircularProgressIndicator())
                else if (_searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          title: Text(user['name'] ?? ''),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Select Project Role'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: projectRoles
                                        .map((role) => ListTile(
                                              title: Text(role.toUpperCase()),
                                              onTap: () {
                                                Navigator.pop(context);
                                                addNewMember(user['_id'], role);
                                              },
                                            ))
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                            child: Text('Add'),
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.project.members.length,
                    itemBuilder: (context, index) {
                      final member = widget.project.members[index];
                      String currentRole = 'member';
                      String displayName = '';
                      String userId = '';

                      if (member is Map<String, dynamic>) {
                        final memberMap = member as Map<String, dynamic>;
                        final user = memberMap['userId'];
                        currentRole =
                            memberMap['role']?.toLowerCase() ?? 'member';
                        if (user is Map<String, dynamic>) {
                          displayName = (user['name']?.isNotEmpty ?? false)
                              ? user['name'] as String
                              : (user['_id'] ?? '') as String;
                          userId = (user['_id'] ?? '') as String;
                        } else if (user is User) {
                          displayName =
                              user.name.isNotEmpty ? user.name : user.id;
                          userId = user.id;
                        }
                      } else if (member is User) {
                        displayName =
                            member.name.isNotEmpty ? member.name : member.id;
                        userId = member.id;
                        currentRole = member.role?.toLowerCase() ?? 'member';
                      }

                      return ListTile(
                        title: Text(displayName),
                        subtitle: Text('Role: ${currentRole.toUpperCase()}'),
                        trailing: (userRole == 'owner' || userRole == 'admin')
                            ? DropdownButton<String>(
                                value: currentRole,
                                items: projectRoles
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role[0].toUpperCase() +
                                              role.substring(1)),
                                        ))
                                    .toList(),
                                onChanged: (newRole) {
                                  if (newRole != null &&
                                      newRole != currentRole) {
                                    updateMemberRole(userId, newRole);
                                  }
                                },
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
