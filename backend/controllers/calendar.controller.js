const CalendarEvent = require('../models/calendar.model');
const Task = require('../models/task.model');
const Project = require('../models/project.model');

// Get calendar events for a specific date range
exports.getEvents = async (req, res) => {
  console.log('CalendarController.getEvents: req.user:', req.user);
  try {
    const { startDate, endDate, type, projectId } = req.query;
    const userId = req.user._id;

    const query = {
      userId,
      startDate: { $gte: new Date(startDate) },
      endDate: { $lte: new Date(endDate) }
    };

    if (type) {
      query.type = type;
    }

    if (projectId) {
      query.projectId = projectId;
    }

    const events = await CalendarEvent.find(query)
      .populate('taskId')
      .populate('projectId')
      .sort({ startDate: 1 });

    res.json(events);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Create a new calendar event
exports.createEvent = async (req, res) => {
  try {
    const userId = req.user._id;
    const eventData = { ...req.body, userId };

    // If it's a task-related event, verify the task exists
    if (eventData.taskId) {
      const task = await Task.findOne({ _id: eventData.taskId, userId });
      if (!task) {
        return res.status(404).json({ message: 'Task not found' });
      }
    }

    // If it's a project-related event, verify the project exists
    if (eventData.projectId) {
      const project = await Project.findOne({ _id: eventData.projectId, userId });
      if (!project) {
        return res.status(404).json({ message: 'Project not found' });
      }
    }

    const event = new CalendarEvent(eventData);
    await event.save();

    res.status(201).json(event);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update a calendar event
exports.updateEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const event = await CalendarEvent.findOne({ _id: id, userId });
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    Object.assign(event, req.body);
    await event.save();

    res.json(event);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete a calendar event
exports.deleteEvent = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user._id;

    const event = await CalendarEvent.findOneAndDelete({ _id: id, userId });
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }

    res.json({ message: 'Event deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get events for a specific day
exports.getDayEvents = async (req, res) => {
  try {
    const { date } = req.params;
    const userId = req.user._id;

    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);

    const events = await CalendarEvent.find({
      userId,
      $or: [
        {
          startDate: { $lte: endOfDay },
          endDate: { $gte: startOfDay }
        }
      ]
    })
      .populate('taskId')
      .populate('projectId')
      .sort({ startDate: 1 });

    res.json(events);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get recurring events
exports.getRecurringEvents = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const userId = req.user._id;

    const events = await CalendarEvent.find({
      userId,
      'recurring.isRecurring': true,
      startDate: { $lte: new Date(endDate) },
      $or: [
        { 'recurring.endDate': { $gte: new Date(startDate) } },
        { 'recurring.endDate': null }
      ]
    })
      .populate('taskId')
      .populate('projectId')
      .sort({ startDate: 1 });

    res.json(events);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
}; 