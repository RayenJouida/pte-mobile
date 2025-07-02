import 'package:flutter/foundation.dart';
import '../identifiable.dart';

class Skill implements Identifiable {
  @override
  final String id;
  final String cvId;
  final String name;
  final int level;

  Skill({
    required this.id,
    required this.cvId,
    required this.name,
    required this.level,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
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