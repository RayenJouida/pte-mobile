import 'package:flutter/foundation.dart';
import '../identifiable.dart';

class Certification implements Identifiable {
  @override
  final String id;
  final String cvId;
  final String domaine;
  final String credential;
  final DateTime date;
  final String? certFile;

  Certification({
    required this.id,
    required this.cvId,
    required this.domaine,
    required this.credential,
    required this.date,
    this.certFile,
  });

  factory Certification.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        debugPrint('Failed to parse date: $value');
        return DateTime.now();
      }
    }

    return Certification(
      id: json['_id']?.toString() ?? '',
      cvId: json['cv']?.toString() ?? '',
      domaine: json['domaine']?.toString() ?? '',
      credential: json['credential']?.toString() ?? '',
      date: _parseDate(json['date']) ?? DateTime.now(),
      certFile: json['cert_file']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cv': cvId,
      'domaine': domaine,
      'credential': credential,
      'date': date.toIso8601String(),
      'cert_file': certFile,
    };
  }
}