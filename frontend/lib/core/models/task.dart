import 'package:flutter/material.dart';
import 'package:frontend/core/models/user.dart';
import 'package:frontend/core/models/subtask.dart';

class Attachment {
  final String name;
  final String type;
  final String url;
  final DateTime uploadedAt;

  Attachment({
    required this.name,
    required this.type,
    required this.url,
    required this.uploadedAt,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'url': url,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final String board;
  final List<User> assignees;
  final DateTime? deadline;
  final String status;
  final String priority;
  final int order;
  final List<Attachment> attachments;
  final List<Subtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String color;
  final User leader;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.board,
    required this.assignees,
    this.deadline,
    required this.status,
    required this.priority,
    required this.order,
    this.attachments = const [],
    this.subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
    this.color = '#2196F3',
    required this.leader,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    // Handle board field which might be an object or a string
    String boardId;
    if (json['board'] is Map) {
      boardId = json['board']['_id'] ?? '';
    } else {
      boardId = json['board']?.toString() ?? '';
    }

    // Handle assignees which might be a list of objects or IDs
    List<User> assigneesList = [];
    if (json['assignees'] != null) {
      try {
        assigneesList = (json['assignees'] as List<dynamic>).map((assignee) {
          if (assignee is Map<String, dynamic>) {
            return User.fromJson(assignee);
          } else {
            // If it's just an ID, create a minimal user
            return User(
              id: assignee.toString(),
              name: 'Unknown',
              email: '',
              role: 'Team Member',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
        }).toList();
      } catch (e) {
        debugPrint('Error parsing assignees: $e');
      }
    }

    // Handle dates safely
    DateTime? deadlineDate;
    if (json['deadline'] != null) {
      try {
        deadlineDate = DateTime.parse(json['deadline']);
      } catch (e) {
        debugPrint('Error parsing deadline: $e');
      }
    }

    DateTime createdAtDate;
    try {
      createdAtDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now();
    } catch (e) {
      debugPrint('Error parsing createdAt: $e');
      createdAtDate = DateTime.now();
    }

    DateTime updatedAtDate;
    try {
      updatedAtDate = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now();
    } catch (e) {
      debugPrint('Error parsing updatedAt: $e');
      updatedAtDate = DateTime.now();
    }

    // Handle attachments safely
    List<Attachment> attachmentsList = [];
    if (json['attachments'] != null) {
      try {
        attachmentsList = (json['attachments'] as List<dynamic>)
            .map((attachment) => Attachment.fromJson(attachment))
            .toList();
      } catch (e) {
        debugPrint('Error parsing attachments: $e');
      }
    }

    // Handle subtasks safely
    List<Subtask> subtasksList = [];
    if (json['subtasks'] != null) {
      try {
        subtasksList = (json['subtasks'] as List<dynamic>)
            .map((subtask) => Subtask.fromJson(subtask))
            .toList();
      } catch (e) {
        debugPrint('Error parsing subtasks: $e');
      }
    }

    // Handle color
    String colorValue = json['color']?.toString() ?? '#2196F3';
    if (!colorValue.startsWith('#')) {
      colorValue = '#$colorValue';
    }

    // Handle leader
    debugPrint('Parsing leader from JSON: [33m${json['leader']}[0m');
    User leaderUser;
    try {
      leaderUser = User.fromJson(json['leader'] ?? {});
    } catch (e) {
      leaderUser = User(
        id: '',
        name: 'Unknown',
        email: '',
        role: 'Team Member',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return Task(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      board: boardId,
      assignees: assigneesList,
      deadline: deadlineDate,
      status: json['status'] ?? 'To Do',
      priority: json['priority'] ?? 'Medium',
      order: json['order'] ?? 0,
      attachments: attachmentsList,
      subtasks: subtasksList,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
      color: colorValue,
      leader: leaderUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'board': board,
      'assignees': assignees.map((assignee) => assignee.id).toList(),
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'priority': priority,
      'attachments':
          attachments.map((attachment) => attachment.toJson()).toList(),
      'subtasks': subtasks.map((subtask) => subtask.toJson()).toList(),
      'color': color,
      'leader': leader.id,
    };
  }

  Task copyWith({
    String? title,
    String? description,
    String? board,
    List<User>? assignees,
    DateTime? deadline,
    String? status,
    String? priority,
    int? order,
    List<Attachment>? attachments,
    List<Subtask>? subtasks,
    String? color,
    User? leader,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      board: board ?? this.board,
      assignees: assignees ?? this.assignees,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      order: order ?? this.order,
      attachments: attachments ?? this.attachments,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
      updatedAt: updatedAt,
      color: color ?? this.color,
      leader: leader ?? this.leader,
    );
  }
}
