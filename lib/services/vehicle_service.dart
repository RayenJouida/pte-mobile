import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/models/vehicule_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleService {
  final String baseUrl;

  VehicleService() : baseUrl = Env.apiUrl;

  // Fetch all vehicles
  Future<List<Vehicle>> getVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userRole = prefs.getString('userRole'); // Get the user role

    if (token == null || userRole == null) {
      throw Exception('Token or role is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/getVehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Role': userRole, // Include the user role in the headers
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => Vehicle.fromJson(data)).toList();
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
      throw Exception('Error fetching vehicles: $e');
    }
  }

  // Add a new vehicle
Future<Vehicle> addVehicle(Vehicle vehicle) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/material/vehicle/addVehicle'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Add the Authorization header
      },
      body: json.encode(vehicle.toJson()),
    );

    if (response.statusCode == 200) {
      return Vehicle.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add vehicle: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error adding vehicle: $e');
  }
}
  // Update a vehicle's details
Future<Vehicle> updateVehicle(Vehicle vehicle) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  try {
    final response = await http.put(
      Uri.parse('$baseUrl/material/vehicle/editVehicle/${vehicle.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Add the Authorization header
      },
      body: json.encode(vehicle.toJson()),
    );

    print('Response Status Code: ${response.statusCode}'); // Debugging
    print('Response Body: ${response.body}'); // Debugging

    if (response.statusCode == 200) {
      return Vehicle.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update vehicle: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error updating vehicle: $e');
  }
}
  // Delete a vehicle
Future<void> deleteVehicle(String vehicleId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/material/vehicle/deleteVehicle/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token', // Add the Authorization header
      },
    );

    print('Response Status Code: ${response.statusCode}'); // Debugging
    print('Response Body: ${response.body}'); // Debugging

    if (response.statusCode != 200) {
      throw Exception('Failed to delete vehicle: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error deleting vehicle: $e');
  }
}  // Search for a vehicle (by type, registration number, or model)
  Future<List<Vehicle>> searchVehicles(String text) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/search?text=$text'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => Vehicle.fromJson(data)).toList();
      } else {
        throw Exception('Failed to search vehicles');
      }
    } catch (e) {
      throw Exception('Error searching vehicles: $e');
    }
  }

  // Fetch all vehicle events
Future<List<VehicleEvent>> getAllEvents() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/material/vehicle/getallevents'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('API Response Status: ${response.statusCode}'); // Debug print
    print('API Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      final List<dynamic> responseBody = json.decode(response.body);
      return responseBody.map((event) => VehicleEvent.fromJson(event)).toList();
    } else {
      throw Exception('Failed to load events: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error fetching events: $e');
  }
}Future<VehicleEvent> createEvent(VehicleEvent event) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/material/vehicle/setevent'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(event.toJson()),
    );

    print('API Request Body: ${event.toJson()}'); // Debug print
    print('API Response Status: ${response.statusCode}'); // Debug print
    print('API Response Body: ${response.body}'); // Debug print

    if (response.statusCode == 200) {
      return VehicleEvent.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create event: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error creating event: $e');
  }
}}