import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/models/task.dart';
import 'package:frontend/core/utils/api_exception.dart';

class TaskService {
  Future<List<Task>> getTasksByBoard(String token, String boardId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks/board/$boardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug print
      debugPrint('getTasksByBoard response status: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tasksData = responseData['data']['tasks'] as List<dynamic>;

        // Parse each task individually to catch and handle errors
        List<Task> tasks = [];
        for (var taskJson in tasksData) {
          try {
            tasks.add(Task.fromJson(taskJson));
          } catch (e) {
            debugPrint('Error parsing individual task: $e');
            // Continue with next task instead of failing the whole list
          }
        }

        return tasks;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to load tasks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in getTasksByBoard: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<List<Task>> getAllTasks(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      // Debug print to see the response
      debugPrint('getAllTasks response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final tasksData = responseData['data']['tasks'] as List<dynamic>;

        // Parse each task individually to catch and handle errors
        List<Task> tasks = [];
        for (var taskJson in tasksData) {
          try {
            tasks.add(Task.fromJson(taskJson));
          } catch (e) {
            debugPrint('Error parsing individual task: $e');
            // Continue with next task instead of failing the whole list
          }
        }

        return tasks;
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to load tasks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in getAllTasks: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<List<Task>> getTodayTasks(String token) async {
    try {
      // Get all tasks first
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      // Debug print to see the response
      debugPrint('getTodayTasks response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final tasksData = responseData['data']['tasks'] as List<dynamic>;

        // Parse each task individually to catch and handle errors
        List<Task> allTasks = [];
        for (var taskJson in tasksData) {
          try {
            allTasks.add(Task.fromJson(taskJson));
          } catch (e) {
            debugPrint('Error parsing individual task: $e');
            // Continue with next task instead of failing the whole list
          }
        }

        // Filter for tasks with today's deadline
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        return allTasks.where((task) {
          if (task.deadline == null) return false;
          final taskDate = DateTime(
            task.deadline!.year,
            task.deadline!.month,
            task.deadline!.day,
          );
          return taskDate.isAtSameMomentAs(today);
        }).toList();
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to load tasks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in getTodayTasks: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<Task> getTaskById(String token, String taskId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Debug print
      debugPrint('getTaskById response status: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Task.fromJson(responseData['data']['task']);
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to load task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in getTaskById: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<Task> createTask(String token, Map<String, dynamic> taskData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(taskData),
      );

      // Debug print
      debugPrint('createTask response status: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return Task.fromJson(responseData['data']['task']);
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to create task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in createTask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<Task> updateTask(
    String token,
    String taskId,
    Map<String, dynamic> taskData,
  ) async {
    try {
      // Debug log to see what we're sending to the server
      debugPrint('Updating task $taskId with data: $taskData');

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(taskData),
      );

      // Debug log to see the response
      debugPrint('Update task response status: ${response.statusCode}');
      debugPrint('Update task response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Task.fromJson(responseData['data']['task']);
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to update task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in updateTask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<bool> deleteTask(String token, String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(
          message: responseData['message'] ?? 'Failed to delete task',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<Task> moveTask(
    String token,
    String taskId,
    String targetBoardId,
  ) async {
    try {
      // First get the task to get its current board
      final task = await getTaskById(token, taskId);

      // Get the board to get its project ID
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/boards/${task.board}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw ApiException(
          message: 'Failed to get board information',
          statusCode: response.statusCode,
        );
      }

      final boardData = jsonDecode(response.body);
      final projectId = boardData['data']['board']['project'];

      final moveResponse = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks/$taskId/move'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'targetBoard': targetBoardId,
          'projectId': projectId,
        }),
      );

      // Debug print
      debugPrint('moveTask response status: ${moveResponse.statusCode}');

      final responseData = jsonDecode(moveResponse.body);

      if (moveResponse.statusCode == 200) {
        return Task.fromJson(responseData['data']['task']);
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to move task',
          statusCode: moveResponse.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in moveTask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<bool> reorderTasks(
    String token,
    String boardId,
    List<Map<String, dynamic>> taskOrders,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/api/tasks/board/$boardId/reorder'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tasks': taskOrders}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseData = jsonDecode(response.body);
        throw ApiException(
          message: responseData['message'] ?? 'Failed to reorder tasks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}
