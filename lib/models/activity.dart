import 'package:flutter/material.dart';

class Activity {
  final String id;
  final String type;
  final Map<String, dynamic> actor; // { _id, firstName, lastName, image }
  final String targetUser;
  final Map<String, dynamic>? post; // { _id, description }
  final Map<String, dynamic>? comment; // { _id, text }
  final String? like; // Like ID
  final bool read;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.type,
    required this.actor,
    required this.targetUser,
    this.post,
    this.comment,
    this.like,
    required this.read,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    debugPrint('Activity JSON: $json');
    return Activity(
      id: json['_id'] as String,
      type: json['type'] as String,
      actor: json['actor'] as Map<String, dynamic>,
      targetUser: json['targetUser'] as String,
      post: json['post'] as Map<String, dynamic>?,
      comment: json['comment'] as Map<String, dynamic>?,
      like: json['like'] as String?,
      read: json['read'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}