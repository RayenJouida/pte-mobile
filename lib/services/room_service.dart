import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart'; // Import the Env class for the API URL
import '../models/room.dart'; // Import the Room model
import '../models/room_event.dart'; // Import the RoomEvent model

class RoomService {
  final String baseUrl;

  RoomService() : baseUrl = Env.apiUrl;

  // Helper method to get headers with auth token and user role
  Future<Map<String, String>> _getHeaders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userRole = prefs.getString('userRole');

    if (token == null || userRole == null) {
      throw Exception('Token or role is not available');
    }

    return {
      'Authorization': 'Bearer $token',
      'Role': userRole,
      'Content-Type': 'application/json',
    };
  }

  // Room Management Methods

  // Get all rooms
  Future<List<Room>> getAllRooms() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/room/getRooms'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((room) => Room.fromJson(room)).toList();
      } else {
        throw Exception('Failed to load rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllRooms: $e');
      rethrow;
    }
  }

  // Search rooms by label or location
  Future<List<Room>> searchRooms(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/room/search?text=$query'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((room) => Room.fromJson(room)).toList();
      } else {
        throw Exception('Failed to search rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in searchRooms: $e');
      rethrow;
    }
  }

  // Add a new room
  Future<Room> addRoom(Room room) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/material/room/add'),
        headers: await _getHeaders(),
        body: json.encode(room.toJson()),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return Room.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addRoom: $e');
      rethrow;
    }
  }

  // Edit a room
  Future<Room> editRoom(String id, Room room) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/material/room/editRoom/$id'),
        headers: await _getHeaders(),
        body: json.encode(room.toJson()),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return Room.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to edit room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in editRoom: $e');
      rethrow;
    }
  }

  // Delete a room
  Future<void> deleteRoom(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/material/room/delete/$id'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteRoom: $e');
      rethrow;
    }
  }

  // Event Management Methods

  // Get all events for a room
  Future<List<RoomEvent>> getRoomEvents(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/room/getRoomEvents/$roomId'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((event) => RoomEvent.fromJson(event)).toList();
      } else {
        throw Exception('Failed to load room events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRoomEvents: $e');
      rethrow;
    }
  }

  // Create a new event
  Future<RoomEvent> createEvent(RoomEvent event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/material/room/setevent'),
        headers: await _getHeaders(),
        body: json.encode(event.toJson()),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return RoomEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createEvent: $e');
      rethrow;
    }
  }

  // Update an event
  Future<RoomEvent> updateEvent(String eventId, RoomEvent event) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/material/room/updateEvent/$eventId'),
        headers: await _getHeaders(),
        body: json.encode(event.toJson()),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return RoomEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateEvent: $e');
      rethrow;
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/material/room/deleteEvent/$eventId'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deleteEvent: $e');
      rethrow;
    }
  }

  // Get an event by ID
  Future<RoomEvent> getEventById(String eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/room/getEventById/$eventId'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return RoomEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getEventById: $e');
      rethrow;
    }
  }

  // Get all events
  Future<List<RoomEvent>> getAllEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/room/getAllEvents'),
        headers: await _getHeaders(),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((event) => RoomEvent.fromJson(event)).toList();
      } else {
        throw Exception('Failed to load all events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getAllEvents: $e');
      rethrow;
    }
  }
}