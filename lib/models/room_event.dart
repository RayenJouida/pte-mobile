class RoomEvent {
  final String? id; // Optional, as the backend generates it
  final String title;
  final DateTime start;
  final DateTime end;
  final String roomId; // Use roomId instead of room object for simplicity
  final String applicantId; // Use applicantId instead of applicant object for simplicity
  final bool isAccepted;

  RoomEvent({
    this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.roomId,
    required this.applicantId,
    this.isAccepted = true, // Default value is true
  });

  // Convert from JSON
  factory RoomEvent.fromJson(Map<String, dynamic> json) {
    return RoomEvent(
      id: json['_id'] as String?, // Extract the event ID
      title: json['title'] as String,
      start: DateTime.parse(json['start']), // Parse ISO 8601 string to DateTime
      end: DateTime.parse(json['end']), // Parse ISO 8601 string to DateTime
      roomId: json['room'] is String
          ? json['room'] as String // Flat structure (for create event response)
          : json['room']['_id'] as String, // Nested structure (for fetch events response)
      applicantId: json['applicant'] is String
          ? json['applicant'] as String // Flat structure (for create event response)
          : json['applicant']['_id'] as String, // Nested structure (for fetch events response)
      isAccepted: json['isAccepted'] ?? true, // Default to true if not provided
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'room': roomId,
      'applicant': applicantId,
      'isAccepted': isAccepted,
    };
  }
}