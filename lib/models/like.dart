// lib/models/like.dart
import 'package:flutter/foundation.dart';
import 'package:pte_mobile/models/user.dart';

class Like {
  final String id;
  final User user;
  final String post;
  final DateTime createdAt;
  final DateTime updatedAt;

  Like({
    required this.id,
    required this.user,
    required this.post,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    try {
      return Like(
        id: json['_id']?.toString() ?? '',
        user: User.fromJson(json['user'] is String
            ? {'_id': json['user']}
            : json['user'] ?? {}),
        post: json['post']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'].toString())
            : DateTime.now(),
      );
    } catch (e, stack) {
      debugPrint('Error parsing Like JSON: $e');
      debugPrint('Stack trace: $stack');
      debugPrint('Problematic JSON: ${json.toString()}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user.id, // Only store user ID for serialization
      'post': post,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Like(id: $id, user: ${user.id}, post: $post)';
  }
}