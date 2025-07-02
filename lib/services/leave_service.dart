import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveService {
  // Helper method to get the auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Helper method to create headers with auth token
  Future<Map<String, String>> _getHeaders({bool isJson = false}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No auth token found. Please log in again.');
    }
    final headers = {
      'Authorization': 'Bearer $token',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<Leave> createLeaveRequest({
    required String fullName,
    required String email,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    String? note,
    required String applicantId,
    required String supervisorId,
    File? certifFile, // For certificate file
  }) async {
    try {
      final url = Uri.parse('${Env.apiUrl}/leave/createLeaveRequest');

      if (certifFile != null) {
        final headers = await _getHeaders();
        var request = http.MultipartRequest('POST', url);
        request.headers.addAll(headers);
        request.fields.addAll({
          'fullName': fullName,
          'email': email,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'type': type,
          if (note != null) 'note': note,
          'applicant': applicantId,
          'supervisor': supervisorId,
        });

        // Determine the MIME type based on file extension
        String mimeType = 'application/octet-stream';
        if (certifFile.path.endsWith('.pdf')) {
          mimeType = 'application/pdf';
        } else if (certifFile.path.endsWith('.doc') || certifFile.path.endsWith('.docx')) {
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        }

        request.files.add(await http.MultipartFile.fromPath(
          'certif',
          certifFile.path,
          contentType: MediaType.parse(mimeType),
        ));

        print('Sending leave request with file to: $url');
        print('Request Headers: $headers');
        print('Request Fields: ${request.fields}');

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        print('CreateLeaveRequest Status: ${response.statusCode}');
        print('CreateLeaveRequest Body: $responseBody');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(responseBody);
          print('Successful response from createLeaveRequest: $jsonResponse'); 
          return Leave.fromJson(jsonResponse);
        } else {
          throw Exception('Failed to create leave request: $responseBody');
        }
      } else {
        final headers = await _getHeaders(isJson: true); // Add Content-Type: application/json
        final body = json.encode({
          'fullName': fullName,
          'email': email,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'type': type,
          if (note != null) 'note': note,
          'applicant': applicantId,
          'supervisor': supervisorId,
        });

        print('Sending leave request to: $url');
        print('Request Headers: $headers');
        print('Request Body: $body');

        final response = await http.post(url, headers: headers, body: body);

        print('CreateLeaveRequest Status: ${response.statusCode}');
        print('CreateLeaveRequest Body: ${response.body}');

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          return Leave.fromJson(jsonResponse);
        } else {
          throw Exception('Failed to create leave request: ${response.body}');
        }
      }
    } catch (e) {
      print('Error creating leave request: $e');
      rethrow;
    }
  }

  // Fetch all leaves (for admins/assistants)
  Future<List<Leave>> fetchAllLeaves() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/leave/getAllLeave'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Leave.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch leaves: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching leaves: $e');
      rethrow;
    }
  }

  // Fetch leaves for a specific user
  Future<List<Leave>> fetchUserLeaves(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/leave/getUserLeave/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Leave.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch user leaves: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching user leaves: $e');
      rethrow;
    }
  }

  // Fetch leaves by applicant ID (same as getUserLeave but named differently in backend)
  Future<List<Leave>> fetchLeavesByApplicantId(String applicantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/leave/getLeaveById/$applicantId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Leave.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch leaves by applicant ID: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching leaves by applicant ID: $e');
      rethrow;
    }
  }

  // Fetch worker requests (for supervisors)
  Future<List<Leave>> fetchWorkerRequests(String workerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/leave/getWorkerRequests/$workerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Leave.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch worker requests: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching worker requests: $e');
      rethrow;
    }
  }

  // Manager accept leave request
  Future<void> managerAccept(String leaveId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/leave/managerAccept/$leaveId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to accept leave request (manager): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error accepting leave request (manager): $e');
      rethrow;
    }
  }

  // Manager decline leave request
  Future<void> managerDecline(String leaveId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/leave/managerDecline/$leaveId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to decline leave request (manager): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error declining leave request (manager): $e');
      rethrow;
    }
  }

  // Worker (supervisor) accept leave request
  Future<void> workerAccept(String leaveId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/leave/workerAccept/$leaveId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to accept leave request (worker): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error accepting leave request (worker): $e');
      rethrow;
    }
  }

  // Worker (supervisor) decline leave request
  Future<void> workerDecline(String leaveId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/leave/workerDecline/$leaveId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to decline leave request (worker): ${response.body}');
      }
    } catch (e) {
      debugPrint('Error declining leave request (worker): $e');
      rethrow;
    }
  }

  // Delete a leave request
  Future<void> deleteLeave(String leaveId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${Env.apiUrl}/leave/deleteLeave/$leaveId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete leave request: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error deleting leave request: $e');
      rethrow;
    }
  }
}