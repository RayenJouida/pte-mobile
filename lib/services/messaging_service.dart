import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../config/env.dart';

class MessageService {
  // Send a message to a specific user
  Future<bool> sendMessage(String receiverId, String messageText) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? senderId = prefs.getString('userId'); // Sender ID from preferences
    String? token = prefs.getString('authToken'); // Authentication token

    // Ensure the user is authenticated
    if (senderId == null || token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.post(
        Uri.parse('${Env.apiUrl}/messages/send'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'sender': senderId,
          'receiver': receiverId,
          'content': messageText,
        }),
      );

      if (response.statusCode == 201) {
        print('Message sent successfully!');
        return true;
      } else {
        print('Failed to send message: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Fetch messages between the current user and a recipient
  Future<List<Message>> fetchMessages(String userId, String recipientId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken'); // Authentication token

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/messages/$userId/$recipientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response into a list of messages
        List<dynamic> body = json.decode(response.body);
        return body.map((json) => Message.fromJson(json)).toList();
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        throw Exception('Failed to fetch messages');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      throw Exception('Failed to fetch messages');
    }
  }

  // Fetch the list of users available for messaging
  Future<List<dynamic>> fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken'); // Authentication token

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/users/getall'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the JSON response into a list of users
        return json.decode(response.body);
      } else {
        print('Failed to fetch users: ${response.statusCode}');
        throw Exception('Failed to fetch users');
      }
    } catch (e) {
      print('Error fetching users: $e');
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<Map<String, dynamic>>> fetchConversations(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('${Env.apiUrl}/messages/conversations/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch conversations');
      }
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  // New method to mark messages as read for a specific conversation
  Future<int> markMessagesAsRead(String senderId, String receiverId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.patch(
        Uri.parse('${Env.apiUrl}/messages/mark-read/$senderId/$receiverId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0; // Return the updated unread count
      } else {
        print('Failed to mark messages as read: ${response.statusCode}');
        throw Exception('Failed to mark messages as read');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      throw Exception('Failed to mark messages as read');
    }
  }
}