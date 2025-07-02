import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/models/cv/experience.dart';
import '../models/cv/cv.dart';
import '../models/cv/education.dart';
import '../models/cv/certification.dart';
import '../models/cv/skill.dart';
import '../models/cv/language.dart';
import '../models/cv/project.dart';
import '../config/env.dart';

class CvService {
  final String baseUrl = Env.apiUrl;

  Future<List<Cv>> getUserCV(String userId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getUserCV/$userId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Cv.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch CV: ${response.body}');
    }
  }

  Future<String> getSummary(String userId, String token) async {
    final url = Uri.parse('$baseUrl/getSummary/$userId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['summary'] ?? '';
    } else {
      throw Exception('Failed to fetch summary: ${response.body}');
    }
  }

  Future<void> updateSummary(String cvId, String summary, String userId, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateSummary/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: {"summary": "$summary", "user": "$userId"}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'summary': summary,
        'user': userId,
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update summary: ${response.body}');
    }
  }

  Future<List<Education>> getEducation(String cvId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getEdu/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Education.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch education: ${response.body}');
    }
  }

  Future<void> addEducation(Education education, String token) async {
    final url = Uri.parse('$baseUrl/cv/addEdu'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(education.toJson())}');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(education.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add education: ${response.body}');
    }
  }

  Future<void> updateEducation(String id, Education education, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateEdu/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(education.toJson())}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(education.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update education: ${response.body}');
    }
  }

  Future<void> deleteEducation(String id, String token) async {
    final url = Uri.parse('$baseUrl/cv/deleteEdu/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete education: ${response.body}');
    }
  }

  Future<List<Experience>> getExperience(String cvId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getExp/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Experience.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch experience: ${response.body}');
    }
  }

  Future<void> addExperience(Experience experience, String token) async {
    final url = Uri.parse('$baseUrl/cv/addExp'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(experience.toJson())}');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(experience.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add experience: ${response.body}');
    }
  }

  Future<void> updateExperience(String id, Experience experience, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateExp/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(experience.toJson())}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(experience.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update experience: ${response.body}');
    }
  }

  Future<void> deleteExperience(String id, String token) async {
    final url = Uri.parse('$baseUrl/cv/deleteExp/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete experience: ${response.body}');
    }
  }

  Future<List<Certification>> getCertifications(String cvId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getCertif/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Certification.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch certifications: ${response.body}');
    }
  }

  Future<void> addCertification(Certification certification, String token) async {
    final url = Uri.parse('$baseUrl/cv/addCert'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(certification.toJson())}');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(certification.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add certification: ${response.body}');
    }
  }

  Future<void> updateCertification(String id, Certification certification, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateCert/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(certification.toJson())}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(certification.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update certification: ${response.body}');
    }
  }

  Future<void> deleteCertification(String id, String token) async {
    final url = Uri.parse('$baseUrl/cv/deleteCert/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete certification: ${response.body}');
    }
  }

  Future<List<Skill>> getSkills(String cvId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getSkill/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Skill.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch skills: ${response.body}');
    }
  }

  Future<void> addSkill(Skill skill, String token) async {
    final url = Uri.parse('$baseUrl/cv/addSkill'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(skill.toJson())}');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(skill.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add skill: ${response.body}');
    }
  }

  Future<void> updateSkill(String id, Skill skill, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateSkill/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(skill.toJson())}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(skill.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update skill: ${response.body}');
    }
  }

  Future<void> deleteSkill(String id, String token) async {
    final url = Uri.parse('$baseUrl/cv/deleteSkill/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete skill: ${response.body}');
    }
  }

  Future<List<Language>> getLanguages(String cvId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getLanguage/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Language.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch languages: ${response.body}');
    }
  }

  Future<void> addLanguage(Language language, String token) async {
    final url = Uri.parse('$baseUrl/cv/addLanguage'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(language.toJson())}');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(language.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add language: ${response.body}');
    }
  }

  Future<void> updateLanguage(String id, Language language, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateLanguage/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(language.toJson())}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(language.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update language: ${response.body}');
    }
  }

  Future<void> deleteLanguage(String id, String token) async {
    final url = Uri.parse('$baseUrl/cv/deleteLanguage/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete language: ${response.body}');
    }
  }

  Future<List<Project>> getProjects(String cvId, String token) async {
    final url = Uri.parse('$baseUrl/cv/getProject/$cvId');
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Project.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch projects: ${response.body}');
    }
  }

  Future<void> addProject(Project project, String token) async {
    final url = Uri.parse('$baseUrl/cv/addProj'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(project.toJson())}');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(project.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to add project: ${response.body}');
    }
  }

  Future<void> updateProject(String id, Project project, String token) async {
    final url = Uri.parse('$baseUrl/cv/updateProject/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"}');
    print('Request body: ${jsonEncode(project.toJson())}');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(project.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to update project: ${response.body}');
    }
  }

  Future<void> deleteProject(String id, String token) async {
    final url = Uri.parse('$baseUrl/cv/deleteProject/$id'); // Added /cv segment
    print('Requesting URL: $url');
    print('Headers: {"Authorization": "Bearer $token"}');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete project: ${response.body}');
    }
  }
}