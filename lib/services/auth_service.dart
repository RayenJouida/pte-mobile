import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/user.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../models/activity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  Future<bool> signUp({
    required String matricule,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String experience,
    required String phone,
    required String nationality,
    required String fs,
    required String bio,
    required String address,
    required String departement,
    required bool teamLeader,
    String? imagePath,
    String? hiringDate,
    bool? drivingLicense,
    String? gender,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.apiUrl}/users/signup'),
      );

      request.fields.addAll({
        'matricule': matricule,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'experience': experience,
        'phone': phone,
        'nationality': nationality,
        'fs': fs,
        'bio': bio,
        'address': address,
        'departement': departement,
        'teamLeader': teamLeader.toString(),
        'hiringDate': hiringDate ?? '',
        'drivingLicense': drivingLicense?.toString() ?? 'false',
        'gender': gender ?? '',
      });

      print("Request fields added: ${request.fields}");

      if (imagePath != null && imagePath.isNotEmpty) {
        File imageFile = File(imagePath);

        if (!await imageFile.exists()) {
          print("Image file does not exist at: $imagePath");
          return false;
        } else {
          print("Image file exists and will be uploaded");
        }

        request.files.add(
          http.MultipartFile(
            'image',
            imageFile.openRead(),
            imageFile.lengthSync(),
            filename: basename(imageFile.path),
            contentType: MediaType.parse(lookupMimeType(imagePath) ?? 'application/octet-stream'),
          ),
        );
      }

      print("Request details:");
      print("URL: ${request.url}");
      print("Fields: ${request.fields}");
      for (var file in request.files) {
        print("File field: ${file.field}, Filename: ${file.filename}");
      }

      try {
        var response = await request.send().timeout(Duration(seconds: 30));
        print("Request sent. Waiting for response...");
        var responseBody = await response.stream.bytesToString();
        print('Response Status: ${response.statusCode}');
        print('Response Body: $responseBody');

        if (response.statusCode == 200) {
          print("Signup successful!");
          return true;
        } else {
          print("Signup failed with status code: ${response.statusCode}");
          print("Response body: $responseBody");
          return false;
        }
      } on TimeoutException {
        print("Request timed out. Backend might be unresponsive.");
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/users/forgotPassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<bool> validateCode(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/users/validateCode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'code': code}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<bool> changePassword(String id, String email, String password) async {
    print('Entered changePassword function');
    try {
      print('Attempting to change password for email: $email');
      print('New password: $password');
      print('ID: $id');

      final response = await http.patch(
        Uri.parse('${Env.apiUrl}/users/change-psw/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 && response.body == '"password updated"') {
        print('Password successfully updated for email: $email');
        return true;
      } else {
        print('Failed to update password: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  Future<User?> fetchUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch user response status: ${response.statusCode}');
      print('Fetch user response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching user: $e');
      rethrow;
    }
  }


  Future<User?> login(String email, String password) async {
    try {
      // Ensure Firebase is initialized
      try {
        await Firebase.initializeApp();
        print('Firebase initialized in login');
      } catch (e) {
        print('Firebase initialization error: $e');
      }

      final response = await http.post(
        Uri.parse('${Env.apiUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Validate and store userId
        final userId = responseData['id'] as String?;
        if (userId == null || userId.isEmpty) {
          throw Exception('Invalid or missing userId in response: ${response.body}');
        }
        await prefs.setString('userId', userId);
        print('Stored userId in SharedPreferences: $userId');

        // Store other user data
        await prefs.setString('authToken', responseData['token']);
        await prefs.setString('userName', responseData['userName'] ?? 'User');
        await prefs.setString('userImage', responseData['image'] ?? '');

        if (responseData['userName'] != null) {
          final nameParts = responseData['userName'].split(' ');
          await prefs.setString('firstName', nameParts.isNotEmpty ? nameParts[0] : 'Unknown');
          await prefs.setString('lastName', nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User');
        } else {
          await prefs.setString('firstName', 'Unknown');
          await prefs.setString('lastName', 'User');
        }

        await prefs.setString('email', email);

        if (responseData['roles'] != null && responseData['roles'].isNotEmpty) {
          await prefs.setString('userRole', responseData['roles'][0]);
        } else {
          await prefs.setString('userRole', 'Unknown Role');
        }

        // Attempt to save FCM token
        try {
          FirebaseMessaging messaging = FirebaseMessaging.instance;
          NotificationSettings settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          print('Notification permission status: ${settings.authorizationStatus}');
          if (settings.authorizationStatus == AuthorizationStatus.authorized) {
            String? fcmToken;
            // Retry token retrieval with a timeout
            try {
              fcmToken = await messaging.getToken().timeout(Duration(seconds: 5));
              if (fcmToken != null) {
                await updateFcmToken(userId, fcmToken, responseData['token']);
              } else {
                print('FCM token is null');
              }
            } catch (e) {
              print('Failed to retrieve FCM token: $e');
            }
          } else {
            print('Notification permissions not granted');
          }
        } catch (e) {
          print('Error handling FCM in login: $e');
        }

        return User.fromJson(responseData);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid credentials. Please check your email and password.');
      } else if (response.statusCode == 403) {
        throw Exception('Account not yet confirmed. Please wait for email verification.');
      } else {
        throw Exception('Login failed: ${responseData['message']}');
      }
    } catch (e) {
      print('Exception during login: $e');
      throw Exception('Login error: $e');
    }
  }

  Future<void> updateFcmToken(String userId, String fcmToken, String authToken) async {
    try {
      final response = await http.patch(
        Uri.parse('${Env.apiUrl}/users/$userId/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode == 200) {
        print('FCM token updated successfully for user: $userId');
      } else {
        print('Failed to update FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<bool> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    if (token != null) {
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  static Future<Map<String, String>> getCurrentUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString('userName') ?? 'Unknown User',
    };
  }

  Future<List<Activity>> fetchActivities() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('authToken');
    if (userId == null) throw Exception('User not logged in');
    if (token == null) throw Exception('Not authenticated');

    print('Fetching activities for user: $userId');
    print('Using token: $token');

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
        return data.map((json) => Activity.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch activities: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching activities: $e');
      rethrow;
    }
  }

  Future<void> markActivitiesAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('authToken');
    if (userId == null) throw Exception('User not logged in');
    if (token == null) throw Exception('Not authenticated');

    print('Marking activities as read for user: $userId');
    print('Using token: $token');

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

  Future<Map<String, int>> fetchUnreadCounts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    String? token = prefs.getString('authToken');
    if (userId == null) throw Exception('User not logged in');
    if (token == null) throw Exception('Not authenticated');

    print('Fetching unread counts for user: $userId');
    print('Using token: $token');

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/messages/unread-count/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Fetch unread counts response status: ${response.statusCode}');
      print('Fetch unread counts response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Unread counts: messages=${data['unreadCount']}, activities=${data['unreadActivities'] ?? 0}');
        return {
          'unreadMessages': data['unreadCount'] ?? 0,
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
}