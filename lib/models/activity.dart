import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Activity extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> actor;
  final String? targetUser;
  final Map<String, dynamic>? post;
  final Map<String, dynamic>? comment;
  final String? like;
  final Map<String, dynamic>? leave;
  final bool read;
  final DateTime timestamp;

  Activity({
    required this.id,
    required this.type,
    required this.actor,
    this.targetUser,
    this.post,
    this.comment,
    this.like,
    this.leave,
    required this.read,
    required this.timestamp,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    debugPrint('Activity JSON: $json');
    return Activity(
      id: json['_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      actor: json['actor'] as Map<String, dynamic>? ?? {},
      targetUser: json['targetUser']?.toString(),
      post: json['post'] as Map<String, dynamic>?,
      comment: json['comment'] as Map<String, dynamic>?,
      like: json['like']?.toString(),
      leave: json['leave'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'actor': actor,
      'targetUser': targetUser,
      'post': post,
      'comment': comment,
      'like': like,
      'leave': leave,
      'read': read,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  Activity copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? actor,
    String? targetUser,
    Map<String, dynamic>? post,
    Map<String, dynamic>? comment,
    String? like,
    Map<String, dynamic>? leave,
    bool? read,
    DateTime? timestamp,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      actor: actor ?? this.actor,
      targetUser: targetUser ?? this.targetUser,
      post: post ?? this.post,
      comment: comment ?? this.comment,
      like: like ?? this.like,
      leave: leave ?? this.leave,
      read: read ?? this.read,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, type, actor, targetUser, post, comment, like, leave, read, timestamp];
}