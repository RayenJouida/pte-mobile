import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String? id;
  final String? senderId;
  final String? receiverId;
  final String? content;
  final DateTime? timestamp;
  final bool isSent;
  final bool read;

  Message({
    this.id,
    this.senderId,
    this.receiverId,
    this.content,
    this.timestamp,
    this.isSent = false,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] as String?,
      senderId: json['sender'] as String?,
      receiverId: json['receiver'] as String?,
      content: json['content'] as String?,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      isSent: json['isSent'] as bool? ?? false,
      read: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'sender': senderId,
      'receiver': receiverId,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
      'isSent': isSent,
      'read': read,
    };
  }

  @override
  List<Object?> get props => [id, senderId, receiverId, content, timestamp, isSent, read];
}