// services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../config/env.dart';

class AIService {
  /// Upload multiple resumes to AI backend
  static Future<bool> uploadResumes(List<File> files) async {
    final uri = Uri.parse('${Env.aiUrl}/upload_resumes');
    final request = http.MultipartRequest('POST', uri);

    for (var file in files) {
      final mimeType = lookupMimeType(file.path)?.split('/') ?? ['application', 'octet-stream'];
      request.files.add(
        await http.MultipartFile.fromPath(
          'files', // 🟢 match backend key
          file.path,
          contentType: MediaType(mimeType[0], mimeType[1]),
        ),
      );
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      print('✅ Resumes uploaded successfully');
    } else {
      print('❌ Failed to upload resumes: ${response.statusCode}');
    }

    return response.statusCode == 200;
  }

  /// Send job description and get ranked results
  static Future<List<Map<String, dynamic>>> processJobDescription(String jobDescription) async {
    try {
      final uri = Uri.parse('${Env.aiUrl}/process_mobile');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'job_description': jobDescription}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['candidates'] != null) {
          return List<Map<String, dynamic>>.from(data['candidates']);
        }
      } else {
        print('❌ Failed to process: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in processJobDescription: $e');
    }
    return [];
  }
}
