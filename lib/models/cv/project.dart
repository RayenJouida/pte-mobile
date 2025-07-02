import 'package:flutter/foundation.dart';
import '../identifiable.dart';

class Project implements Identifiable {
  @override
  final String id;
  final String cvId;
  final String organization;
  final String title;
  final String description;
  final DateTime date;

  Project({
    required this.id,
    required this.cvId,
    required this.organization,
    required this.title,
    required this.description,
    required this.date,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        debugPrint('Failed to parse date: $value');
        return DateTime.now();
      }
    }

    return Project(
      id: json['_id']?.toString() ?? '',
      cvId: json['cv']?.toString() ?? '',
      organization: json['organization']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cv': cvId,
      'organization': organization,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}