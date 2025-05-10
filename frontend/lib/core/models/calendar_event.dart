import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/models/project.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final bool allDay;
  final String type;
  final String color;
  final String? taskId;
  final String? projectId;
  final String userId;
  final RecurringEvent? recurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Task? task;
  final Project? project;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDate,
    required this.endDate,
    this.allDay = false,
    this.type = 'task',
    this.color = '#3788d8',
    this.taskId,
    this.projectId,
    required this.userId,
    this.recurring,
    required this.createdAt,
    required this.updatedAt,
    this.task,
    this.project,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      allDay: json['allDay'] ?? false,
      type: json['type'] ?? 'task',
      color: json['color'] ?? '#3788d8',
      taskId: json['taskId'],
      projectId: json['projectId'],
      userId: json['userId'],
      recurring: json['recurring'] != null
          ? RecurringEvent.fromJson(json['recurring'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      task: json['taskId'] != null ? Task.fromJson(json['taskId']) : null,
      project: json['projectId'] != null
          ? Project.fromJson(json['projectId'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'allDay': allDay,
      'type': type,
      'color': color,
      'taskId': taskId,
      'projectId': projectId,
      'recurring': recurring?.toJson(),
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? allDay,
    String? type,
    String? color,
    String? taskId,
    String? projectId,
    String? userId,
    RecurringEvent? recurring,
    DateTime? createdAt,
    DateTime? updatedAt,
    Task? task,
    Project? project,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      allDay: allDay ?? this.allDay,
      type: type ?? this.type,
      color: color ?? this.color,
      taskId: taskId ?? this.taskId,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      recurring: recurring ?? this.recurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      task: task ?? this.task,
      project: project ?? this.project,
    );
  }
}

class RecurringEvent {
  final bool isRecurring;
  final String frequency;
  final int interval;
  final DateTime? endDate;
  final List<int>? daysOfWeek;

  RecurringEvent({
    required this.isRecurring,
    this.frequency = 'daily',
    this.interval = 1,
    this.endDate,
    this.daysOfWeek,
  });

  factory RecurringEvent.fromJson(Map<String, dynamic> json) {
    return RecurringEvent(
      isRecurring: json['isRecurring'] ?? false,
      frequency: json['frequency'] ?? 'daily',
      interval: json['interval'] ?? 1,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isRecurring': isRecurring,
      'frequency': frequency,
      'interval': interval,
      'endDate': endDate?.toIso8601String(),
      'daysOfWeek': daysOfWeek,
    };
  }
}
