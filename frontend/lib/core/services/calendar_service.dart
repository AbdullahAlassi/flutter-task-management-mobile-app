import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/models/calendar_event.dart';
import 'package:frontend/core/services/api_service.dart';

class CalendarService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = '/api/calendar';

  // Get events for a date range
  Future<List<CalendarEvent>> getEvents({
    required String? token,
    required DateTime startDate,
    required DateTime endDate,
    String? type,
    String? projectId,
  }) async {
    print('CalendarService.getEvents called with startDate: '
        '\x1B[32m$startDate\x1B[0m, endDate: \x1B[32m$endDate\x1B[0m, type: $type, projectId: $projectId');
    final queryParams = {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (type != null) 'type': type,
      if (projectId != null) 'projectId': projectId,
    };

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final response = await _apiService.get(
      '$_baseUrl/events',
      queryParams: queryParams,
      headers: headers,
    );

    print(
        'CalendarService.getEvents status: \x1B[33m${response.statusCode}\x1B[0m');
    print('CalendarService.getEvents body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CalendarEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  // Get events for a specific day
  Future<List<CalendarEvent>> getDayEvents(String? token, DateTime date) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = await _apiService.get(
      '$_baseUrl/day/${date.toIso8601String()}',
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CalendarEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load day events');
    }
  }

  // Get recurring events
  Future<List<CalendarEvent>> getRecurringEvents({
    required String? token,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final queryParams = {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = await _apiService.get(
      '$_baseUrl/recurring',
      queryParams: queryParams,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => CalendarEvent.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load recurring events');
    }
  }

  // Create a new event
  Future<CalendarEvent> createEvent(String? token, CalendarEvent event) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = await _apiService.post(
      '$_baseUrl/events',
      body: event.toJson(),
      headers: headers,
    );

    if (response.statusCode == 201) {
      return CalendarEvent.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create event');
    }
  }

  // Update an event
  Future<CalendarEvent> updateEvent(
      String? token, String id, CalendarEvent event) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response = await _apiService.put(
      '$_baseUrl/events/$id',
      body: event.toJson(),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return CalendarEvent.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update event');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String? token, String id) async {
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    final response =
        await _apiService.delete('$_baseUrl/events/$id', headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete event');
    }
  }
}
