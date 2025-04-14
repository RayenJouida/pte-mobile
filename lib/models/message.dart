class Message {
  final String? id; // Make fields nullable
  final String? senderId;
  final String? receiverId;
  final String? content;
  final DateTime? timestamp;
  final bool isSent; // Add isSent field to track sent messages

  Message({
    this.id,
    this.senderId,
    this.receiverId,
    this.content,
    this.timestamp,
    this.isSent = false, // Default value is false (message is not sent)
  });

factory Message.fromJson(Map<String, dynamic> json) {
  return Message(
    id: json['_id'] as String?,
    senderId: json['sender'] as String?,
    receiverId: json['receiver'] as String?,
    content: json['content'] as String?,
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    isSent: json['isSent'] as bool? ?? false,  // Ensure a default value of false if not provided
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
      'isSent': isSent, // Add isSent to JSON
    };
  }
}
