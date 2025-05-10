import 'package:flutter/material.dart';
import 'package:frontend/core/models/calendar_event.dart';
import 'package:frontend/core/services/calendar_service.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:frontend/widgets/custom_text_field.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/auth_provider.dart';

class CreateEventScreen extends StatefulWidget {
  final DateTime initialDate;

  const CreateEventScreen({
    super.key,
    required this.initialDate,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _calendarService = CalendarService();
  bool _isLoading = false;
  String? _error;

  // Form fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  bool _isAllDay = false;
  String _type = 'task';
  String _color = '#3788d8';
  bool _isRecurring = false;
  String _frequency = 'daily';
  int _interval = 1;
  DateTime? _recurringEndDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate;
    _endDate = widget.initialDate.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
          _error = null;
        });

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        final event = CalendarEvent(
          id: '', // Will be set by the server
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          allDay: _isAllDay,
          type: _type,
          color: _color,
          userId: '', // Will be set by the server
          recurring: _isRecurring
              ? RecurringEvent(
                  isRecurring: true,
                  frequency: _frequency,
                  interval: _interval,
                  endDate: _recurringEndDate,
                )
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _calendarService.createEvent(token, event);

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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _startDate.hour,
            _startDate.minute,
          );
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _endDate.hour,
            _endDate.minute,
          );
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        isStartTime ? _startDate : _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startDate = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endDate = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Event'),
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
                        onPressed: _createEvent,
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Title
                      CustomTextField(
                        controller: _titleController,
                        labelText: 'Title',
                        hintText: 'Enter event title',
                        prefixIcon: Icons.title,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      CustomTextField(
                        controller: _descriptionController,
                        labelText: 'Description',
                        hintText: 'Enter event description',
                        prefixIcon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // All Day Switch
                      SwitchListTile(
                        title: const Text('All Day'),
                        value: _isAllDay,
                        onChanged: (value) {
                          setState(() {
                            _isAllDay = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date and Time Selection
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Start'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _selectDate(
                                          context,
                                          true,
                                        ),
                                        child: Text(
                                          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                                        ),
                                      ),
                                    ),
                                    if (!_isAllDay) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _selectTime(
                                            context,
                                            true,
                                          ),
                                          child: Text(
                                            '${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('End'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _selectDate(
                                          context,
                                          false,
                                        ),
                                        child: Text(
                                          '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}',
                                        ),
                                      ),
                                    ),
                                    if (!_isAllDay) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _selectTime(
                                            context,
                                            false,
                                          ),
                                          child: Text(
                                            '${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Event Type
                      const Text(
                        'Event Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _type,
                        items: const [
                          DropdownMenuItem(
                            value: 'task',
                            child: Text('Task'),
                          ),
                          DropdownMenuItem(
                            value: 'milestone',
                            child: Text('Milestone'),
                          ),
                          DropdownMenuItem(
                            value: 'reminder',
                            child: Text('Reminder'),
                          ),
                          DropdownMenuItem(
                            value: 'holiday',
                            child: Text('Holiday'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _type = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Color Selection
                      const Text(
                        'Color',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          '#3788d8',
                          '#e74c3c',
                          '#2ecc71',
                          '#f1c40f',
                          '#9b59b6',
                          '#1abc9c',
                        ].map((color) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _color = color;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(color.replaceAll('#', '0xFF')),
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _color == color
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Recurring Event
                      SwitchListTile(
                        title: const Text('Recurring Event'),
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _frequency,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'daily',
                                    child: Text('Daily'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'weekly',
                                    child: Text('Weekly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'monthly',
                                    child: Text('Monthly'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'yearly',
                                    child: Text('Yearly'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _frequency = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: '1',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Interval',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _interval = int.tryParse(value) ?? 1;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _recurringEndDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setState(() {
                                _recurringEndDate = picked;
                              });
                            }
                          },
                          child: Text(
                            _recurringEndDate != null
                                ? 'Ends on: ${_recurringEndDate.toString().split(' ')[0]}'
                                : 'Set End Date',
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Create Button
                      CustomButton(
                        text: 'Create Event',
                        onPressed: _createEvent,
                      ),
                    ],
                  ),
                ),
    );
  }
}
