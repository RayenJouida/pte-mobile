import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart';
import '../models/virtualization_env.dart';

class VirtualizationEnvService {
  Future<List<VirtualizationEnv>> getAllVirtualizationEnvs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      print('ERROR: No auth token found');
      throw Exception('Token is not available');
    }

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/getVirtsEnv');
    print('Fetching virtualization envs: $url');
    print('Token: $token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('GetAllVirtEnvs Status: ${response.statusCode}');
      print('GetAllVirtEnvs Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('GetAllVirtEnvs Parsed: ${data.length} items');
        return data.map((json) => VirtualizationEnv.fromJson(json)).toList();
      } else {
        print('GetAllVirtEnvs Error: Status ${response.statusCode}');
        throw Exception('Failed to load virtualization environments: ${response.body}');
      }
    } catch (e) {
      print('GetAllVirtEnvs Exception: $e');
      rethrow;
    }
  }

  Future<VirtualizationEnv> addVirtualizationEnv(Map<String, dynamic> envData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    String? userId = prefs.getString('userId');

    if (token == null || userId == null) {
      print('ERROR: Token or userId missing');
      throw Exception('Token or user ID is not available');
    }

    final payload = {
      'firstName': envData['firstName']?.toString() ?? '',
      'lastName': envData['lastName']?.toString() ?? '',
      'email': envData['email']?.toString() ?? '',
      'departement': envData['departement']?.toString() ?? '',
      'type': envData['type']?.toString() ?? '',
      'backup': envData['backup'] ?? false,
      'ram': envData['ram']?.toString() ?? '',
      'disk': envData['disk']?.toString() ?? '',
      'processor': envData['processor']?.toString() ?? '',
      'dhcp': envData['dhcp'] ?? false,
      'start': envData['start']?.toString() ?? '',
      'end': envData['end']?.toString() ?? '',
      'goals': envData['goals']?.toString() ?? '',
      'applicant': userId,
    };

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/addaddVirtEnv');
    print('Adding virt env: $url');
    print('Token: $token');
    print('Payload: ${json.encode(payload)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      print('AddVirtEnv Status: ${response.statusCode}');
      print('AddVirtEnv Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return VirtualizationEnv.fromJson(responseData);
      } else {
        print('AddVirtEnv Error: Status ${response.statusCode}');
        throw Exception('Failed to add virtualization environment: ${response.body}');
      }
    } catch (e) {
      print('AddVirtEnv Exception: $e');
      rethrow;
    }
  }

  Future<VirtualizationEnv> getVirtualizationEnvById(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      print('ERROR: No auth token found');
      throw Exception('Token is not available');
    }

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/getVirtEnv/$id');
    print('Fetching virt env: $url');
    print('Token: $token');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('GetVirtEnv Status: ${response.statusCode}');
      print('GetVirtEnv Body: ${response.body}');

      if (response.statusCode == 200) {
        return VirtualizationEnv.fromJson(json.decode(response.body));
      } else {
        print('GetVirtEnv Error: Status ${response.statusCode}');
        throw Exception('Failed to load virtualization environment: ${response.body}');
      }
    } catch (e) {
      print('GetVirtEnv Exception: $e');
      rethrow;
    }
  }

  Future<bool> deleteVirtualizationEnv(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      print('ERROR: No auth token found');
      throw Exception('Token is not available');
    }

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/deleteVirtEnv/$id');
    print('Deleting virt env: $url');
    print('Token: $token');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('DeleteVirtEnv Status: ${response.statusCode}');
      print('DeleteVirtEnv Body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print('DeleteVirtEnv Error: Status ${response.statusCode}');
        throw Exception('Failed to delete virtualization environment: ${response.body}');
      }
    } catch (e) {
      print('DeleteVirtEnv Exception: $e');
      rethrow;
    }
  }

  Future<VirtualizationEnv> acceptLabRequest(String id, Map<String, dynamic> requestData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      print('ERROR: No auth token found');
      throw Exception('Token is not available');
    }

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/acceptReq/$id');
    print('Accepting lab request: $url');
    print('Token: $token');
    print('Payload: ${json.encode(requestData)}');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('AcceptReq Status: ${response.statusCode}');
      print('AcceptReq Body: ${response.body}');

      if (response.statusCode == 200) {
        return VirtualizationEnv.fromJson(json.decode(response.body));
      } else {
        print('AcceptReq Error: Status ${response.statusCode}');
        throw Exception('Failed to accept lab request: ${response.body}');
      }
    } catch (e) {
      print('AcceptReq Exception: $e');
      rethrow;
    }
  }

  Future<VirtualizationEnv> declineLabRequest(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      print('ERROR: No auth token found');
      throw Exception('Token is not available');
    }

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/declineReq/$id');
    print('Declining lab request: $url');
    print('Token: $token');
    print('Payload: {}');

    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      print('DeclineReq Status: ${response.statusCode}');
      print('DeclineReq Body: ${response.body}');

      if (response.statusCode == 200) {
        return VirtualizationEnv.fromJson(json.decode(response.body));
      } else {
        print('DeclineReq Error: Status ${response.statusCode}');
        throw Exception('Failed to decline lab request: ${response.body}');
      }
    } catch (e) {
      print('DeclineReq Exception: $e');
      rethrow;
    }
  }

  Future<List<VirtualizationEnv>> getUserLabEnvs(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    print('Fetching user lab envs for userId: $userId');
    print('Token exists: ${token != null}');

    if (token == null) {
      print('ERROR: No auth token found');
      throw Exception('Authentication token not available');
    }

    final url = Uri.parse('${Env.apiUrl}/material/virtualization/getUserLabEnv/$userId');
    print('Fetching user lab envs: $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('GetUserLabEnvs Status: ${response.statusCode}');
      print('GetUserLabEnvs Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('GetUserLabEnvs Parsed: ${data.length} items');
        return data.map((json) => VirtualizationEnv.fromJson(json)).toList();
      } else {
        print('GetUserLabEnvs Error: Status ${response.statusCode}');
        throw Exception('Failed to load user lab environments: ${response.body}');
      }
    } catch (e) {
      print('GetUserLabEnvs Exception: $e');
      rethrow;
    }
  }

  Future<List<VirtualizationEnv>> getActiveLabs() async {
    final url = Uri.parse('${Env.apiUrl}/material/virtualization/allActiveLabs');
    print('Fetching active labs: $url');

    try {
      final response = await http.get(url);

      print('GetActiveLabs Status: ${response.statusCode}');
      print('GetActiveLabs Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('GetActiveLabs Parsed: ${data.length} items');
        return data.map((json) => VirtualizationEnv.fromJson(json)).toList();
      } else {
        print('GetActiveLabs Error: Status ${response.statusCode}');
        throw Exception('Failed to load active labs: ${response.body}');
      }
    } catch (e) {
      print('GetActiveLabs Exception: $e');
      rethrow;
    }
  }
}
