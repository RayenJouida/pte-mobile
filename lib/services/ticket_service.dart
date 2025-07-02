import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TicketService {
  final String _opmApi = '${Env.opmUrl}/ticket/ticketReservation';

  Future<Map<String, dynamic>> getTicketReservation(String email, String caseId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse(_opmApi),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'caseId': caseId,
        }),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load ticket reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching ticket reservation: $e');
      throw Exception('Error fetching ticket reservation: $e');
    }
  }

  Future<Map<String, dynamic>> createTicketReservation(Map<String, dynamic> ticketData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.post(
        Uri.parse(_opmApi),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(ticketData),
      );

      print('Request Body: ${json.encode(ticketData)}');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create ticket reservation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error creating ticket reservation: $e');
      throw Exception('Error creating ticket reservation: $e');
    }
  }
}