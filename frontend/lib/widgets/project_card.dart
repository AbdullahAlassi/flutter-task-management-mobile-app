import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;

  const ProjectCard({super.key, required this.project, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Parse the project color
    Color projectColor;
    try {
      projectColor = Color(int.parse(project.color.replaceAll('#', '0xFF')));
    } catch (e) {
      projectColor = Colors.blue; // Default color if parsing fails
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Banner with color
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: projectColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(project.status),
                    ],
                  ),
                  if (project.description != null &&
                      project.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        project.description!,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Team',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildTeamMembers(project.members
                                .map((m) => User(
                                      id: m.id,
                                      name: m.name,
                                      email: m.email,
                                      role: m.role,
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ))
                                .toList()),
                          ],
                        ),
                      ),
                      if (project.deadline != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Deadline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(project.deadline!),
                              style: TextStyle(
                                color: _isDeadlineNear(project.deadline!)
                                    ? Colors.red
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (project.progress != null) ...[
                    const SizedBox(height: 16),
                    _buildProgressBar(project.progress!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status) {
      case 'Planning':
        chipColor = Colors.blue;
        break;
      case 'In Progress':
        chipColor = Colors.orange;
        break;
      case 'On Hold':
        chipColor = Colors.grey;
        break;
      case 'Completed':
        chipColor = Colors.green;
        break;
      case 'Cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTeamMembers(List<User> members) {
    if (members.isEmpty) {
      return const Text(
        'No team members',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: members.length > 3 ? 4 : members.length,
        itemBuilder: (context, index) {
          if (index == 3 && members.length > 3) {
            return Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '+${members.length - 3}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          return _buildMemberAvatar(members[index]);
        },
      ),
    );
  }

  Widget _buildMemberAvatar(User member) {
    // Check if profile picture is valid
    bool hasValidProfilePic = member.profilePicture != null &&
        member.profilePicture!.isNotEmpty &&
        member.profilePicture!.startsWith('http');

    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 4),
      child: Tooltip(
        message: member.name,
        child: CircleAvatar(
          backgroundColor: Colors.grey[300],
          backgroundImage:
              hasValidProfilePic ? NetworkImage(member.profilePicture!) : null,
          child: !hasValidProfilePic
              ? Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildProgressBar(ProjectProgress progress) {
    final percentage = progress.progressPercentage.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(percentage),
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          '${progress.completedTasks}/${progress.totalTasks} tasks completed',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  bool _isDeadlineNear(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    return difference <= 3 && difference >= 0;
  }
}
