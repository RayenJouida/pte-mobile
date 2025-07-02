import 'package:flutter/foundation.dart';
import '../identifiable.dart';

class Education implements Identifiable {
  @override
  final String id;
  final String cvId;
  final String establishment;
  final String section;
  final String diploma;
  final DateTime yearStart;
  final DateTime? yearEnd;
  final bool present;

  Education({
    required this.id,
    required this.cvId,
    required this.establishment,
    required this.section,
    required this.diploma,
    required this.yearStart,
    this.yearEnd,
    required this.present,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        debugPrint('Failed to parse date: $value');
        return null;
      }
    }

    return Education(
      id: json['_id']?.toString() ?? '',
      cvId: json['cv']?.toString() ?? '',
      establishment: json['establishment']?.toString() ?? '',
      section: json['section']?.toString() ?? '',
      diploma: json['diploma']?.toString() ?? '',
      yearStart: _parseDate(json['year_start']) ?? DateTime.now(),
      yearEnd: _parseDate(json['year_end']),
      present: json['present'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cv': cvId,
      'establishment': establishment,
      'section': section,
      'diploma': diploma,
      'year_start': yearStart.toIso8601String(),
      'year_end': yearEnd?.toIso8601String(),
      'present': present,
    };
  }
}