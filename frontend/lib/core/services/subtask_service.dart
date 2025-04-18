import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:frontend/core/constants/api_constants.dart';
import 'package:frontend/core/utils/api_exception.dart';

class SubtaskService {
  Future<Map<String, dynamic>> createSubtask(
    String token,
    String taskId,
    Map<String, dynamic> subtaskData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/subtasks/task/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(subtaskData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Handle both response structures
        if (responseData['data'] != null &&
            responseData['data']['subtask'] != null) {
          return responseData['data']['subtask'];
        } else {
          return responseData;
        }
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to create subtask',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in createSubtask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getSubtasksByTask(
    String token,
    String taskId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/subtasks/task/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null &&
            responseData['data']['subtasks'] != null) {
          return List<Map<String, dynamic>>.from(
            responseData['data']['subtasks'],
          );
        } else {
          return List<Map<String, dynamic>>.from(
            responseData['subtasks'] ?? [],
          );
        }
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to load subtasks',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in getSubtasksByTask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateSubtask(
    String token,
    String subtaskId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/api/subtasks/$subtaskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData['data']['subtask'];
      } else {
        throw ApiException(
          message: responseData['message'] ?? 'Failed to update subtask',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in updateSubtask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }

  Future<bool> deleteSubtask(String token, String subtaskId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/api/subtasks/$subtaskId'),
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
          message: responseData['message'] ?? 'Failed to delete subtask',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Error in deleteSubtask: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(message: e.toString());
    }
  }
}
