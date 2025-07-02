import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/models/vehicule_event.dart';
import 'package:pte_mobile/models/gas_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleService {
  final String baseUrl;

  VehicleService() : baseUrl = Env.apiUrl; // http://localhost:3001/api

  Map<String, dynamic> _preprocessVehicleEventJson(Map<String, dynamic> json) {
    print('Preprocessing JSON input: $json');
    final processed = {
      ...json, // Preserve all fields
      '_id': json['_id']?.toString(),
      'title': json['title']?.toString(),
      'start': json['start']?.toString(),
      'end': json['end']?.toString(),
      'vehicle': json['vehicle'], // Pass raw value (let fromJson handle it)
      'driver': json['driver'],   // Pass raw value
      'applicant': json['applicant'], // Pass raw value
      'destination': json['destination']?.toString(),
      'departure': json['departure']?.toString(),
      'caseNumber': json['caseNumber']?.toString(),
      'isAccepted': json['isAccepted'] as bool? ?? false,
      'km': json['km'] is int ? json['km'] : int.tryParse(json['km']?.toString() ?? '0') ?? 0,
    };
    print('Processed JSON output: $processed');
    return processed;
  }

  // Helper method to check if a time range overlaps with any event
  bool _hasEventConflict(DateTime start, DateTime end, List<VehicleEvent> events) {
    for (var event in events) {
      final eventStart = event.start;
      final eventEnd = event.end;
      if (eventStart != null && eventEnd != null) {
        if (start.isBefore(eventEnd) && end.isAfter(eventStart)) {
          return true;
        }
      }
    }
    return false;
  }

  // Fetch all vehicles
  Future<List<Vehicle>> getVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userRole = prefs.getString('userRole');

    if (token == null || userRole == null) {
      throw Exception('Token or role is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/getVehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Role': userRole,
        },
      );

      print('Get Vehicles Response Status: ${response.statusCode}');
      print('Get Vehicles Response Body: ${response.body}');

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

  // Fetch available vehicles for a given time range
  Future<List<Vehicle>> fetchAvailableVehicles(Map<String, dynamic> dates) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userRole = prefs.getString('userRole');

    if (token == null || userRole == null) {
      throw Exception('Token or role is not available');
    }

    try {
      final start = DateTime.parse(dates['start']);
      final end = DateTime.parse(dates['end']);
      print('Checking availability for: start=$start, end=$end');

      final allVehicles = await getVehicles();
      print('Total Vehicles Fetched: ${allVehicles.length}');

      List<Vehicle> availableVehicles = [];
      for (var vehicle in allVehicles) {
        if (vehicle.available != true) {
          print('Vehicle ${vehicle.id} (${vehicle.model}) is not available');
          continue;
        }
        if (vehicle.id == null) {
          print('Vehicle ID is null for ${vehicle.model}');
          continue;
        }
        final events = await vehicleEventsById(vehicle.id!);
        print('Events for vehicle ${vehicle.id}: ${events.length}');
        if (!_hasEventConflict(start, end, events)) {
          availableVehicles.add(vehicle);
          print('Vehicle ${vehicle.id} (${vehicle.model}) is available');
        } else {
          print('Vehicle ${vehicle.id} (${vehicle.model}) has conflicting events');
        }
      }

      print('Available Vehicles: ${availableVehicles.length}');
      return availableVehicles;
    } catch (e) {
      print('Error fetching available vehicles: $e');
      throw Exception('Error fetching available vehicles: $e');
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
          'Authorization': 'Bearer $token',
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
  Future<Vehicle> updateVehicle(String vehicleId, Vehicle vehicle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/material/vehicle/editVehicle/$vehicleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'model': vehicle.model,
          'registration_number': vehicle.registrationNumber,
          'type': vehicle.type,
        }),
      );

      print('Update Vehicle Response Status: ${response.statusCode}');
      print('Update Vehicle Response Body: ${response.body}');

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
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete Vehicle Response Status: ${response.statusCode}');
      print('Delete Vehicle Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete vehicle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting vehicle: $e');
    }
  }

  // Search for vehicles
  Future<List<Vehicle>> searchVehicles(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/search?text=${Uri.encodeQueryComponent(text)}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((data) => Vehicle.fromJson(data)).toList();
      } else {
        throw Exception('Failed to search vehicles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching vehicles: $e');
    }
  }

  // Change vehicle availability
  Future<Vehicle> changeAvailability(String vehicleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/material/vehicle/changeAvailability/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Vehicle.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to change availability: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error changing availability: $e');
    }
  }

  // Create a new event
  Future<VehicleEvent> createEvent(VehicleEvent event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      // Convert start and end to UTC
      final eventJson = event.toJson();
      if (event.start != null) {
        eventJson['start'] = event.start!.toUtc().toIso8601String();
      }
      if (event.end != null) {
        eventJson['end'] = event.end!.toUtc().toIso8601String();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/material/vehicle/setevent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(eventJson),
      );

      print('Create Event Request Body: ${json.encode(eventJson)}');
      print('Create Event Response Status: ${response.statusCode}');
      print('Create Event Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VehicleEvent.fromJson(_preprocessVehicleEventJson(jsonData));
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Error creating event: $e');
    }
  }

  // Get vehicle events by vehicle ID
  Future<List<VehicleEvent>> getVehicleEventsById(String vehicleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userRole = prefs.getString('userRole');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/material/vehicle/getVehicleEvents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Role': userRole ?? 'user',
        },
        body: json.encode({'vehicle': vehicleId}),
      );

      print('Get Vehicle Events Request Body: ${json.encode({'vehicle': vehicleId})}');
      print('Get Vehicle Events Response Status: ${response.statusCode}');
      print('Get Vehicle Events Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = json.decode(response.body);
        return responseBody.map((event) => VehicleEvent.fromJson(_preprocessVehicleEventJson(event))).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  // Get vehicle events by vehicle ID (alternative endpoint)
  Future<List<VehicleEvent>> vehicleEventsById(String vehicleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/getVehicleEvents/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Get Vehicle Events By ID Response Status: ${response.statusCode}');
      print('Get Vehicle Events By ID Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = json.decode(response.body);
        return responseBody.map((event) => VehicleEvent.fromJson(_preprocessVehicleEventJson(event))).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  // Edit an event
  Future<VehicleEvent> editEvent(String eventId, VehicleEvent event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/material/vehicle/editEvent/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': event.title,
          'start': event.start?.toUtc().toIso8601String(),
          'end': event.end?.toUtc().toIso8601String(),
          'applicant': event.applicantId,
          'driver': event.driverId,
          'destination': event.destination,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VehicleEvent.fromJson(_preprocessVehicleEventJson(jsonData));
      } else {
        throw Exception('Failed to edit event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error editing event: $e');
    }
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/material/vehicle/deleteEvent/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting event: $e');
    }
  }

  // Get event by ID
  Future<VehicleEvent> getEventById(String eventId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/getEventById/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return VehicleEvent.fromJson(_preprocessVehicleEventJson(jsonData));
      } else {
        throw Exception('Failed to load event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching event: $e');
    }
  }

  // Get all events
  Future<List<VehicleEvent>> getAllEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/getAllEvents'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseBody = json.decode(response.body);
        return responseBody.map((event) => VehicleEvent.fromJson(_preprocessVehicleEventJson(event))).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  // Get gas card by vehicle ID
  Future<GasCard> getVehicleCard(String vehicleId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/material/vehicle/getVehicleCard/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return GasCard.fromJson(responseBody['data']);
      } else {
        throw Exception('Failed to load gas card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching gas card: $e');
    }
  }

  // Add a new gas card
  Future<GasCard> addVehicleCard(GasCard gasCard) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/material/vehicle/addVehicleCard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(gasCard.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return GasCard.fromJson(responseBody['data']);
      } else {
        throw Exception('Failed to add gas card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding gas card: $e');
    }
  }

  // Update a gas card
  Future<GasCard> updateVehicleCard(String cardId, GasCard gasCard) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/material/vehicle/updateVehicleCard/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(gasCard.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        return GasCard.fromJson(responseBody['data']);
      } else {
        throw Exception('Failed to update gas card: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating gas card: $e');
    }
  }

  // Delete a gas card
  Future<void> deleteVehicleCard(String cardId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/material/vehicle/deleteVehicleCard/$cardId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to delete gas card: $cardId');
      }
    } catch (e) {
      throw Exception('Error deleting gas card: $e');
    }
  }

  // Add consumption to a gas card
  Future<GasCard> addConsumption(String cardId, double amount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/material/vehicle/addConsumption/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponseBody = json.decode(response.body);
        return GasCard.fromJson(jsonResponseBody['data']);
      } else {
        throw Exception('Failed to add consumption: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding consumption: $e');
    }
  }
}