import 'package:flutter/material.dart';
import 'package:frontend/core/models/project.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'dart:math';

class RecentProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const RecentProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Calculate project progress
    final progress = _calculateProgress();

    // Calculate days left
    final daysLeft = project.deadline?.difference(DateTime.now()).inDays;

    // Parse the project color
    Color projectColor;
    try {
      projectColor = Color(int.parse(project.color.replaceAll('#', '0xFF')));
    } catch (e) {
      projectColor = AppColors.primary;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solid Color Header with Team Members
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: projectColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project Logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getRandomIcon(),
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),

                    // Team Members
                    Row(
                      children: [
                        // Display up to 3 team members
                        ...project.members.take(3).map(
                              (member) => Align(
                                widthFactor: 0.7,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  backgroundImage: member.profilePicture !=
                                              null &&
                                          member.profilePicture!.isNotEmpty &&
                                          member.profilePicture!
                                              .startsWith('http')
                                      ? NetworkImage(member.profilePicture!)
                                      : null,
                                  child: member.profilePicture == null ||
                                          member.profilePicture!.isEmpty ||
                                          !member.profilePicture!
                                              .startsWith('http')
                                      ? Text(
                                          member.name.isNotEmpty
                                              ? member.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),

                        // Show +X for additional members
                        if (project.members.length > 3)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '+${project.members.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Project Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {
                          // Show options
                        },
                      ),
                    ],
                  ),
                  Text(
                    '${project.description ?? "No description"} - ${project.deadline != null ? _formatDate(project.deadline!) : "No deadline"}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${progress.completedTasks} / ${progress.totalTasks}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        daysLeft != null
                            ? daysLeft > 0
                                ? '$daysLeft Days Left'
                                : daysLeft == 0
                                    ? 'Due Today'
                                    : '${daysLeft.abs()} Days Overdue'
                            : 'No deadline',
                        style: TextStyle(
                          color: daysLeft != null && daysLeft < 0
                              ? Colors.red
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.progressPercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to calculate progress
  _ProjectProgress _calculateProgress() {
    // Check if project has progress information from the backend
    if (project.toJson().containsKey('progress')) {
      final progressData = project.toJson()['progress'];
      return _ProjectProgress(
        totalTasks: progressData['totalTasks'] ?? 0,
        completedTasks: progressData['completedTasks'] ?? 0,
        progressPercentage: progressData['progressPercentage'] ?? 0.0,
      );
    }

    // Fallback to default values if progress information is not available
    return _ProjectProgress(
      totalTasks: 0,
      completedTasks: 0,
      progressPercentage: 0.0,
    );
  }

  // Helper method to format date
  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Helper method to get a random icon for the project
  IconData _getRandomIcon() {
    final icons = [
      Icons.work,
      Icons.code,
      Icons.design_services,
      Icons.article,
      Icons.analytics,
      Icons.architecture,
      Icons.brush,
      Icons.business_center,
      Icons.campaign,
      Icons.category,
    ];

    // Use the project id to generate a consistent icon for the same project
    final random = Random(project.id.hashCode);
    return icons[random.nextInt(icons.length)];
  }
}

class _ProjectProgress {
  final int totalTasks;
  final int completedTasks;
  final double progressPercentage;

  _ProjectProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPercentage,
  });
}
