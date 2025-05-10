import 'package:flutter/material.dart';
import 'package:frontend/core/models/calendar_event.dart';
import 'package:frontend/core/services/calendar_service.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/screens/projects/project_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/auth_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final CalendarEvent event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final CalendarService _calendarService = CalendarService();
  bool _isLoading = false;
  String? _error;

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
          _error = null;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;
        await _calendarService.deleteEvent(token, widget.event.id);

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Implement edit functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteEvent,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _deleteEvent,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Type and Color
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  widget.event.color.replaceAll('#', '0xFF'),
                                ),
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.event.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        widget.event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      if (widget.event.description != null) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.event.description!),
                        const SizedBox(height: 24),
                      ],

                      // Date and Time
                      const Text(
                        'Date & Time',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.event.allDay
                            ? 'All day event'
                            : '${widget.event.startDate.toString().split('.')[0]} - ${widget.event.endDate.toString().split('.')[0]}',
                      ),
                      const SizedBox(height: 24),

                      // Related Task or Project
                      if (widget.event.task != null) ...[
                        const Text(
                          'Related Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.task),
                          title: Text(widget.event.task!.title),
                          onTap: () {
                            // TODO: Navigate to task details
                          },
                        ),
                      ] else if (widget.event.project != null) ...[
                        const Text(
                          'Related Project',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(widget.event.project!.title),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProjectDetailScreen(
                                  project: widget.event.project!,
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      // Recurring Information
                      if (widget.event.recurring?.isRecurring ?? false) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Recurring',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.event.recurring!.frequency} (every ${widget.event.recurring!.interval} ${widget.event.recurring!.frequency})',
                        ),
                        if (widget.event.recurring!.endDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Ends on: ${widget.event.recurring!.endDate.toString().split(' ')[0]}',
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
    );
  }
}
