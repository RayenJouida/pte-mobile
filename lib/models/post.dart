// lib/models/post.dart
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/models/like.dart';

class Post {
  final String id;
  final String description;
  final List<String> images;
  final User user;
  final DateTime date;
  final bool isAccepted;
  final String status;
  final List<Like> likes;

  Post({
    required this.id,
    required this.description,
    required this.images,
    required this.user,
    required this.date,
    this.isAccepted = false,
    this.status = "Pending",
    this.likes = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      user: User.fromJson(json['user'] ?? {}),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      isAccepted: json['isAccepted'] ?? false,
      status: json['status'] ?? 'Pending',
      likes: (json['likes'] as List<dynamic>?)
              ?.map((like) => Like.fromJson(like is String ? {'_id': like} : like))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'description': description,
      'images': images,
      'user': user.toJson(),
      'date': date.toIso8601String(),
      'isAccepted': isAccepted,
      'status': status,
      'likes': likes.map((like) => like.toJson()).toList(),
    };
  }
}