import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import 'package:path/path.dart';
import '../models/user_event.dart';
import '../models/user.dart';

class UserService {
  // Fetch all active users (except admins)
  Future<List> fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/getall'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List> fetchTechEventsById(String technicianId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/tech-events/$technicianId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load technician events');
    }
  }

  Future<Map<String, dynamic>> fetchEventById(String eventId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/event/$eventId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load event details');
    }
  }

  Future<List> fetchEventsByDate(Map<String, dynamic> filters) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.post(
      Uri.parse('${Env.apiUrl}/users/events-by-date'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(filters),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load events by date');
    }
  }

  Future<Map<String, dynamic>> fetchUserByEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.post(
      Uri.parse('${Env.apiUrl}/users/get-by-email'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user by email');
    }
  }

Future<bool> switchUserToExternal(String userId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  debugPrint('UserService.switchUserToExternal - userId: $userId');
  debugPrint('UserService.switchUserToExternal - Token: $token');

  if (token == null) {
    debugPrint('UserService.switchUserToExternal - Error: Token is not available');
    throw Exception('Token is not available');
  }

  final url = Uri.parse('${Env.apiUrl}/users/switchToExternal/$userId');
  debugPrint('UserService.switchUserToExternal - Request URL: $url');

  try {
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('UserService.switchUserToExternal - Response Status: ${response.statusCode}');
    debugPrint('UserService.switchUserToExternal - Response Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('UserService.switchUserToExternal - Success: User switched to external');
      return true;
    } else {
      // Try to parse the response body for a detailed error message
      try {
        final responseBody = json.decode(response.body);
        final errorMessage = responseBody['error'] ?? 'No error message provided';
        debugPrint('UserService.switchUserToExternal - Error: Failed with status ${response.statusCode} - $errorMessage');
        throw Exception('Failed to switch user to external: $errorMessage');
      } catch (e) {
        debugPrint('UserService.switchUserToExternal - Error parsing response body: $e');
        throw Exception('Failed to switch user to external: Status ${response.statusCode} - ${response.body}');
      }
    }
  } catch (e) {
    debugPrint('UserService.switchUserToExternal - Exception: $e');
    throw Exception('Failed to switch user to external: $e');
  }
}
  Future<bool> uploadSignature(String userId, String filePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiUrl}/users/upload-signature/$userId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to upload signature');
      }
    } catch (e) {
      throw Exception('Error uploading signature: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAdminUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/get-admin'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load admin user');
    }
  }

  Future<bool> updateUserRoles(String userId, List<String> roles) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.patch(
      Uri.parse('${Env.apiUrl}/users/update-roles/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'roles': roles}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to update user roles');
    }
  }

  Future<bool> addExternalUser(Map<String, dynamic> userData, List<String> filePaths) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiUrl}/users/add-external'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['fname'] = userData['fname'];
      request.fields['lname'] = userData['lname'];
      request.fields['departement'] = userData['departement'];

      for (var filePath in filePaths) {
        request.files.add(await http.MultipartFile.fromPath('files', filePath));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to add external user');
      }
    } catch (e) {
      throw Exception('Error adding external user: $e');
    }
  }

  Future<List> fetchSignUpRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/signup/requests'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load sign-up requests');
    }
  }

  Future<bool> confirmSignUp(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/users/confirm-signup/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['error'] ?? 'Failed to approve user');
      }
    } catch (e) {
      print('Error confirming sign-up: $e');
      throw Exception('Error: $e');
    }
  }

  Future<List> fetchDrivers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/drivers'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load drivers');
    }
  }

  Future<bool> updatePassword(String userId, String newPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final url = Uri.parse('${Env.apiUrl}/users/updatePass/$userId');
    print('Debug: Full API URL: $url');
    print('Debug: Token: $token');
    print('Debug: Request body: ${jsonEncode({'password': newPassword})}');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'password': newPassword,
        }),
      );

      print('Debug: HTTP status code: ${response.statusCode}');
      print('Debug: HTTP response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['error'] ?? 'Failed to update password');
      }
    } catch (e) {
      print('Debug: Error updating password: $e');
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getUserById(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/getUserByID/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('User Details Response Status: ${response.statusCode}');
    print('User Details Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> updatedUser, {File? imageFile}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      if (imageFile != null) {
        var request = http.MultipartRequest(
          'PUT',
          Uri.parse('${Env.apiUrl}/users/update/$userId'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        updatedUser.forEach((key, value) {
          request.fields[key] = value.toString();
        });

        final mimeType = lookupMimeType(imageFile.path) ?? 'image/png';
        request.files.add(
          http.MultipartFile(
            'image',
            imageFile.readAsBytes().asStream(),
            imageFile.lengthSync(),
            filename: basename(imageFile.path),
            contentType: MediaType.parse(mimeType),
          ),
        );

        var response = await request.send();

        if (response.statusCode == 200) {
          return true;
        } else {
          final responseBody = await response.stream.bytesToString();
          throw Exception(json.decode(responseBody)['error'] ?? 'Failed to update user with image');
        }
      } else {
        final response = await http.put(
          Uri.parse('${Env.apiUrl}/users/update/$userId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(updatedUser),
        );

        if (response.statusCode == 200) {
          return true;
        } else {
          final responseBody = json.decode(response.body);
          throw Exception(responseBody['error'] ?? 'Failed to update user');
        }
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  Future<bool> deleteUser(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.delete(
        Uri.parse('${Env.apiUrl}/users/delete/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Create a new user event (Book a Technician)
  Future<UserEvent> createUserEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    required String engineerId,
    required String job,
    required String address,
    required String applicantId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final body = json.encode({
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'engineer': engineerId,
      'job': job,
      'address': address,
      'applicant': applicantId,
    });

    final response = await http.post(
      Uri.parse('${Env.apiUrl}/users/setevent'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserEvent.fromJson(data);
    } else {
      final responseBody = json.decode(response.body);
      throw Exception(responseBody['error'] ?? 'Failed to create user event');
    }
  }

  // Get user events for a specific engineer within a date range
  Future<List<UserEvent>> getUserEvents({
    required String engineerId,
    required DateTime start,
    required DateTime end,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final uri = Uri.parse('${Env.apiUrl}/users/events').replace(queryParameters: {
      'engineer': engineerId,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List).map((event) => UserEvent.fromJson(event)).toList();
    } else {
      final responseBody = json.decode(response.body);
      throw Exception(responseBody['error'] ?? 'Failed to fetch user events');
    }
  }

  // Get all user events (for admin or overview purposes)
Future<List<UserEvent>> getAllUserEvents() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  try {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/users/allUserEvents'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('getAllUserEvents Response Status: ${response.statusCode}');
    print('getAllUserEvents Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data is List) {
        return data.map((event) {
          if (event is Map<String, dynamic>) {
            return UserEvent.fromJson(event);
          } else {
            throw Exception('Event item is not a Map: $event');
          }
        }).toList();
      } else if (data is Map<String, dynamic>) {
        // Handle case where API returns a single event wrapped in an object
        return [UserEvent.fromJson(data)];
      } else if (data is String) {
        throw Exception('Unexpected string response: $data');
      } else {
        throw Exception('Unexpected response format: $data');
      }
    } else {
      // Try to parse error message
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to fetch events: ${response.statusCode}');
      } catch (_) {
        throw Exception('Failed to fetch events: ${response.statusCode} - ${response.body}');
      }
    }
  } catch (e) {
    throw Exception('Failed to fetch events: $e');
  }
}

  // Update a user event
  Future<UserEvent> updateUserEvent({
    required String eventId,
    required String title,
    required DateTime start,
    required DateTime end,
    required String job,
    required String address,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final body = json.encode({
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'job': job,
      'address': address,
    });

    final response = await http.put(
      Uri.parse('${Env.apiUrl}/users/updateEvent/$eventId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UserEvent.fromJson(data);
    } else {
      final responseBody = json.decode(response.body);
      throw Exception(responseBody['error'] ?? 'Failed to update user event');
    }
  }

  // Delete a user event
  Future<bool> deleteUserEvent(String eventId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.delete(
      Uri.parse('${Env.apiUrl}/users/deleteEvent/$eventId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      final responseBody = json.decode(response.body);
      throw Exception(responseBody['error'] ?? 'Failed to delete user event');
    }
  }
}