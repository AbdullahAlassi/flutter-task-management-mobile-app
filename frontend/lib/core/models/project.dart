import 'package:frontend/core/models/user.dart';

class Project {
  final String id;
  final String title;
  final String description;
  final DateTime? deadline;
  final String status;
  final String manager;
  final List<User> members;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectProgress? progress;

  Project({
    required this.id,
    required this.title,
    required this.description,
    this.deadline,
    required this.status,
    required this.manager,
    required this.members,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.progress,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    // Add debug print to see what's coming from the API
    // print('Project.fromJson: $json');

    // Handle dates safely
    DateTime? deadlineDate;
    if (json['deadline'] != null) {
      try {
        deadlineDate = DateTime.parse(json['deadline']);
      } catch (e) {
        // print('Error parsing deadline: $e');
      }
    }

    DateTime createdAtDate;
    try {
      createdAtDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now();
    } catch (e) {
      // print('Error parsing createdAt: $e');
      createdAtDate = DateTime.now();
    }

    DateTime updatedAtDate;
    try {
      updatedAtDate = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now();
    } catch (e) {
      // print('Error parsing updatedAt: $e');
      updatedAtDate = DateTime.now();
    }

    // Handle manager which might be null or invalid
    User managerUser;
    try {
      managerUser = User.fromJson(json['manager'] ?? {});
    } catch (e) {
      // print('Error parsing manager: $e');
      managerUser = User(
        id: '',
        name: 'Unknown Manager',
        email: '',
        role: 'Project Manager',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Handle members which might be null or invalid
    List<User> membersList = [];
    if (json['members'] != null) {
      try {
        membersList = (json['members'] as List<dynamic>? ?? []).map((member) {
          final user = member['userId'];
          if (user != null && user is Map<String, dynamic>) {
            return User(
              id: user['_id'] ?? '',
              name: user['name'] ?? '',
              email: user['email'] ?? '',
              role: member['role'] ?? '',
              profilePicture: user['profilePicture'] ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else if (user != null && user is String) {
            return User(
              id: user,
              name: '',
              email: '',
              role: member['role'] ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else {
            return User(
              id: member['userId'] ?? '',
              name: '',
              email: '',
              role: member['role'] ?? '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }).toList();
      } catch (e) {
        print('Error parsing members: $e');
        print('Member data that caused error: $json');
      }
    }

    // Handle progress which might be null or invalid
    ProjectProgress? progressData;
    if (json['progress'] != null) {
      try {
        progressData = ProjectProgress.fromJson(json['progress']);
      } catch (e) {
        // print('Error parsing progress: $e');
      }
    }

    // Handle color with proper validation
    String projectColor;
    try {
      projectColor = json['color']?.toString() ?? '#2196F3';
      // Ensure the color is a valid hex color
      if (!projectColor.startsWith('#')) {
        projectColor = '#$projectColor';
      }
      // Validate hex color format
      if (!RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$')
          .hasMatch(projectColor)) {
        projectColor = '#2196F3'; // Default to blue if invalid
      }
    } catch (e) {
      projectColor = '#2196F3'; // Default to blue if any error
    }

    return Project(
      id: json['_id'] ??
          json['id'] ??
          '', // Handle both _id and id, provide default
      title: json['title'] ?? '', // Provide default empty string
      description: json['description'] ?? '', // Already nullable
      deadline: deadlineDate,
      status: json['status'] ?? 'Planning', // Provide default status
      manager: managerUser.id,
      members: membersList,
      color: projectColor,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
      progress: progressData,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      '_id': id,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'manager': manager,
      'members': members.map((u) => u.toJson()).toList(),
      'color': color,
    };

    if (progress != null) {
      data['progress'] = progress!.toJson();
    }

    return data;
  }

  Project copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    String? status,
    String? manager,
    List<User>? members,
    String? color,
    ProjectProgress? progress,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      manager: manager ?? this.manager,
      members: members ?? this.members,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      progress: progress ?? this.progress,
    );
  }
}

class ProjectProgress {
  final int totalTasks;
  final int completedTasks;
  final double progressPercentage;

  ProjectProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPercentage,
  });

  factory ProjectProgress.fromJson(Map<String, dynamic> json) {
    // Debug print to see the progress data
    // print('ProjectProgress.fromJson: $json');

    // Handle the case where progressPercentage might be an int
    double parseProgressPercentage(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return ProjectProgress(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      progressPercentage: parseProgressPercentage(json['progressPercentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'progressPercentage': progressPercentage,
    };
  }
}
