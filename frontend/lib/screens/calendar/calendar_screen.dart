import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/auth_provider.dart';
import 'package:frontend/core/services/task_service.dart';
import 'package:frontend/core/services/project_service.dart';
import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/models/project.dart';
import 'package:frontend/screens/tasks/task_detail_screen.dart';
import 'package:frontend/screens/projects/project_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDay = {};
  Map<DateTime, List<Project>> _projectsByDay = {};
  bool _isLoading = true;
  String? _error;

  final TaskService _taskService = TaskService();
  final ProjectService _projectService = ProjectService();

  @override
  void initState() {
    super.initState();
    _loadDataForMonth();
  }

  Future<void> _loadDataForMonth() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      // Fetch all tasks and projects for the month
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      final allTasks = await _taskService.getAllTasks(token!);
      final allProjects = await _projectService.getAllProjects(token);
      final tasks = allTasks.where((task) {
        if (task.deadline == null) return false;
        return !task.deadline!.isBefore(firstDay) &&
            !task.deadline!.isAfter(lastDay);
      }).toList();
      final projects = allProjects.where((project) {
        if (project.deadline == null) return false;
        return !project.deadline!.isBefore(firstDay) &&
            !project.deadline!.isAfter(lastDay);
      }).toList();
      // Group by day
      final Map<DateTime, List<Task>> tasksByDay = {};
      for (final task in tasks) {
        if (task.deadline == null) continue;
        final day = DateTime(
            task.deadline!.year, task.deadline!.month, task.deadline!.day);
        tasksByDay.putIfAbsent(day, () => []).add(task);
      }
      final Map<DateTime, List<Project>> projectsByDay = {};
      for (final project in projects) {
        if (project.deadline == null) continue;
        final day = DateTime(project.deadline!.year, project.deadline!.month,
            project.deadline!.day);
        projectsByDay.putIfAbsent(day, () => []).add(project);
      }
      setState(() {
        _tasksByDay = tasksByDay;
        _projectsByDay = projectsByDay;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Task> _getTasksForDay(DateTime day) =>
      _tasksByDay[DateTime(day.year, day.month, day.day)] ?? [];
  List<Project> _getProjectsForDay(DateTime day) =>
      _projectsByDay[DateTime(day.year, day.month, day.day)] ?? [];

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadDataForMonth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      onDaySelected: _onDaySelected,
                      onFormatChanged: _onFormatChanged,
                      onPageChanged: _onPageChanged,
                      eventLoader: (day) => <Object>[
                        ..._getTasksForDay(day),
                        ..._getProjectsForDay(day)
                      ],
                      calendarStyle: CalendarStyle(
                        markersMaxCount: 3,
                        markerDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: _selectedDay == null
                          ? const Center(
                              child: Text(
                                  'Select a day to view tasks and projects'))
                          : _buildDayList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDayList() {
    final tasks = _getTasksForDay(_selectedDay!);
    final projects = _getProjectsForDay(_selectedDay!);
    if (tasks.isEmpty && projects.isEmpty) {
      return const Center(child: Text('No tasks or projects for this day'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (tasks.isNotEmpty) ...[
          const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
          ...tasks.map((task) => ListTile(
                leading: const Icon(Icons.task),
                title: Text(task.title),
                subtitle:
                    Text(task.deadline != null ? task.deadline.toString() : ''),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  );
                },
              )),
          const SizedBox(height: 16),
        ],
        if (projects.isNotEmpty) ...[
          const Text('Projects', style: TextStyle(fontWeight: FontWeight.bold)),
          ...projects.map((project) => ListTile(
                leading: const Icon(Icons.folder),
                title: Text(project.title),
                subtitle: Text(project.deadline != null
                    ? project.deadline.toString()
                    : ''),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectDetailScreen(project: project),
                    ),
                  );
                },
              )),
        ],
      ],
    );
  }
}
