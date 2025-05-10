import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/user_service.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/widgets/user_avatar.dart';
import 'package:provider/provider.dart';

class MemberSelection extends StatefulWidget {
  final List<User> selectedMembers;
  final Function(List<User>) onMembersChanged;
  final bool includeCurrentUser;
  final List<User>? availableMembers;

  const MemberSelection({
    super.key,
    required this.selectedMembers,
    required this.onMembersChanged,
    this.includeCurrentUser = true,
    this.availableMembers,
  });

  @override
  State<MemberSelection> createState() => _MemberSelectionState();
}

class _MemberSelectionState extends State<MemberSelection> {
  final UserService _userService = UserService();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current user if needed
    if (widget.includeCurrentUser) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null &&
          !widget.selectedMembers.any((m) => m.id == authProvider.user!.id)) {
        final updatedMembers = List<User>.from(widget.selectedMembers)
          ..add(authProvider.user!);
        widget.onMembersChanged(updatedMembers);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String email) async {
    if (email.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _isSearching = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.token == null) {
        throw Exception('Authentication token is missing');
      }

      List<User> results;

      // If we have available members, filter from them
      if (widget.availableMembers != null) {
        results = widget.availableMembers!
            .where((user) =>
                user.email.toLowerCase().contains(email.toLowerCase()) ||
                user.name.toLowerCase().contains(email.toLowerCase()))
            .toList();
      } else {
        // Otherwise, search all users (existing behavior)
        results = await _userService.searchUsersByEmail(
          authProvider.token!,
          email,
        );
      }

      // Filter out users that are already selected
      final filteredResults = results
          .where((user) =>
              !widget.selectedMembers.any((member) => member.id == user.id))
          .toList();

      setState(() {
        _searchResults = filteredResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addMember(User user) {
    if (!widget.selectedMembers.any((member) => member.id == user.id)) {
      final updatedMembers = List<User>.from(widget.selectedMembers)..add(user);
      widget.onMembersChanged(updatedMembers);

      // Clear search results after adding
      setState(() {
        _searchResults = [];
        _searchController.clear();
        _searchQuery = '';
        _isSearching = false;
      });
    }
  }

  void _removeMember(User user) {
    final updatedMembers = List<User>.from(widget.selectedMembers)
      ..removeWhere((member) => member.id == user.id);
    widget.onMembersChanged(updatedMembers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Members', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),

        // Selected members
        if (widget.selectedMembers.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedMembers
                .map((user) => _buildMemberChip(user))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Search and add members
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search users by email...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _searchUsers(value);
                },
              ),
            ),
          ],
        ),

        // Search results
        if (_isSearching) ...[
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Text(
                      'Error: $_error',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    )
                  : _searchResults.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('No users found with that email'),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final user = _searchResults[index];
                              return ListTile(
                                leading: UserAvatar(user: user),
                                title: Text(user.name),
                                subtitle: Text(user.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: AppColors.primary,
                                  onPressed: () => _addMember(user),
                                ),
                                onTap: () => _addMember(user),
                              );
                            },
                          ),
                        ),
        ],

        if (_error != null && !_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildMemberChip(User user) {
    return Chip(
      avatar: UserAvatar(user: user, size: 24),
      label: Text(user.name),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: () => _removeMember(user),
    );
  }
}
