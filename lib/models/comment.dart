import 'package:flutter/foundation.dart';
import 'user.dart'; // Make sure this import path is correct

class Comment {
  final String id;
  final String text;
  final User user;
  final DateTime createdAt;
  final String postId;

  Comment({
    required this.id,
    required this.text,
    required this.user,
    required this.createdAt,
    required this.postId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      return Comment(
        id: json['_id']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        user: User.fromJson(json['user'] is String 
            ? {'_id': json['user']} 
            : json['user'] ?? {}),
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        postId: (json['post'] is Map ? json['post']['_id'] : json['post'])?.toString() ?? '',
      );
    } catch (e, stack) {
      debugPrint('Error parsing Comment JSON: $e');
      debugPrint('Stack trace: $stack');
      debugPrint('Problematic JSON: ${json.toString()}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'text': text,
      'user': user.id, // Only store user ID for serialization
      'createdAt': createdAt.toIso8601String(),
      'post': postId,
    };
  }

  @override
  String toString() {
    return 'Comment(id: $id, user: ${user.id}, text: ${text.length > 20 ? '${text.substring(0, 20)}...' : text})';
  }
}