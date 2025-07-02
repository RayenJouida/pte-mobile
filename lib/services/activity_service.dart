import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/activity.dart';
import 'auth_service.dart';

class ActivityService {
  final AuthService _authService = AuthService();

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    print('Retrieved auth token: ${token != null ? 'Token exists' : 'No token'}');
    return token;
  }

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    print('Retrieved userId: $userId');
    return userId;
  }

  Future<List<Activity>> fetchActivities(String userId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    if (userId.isEmpty) throw Exception('User ID is required');

    print('Fetching activities for user: $userId');
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/activities/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch activities response status: ${response.statusCode}');
      print('Fetch activities response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final activities = data.map((json) => Activity.fromJson(json)).toList();
        print('Parsed ${activities.length} activities');
        return activities;
      } else {
        throw Exception('Failed to fetch activities: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching activities: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> fetchUnreadCounts() async {
    final userId = await _getUserId();
    final token = await _getToken();
    if (userId == null) throw Exception('User not logged in');
    if (token == null) throw Exception('Not authenticated');

    print('Fetching unread counts for user: $userId');
    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/activities/unread-count/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch unread counts response status: ${response.statusCode}');
      print('Fetch unread counts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'unreadMessages': data['unreadMessages'] ?? 0,
          'unreadActivities': data['unreadActivities'] ?? 0,
        };
      } else {
        throw Exception('Failed to fetch unread counts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching unread counts: $e');
      rethrow;
    }
  }

  Future<void> markActivitiesAsRead() async {
    final userId = await _getUserId();
    final token = await _getToken();
    if (userId == null) throw Exception('User not logged in');
    if (token == null) throw Exception('Not authenticated');

    print('Marking activities as read for user: $userId');
    try {
      final response = await http.patch(
        Uri.parse('${Env.apiUrl}/activities/mark-read/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Mark activities response status: ${response.statusCode}');
      print('Mark activities response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to mark activities as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error marking activities as read: $e');
      rethrow;
    }
  }

  Future<void> markActivityAsRead(String activityId) async {
    final token = await _getToken();
    if (token == null) {
      print('Error: No auth token found in SharedPreferences');
      throw Exception('Not authenticated');
    }

    print('Attempting to mark activity as read: $activityId');
    try {
      final response = await http.patch(
        Uri.parse('${Env.apiUrl}/activities/$activityId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Mark activity response status: ${response.statusCode}');
      print('Mark activity response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Activity $activityId marked as read successfully');
      } else {
        throw Exception('Failed to mark activity as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error marking activity as read: $e');
      throw Exception('Failed to mark activity: $e');
    }
  }
}