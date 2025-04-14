import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env.dart'; // Import the environment file
import 'package:path/path.dart';

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

  if (token == null) {
    throw Exception('Token is not available');
  }

  final response = await http.patch(
    Uri.parse('${Env.apiUrl}/users/switch-to-external/$userId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    throw Exception('Failed to switch user to external');
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

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add file
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

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';

    // Add fields
    request.fields['fname'] = userData['fname'];
    request.fields['lname'] = userData['lname'];
    request.fields['departement'] = userData['departement'];

    // Add files
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
  // Fetch all sign-up requests (inactive users)
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

  // Confirm sign-up request
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
        return true; // Successfully confirmed
      } else {
        // Capture error message from response body (if available)
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['error'] ?? 'Failed to approve user');
      }
    } catch (e) {
      print('Error confirming sign-up: $e'); // Log the error
      throw Exception('Error: $e');
    }
  }

  // Fetch all drivers with a valid driving license
Future<List> fetchDrivers() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');

  if (token == null) {
    throw Exception('Token is not available');
  }

  final response = await http.get(
    Uri.parse('${Env.apiUrl}/users/drivers'), // Call the getDrivers endpoint
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


  // Update password method
  Future<bool> updatePassword(String userId, String newPassword) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');

    if (token == null) {
      throw Exception('Token is not available');
    }

    try {
      final response = await http.patch(
        Uri.parse('${Env.apiUrl}/updatePass/$userId'), // Backend endpoint
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true; // Successful password update
      } else {
        final responseBody = json.decode(response.body);
        throw Exception(responseBody['error'] ?? 'Failed to update password');
      }
    } catch (e) {
      print('Error updating password: $e');
      throw Exception('Error: $e');
    }
  }

  // Fetch user details by ID
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
      // If an image is provided, use a multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('${Env.apiUrl}/users/update/$userId'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      updatedUser.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add image file with correct MIME type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/png'; // Default to 'image/png' if MIME type is not found
      request.files.add(
        http.MultipartFile(
          'image',
          imageFile.readAsBytes().asStream(),
          imageFile.lengthSync(),
          filename: basename(imageFile.path),
          contentType: MediaType.parse(mimeType), // Set the correct MIME type
        ),
      );

      // Send the request
      var response = await request.send();

      // Check the response
      if (response.statusCode == 200) {
        return true;
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception(json.decode(responseBody)['error'] ?? 'Failed to update user with image');
      }
    } else {
      // If no image is provided, use a regular PUT request
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

  // Delete a user
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
        return true; // Successfully deleted
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }


}
