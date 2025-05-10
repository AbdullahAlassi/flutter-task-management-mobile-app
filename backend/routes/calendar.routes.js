const express = require('express');
const router = express.Router();
const calendarController = require('../controllers/calendar.controller');
const { protect } = require('../middleware/auth.middleware');

// Apply auth middleware to all routes
router.use(protect);

// Get calendar events for a date range
router.get('/events', calendarController.getEvents);

// Get events for a specific day
router.get('/day/:date', calendarController.getDayEvents);

// Get recurring events
router.get('/recurring', calendarController.getRecurringEvents);

// Create a new calendar event
router.post('/events', calendarController.createEvent);

// Update a calendar event
router.put('/events/:id', calendarController.updateEvent);

// Delete a calendar event
router.delete('/events/:id', calendarController.deleteEvent);

module.exports = router; 