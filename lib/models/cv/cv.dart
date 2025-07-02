// lib/models/cv/cv.dart
import 'package:flutter/foundation.dart';

class Cv {
  final String id;
  final String userId;
  final String summary;
  final List<String> educationIds;
  final List<String> experienceIds;
  final List<String> certificationIds;
  final List<String> projectIds;
  final List<String> skillIds;
  final List<String> languageIds;

  Cv({
    required this.id,
    required this.userId,
    required this.summary,
    required this.educationIds,
    required this.experienceIds,
    required this.certificationIds,
    required this.projectIds,
    required this.skillIds,
    required this.languageIds,
  });

  factory Cv.fromJson(Map<String, dynamic> json) {
    return Cv(
      id: json['_id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      educationIds: (json['education'] as List<dynamic>?)?.cast<String>() ?? [],
      experienceIds: (json['experience'] as List<dynamic>?)?.cast<String>() ?? [],
      certificationIds: (json['certification'] as List<dynamic>?)?.cast<String>() ?? [],
      projectIds: (json['projet'] as List<dynamic>?)?.cast<String>() ?? [],
      skillIds: (json['skill'] as List<dynamic>?)?.cast<String>() ?? [],
      languageIds: (json['language'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'summary': summary,
      'education': educationIds,
      'experience': experienceIds,
      'certification': certificationIds,
      'projet': projectIds,
      'skill': skillIds,
      'language': languageIds,
    };
  }
}