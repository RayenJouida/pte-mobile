import 'package:flutter/foundation.dart';
import '../identifiable.dart';

class Language implements Identifiable {
  @override
  final String id;
  final String cvId;
  final String name;
  final int level;

  Language({
    required this.id,
    required this.cvId,
    required this.name,
    required this.level,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['_id']?.toString() ?? '',
      cvId: json['cv']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'cv': cvId,
      'name': name,
      'level': level,
    };
  }
}