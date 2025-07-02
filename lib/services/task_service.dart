import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  final String _pmaApi = '${Env.pmaUrl}/api/v1/tasks/getTasksByUser';

  Future<Map<String, dynamic>> getTaskByUser(String ref, String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse(_pmaApi),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ref': ref,
          'email': email,
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['err'] == false) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Failed to retrieve task');
        }
      } else {
        throw Exception('Failed to load task: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching task: $e');
      throw Exception('Error fetching task: $e');
    }
  }
}
