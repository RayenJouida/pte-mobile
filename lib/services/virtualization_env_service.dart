import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart'; // Import the environment file
import '../models/virtualization_env.dart'; // Import the VirtualizationEnv model

class VirtualizationEnvService {
  // Fetch all virtualization environments
  Future<List<VirtualizationEnv>> getAllVirtualizationEnvs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/material/virtualization/getVirtsEnv'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Status Code: ${response.statusCode}'); // Log the status code
    print('Response Body: ${response.body}'); // Log the raw response body

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print('Parsed Data: $data'); // Log the parsed data
      return data.map((json) => VirtualizationEnv.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load virtualization environments');
    }
  }

  // Add a new virtualization environment
Future<VirtualizationEnv> addVirtualizationEnv(Map<String, dynamic> envData) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');
  String? userId = prefs.getString('userId');

  if (token == null || userId == null) {
    throw Exception('Token or user ID is not available');
  }

  // Prepare the payload with proper types
  final Map<String, dynamic> payload = {
    'firstName': envData['firstName']?.toString() ?? '',
    'lastName': envData['lastName']?.toString() ?? '',
    'email': envData['email']?.toString() ?? '',
    'departement': envData['departement']?.toString() ?? '',
    'type': envData['type']?.toString() ?? '',
    'backup': envData['backup'] ?? false,
    'ram': envData['ram']?.toString() ?? '', // Ensure string
    'disk': envData['disk']?.toString() ?? '', // Ensure string
    'processor': envData['processor']?.toString() ?? '',
    'dhcp': envData['dhcp'] ?? false,
    'start': envData['start']?.toString() ?? '',
    'end': envData['end']?.toString() ?? '',
    'goals': envData['goals']?.toString() ?? '',
    'applicant': userId, // Just the ID string
  };

  print('===== REQUEST DATA =====');
  print('Endpoint: ${Env.apiUrl}/material/virtualization/addaddVirtEnv');
  print('Token: $token');
  print('Request payload: ${json.encode(payload)}');

  try {
    final response = await http.post(
      Uri.parse('${Env.apiUrl}/material/virtualization/addaddVirtEnv'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    print('===== RESPONSE DATA =====');
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return VirtualizationEnv.fromJson(responseData);
    } else {
      throw Exception('Failed to add virtualization environment. Status: ${response.statusCode}, Body: ${response.body}');
    }
  } catch (e) {
    print('===== ERROR DETAILS =====');
    print('Error type: ${e.runtimeType}');
    print('Error message: $e');
    rethrow;
  }
}  // Fetch a specific virtualization environment by ID
  Future<VirtualizationEnv> getVirtualizationEnvById(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.get(
      Uri.parse('${Env.apiUrl}/material/virtualization/getVirtEnv/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return VirtualizationEnv.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load virtualization environment');
    }
  }

  // Delete a virtualization environment by ID
  Future<bool> deleteVirtualizationEnv(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.delete(
      Uri.parse('${Env.apiUrl}/material/virtualization/deleteVirtEnv/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete virtualization environment');
    }
  }

  // Accept a lab request
  Future<VirtualizationEnv> acceptLabRequest(String id, Map<String, dynamic> requestData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.put(
      Uri.parse('${Env.apiUrl}/material/virtualization/accpectReq/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestData),
    );

    if (response.statusCode == 200) {
      return VirtualizationEnv.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to accept lab request');
    }
  }

  // Decline a lab request
  Future<VirtualizationEnv> declineLabRequest(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    final response = await http.put(
      Uri.parse('${Env.apiUrl}/material/virtualization/declineReq/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return VirtualizationEnv.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to decline lab request');
    }
  }

  // Fetch all lab environments for a specific user
Future<List<VirtualizationEnv>> getUserLabEnvs(String userId) async {
  print('===== STARTING getUserLabEnvs =====');
  print('User ID: $userId');
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');
  
  print('Token exists: ${token != null}');
  print('API URL: ${Env.apiUrl}');

  if (token == null) {
    print('ERROR: No auth token found');
    throw Exception('Authentication token not available');
  }

  final url = Uri.parse('${Env.apiUrl}/material/virtualization/getUserLabEnv/$userId');
  print('Final request URL: $url');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('===== RESPONSE DATA =====');
    print('Status code: ${response.statusCode}');
    print('Response headers: ${response.headers}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final List<dynamic> data = json.decode(response.body);
        print('Parsed ${data.length} requests');
        
        if (data.isEmpty) {
          print('NOTE: Empty array returned from API - no requests found');
        } else {
          print('First request data: ${data[0]}');
        }
        
        return data.map((json) => VirtualizationEnv.fromJson(json)).toList();
      } else {
        print('ERROR: Response is not JSON');
        throw Exception('Server returned non-JSON response');
      }
    } else {
      print('ERROR: Server returned ${response.statusCode}');
      throw Exception('Failed to load user lab environments. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('===== ERROR IN getUserLabEnvs =====');
    print('Error type: ${e.runtimeType}');
    print('Error message: $e');
    if (e is http.ClientException) {
      print('HTTP Exception details: ${e.message}');
    }
    rethrow;
  }
}  // Fetch all active labs
  Future<List<VirtualizationEnv>> getActiveLabs() async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/material/virtualization/allActiveLabs'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => VirtualizationEnv.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load active labs');
    }
  }
}