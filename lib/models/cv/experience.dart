import 'package:flutter/foundation.dart';
import '../identifiable.dart';

class Experience implements Identifiable {
  @override
  final String id;
  final String cvId;
  final String company;
  final String job;
  final String taskDescription;
  final DateTime start;
  final DateTime? end;
  final bool present;

  Experience({
    required this.id,
    required this.cvId,
    required this.company,
    required this.job,
    required this.taskDescription,
    required this.start,
    this.end,
    required this.present,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        debugPrint('Failed to parse date: $value');
        return null;
      }
    }

    return Experience(
      id: json['_id']?.toString() ?? '',
      cvId: json['cv']?.toString() ?? '',
      company: json['company']?.toString() ?? '',
      job: json['job']?.toString() ?? '',
      taskDescription: json['task_description']?.toString() ?? '',
      start: _parseDate(json['start']) ?? DateTime.now(),
      end: _parseDate(json['end']),
      present: json['present'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cv': cvId,
      'company': company,
      'job': job,
      'task_description': taskDescription,
      'start': start.toIso8601String(),
      'end': end?.toIso8601String(),
      'present': present,
    };
  }
}