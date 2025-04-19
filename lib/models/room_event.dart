class RoomEvent {
  final String? id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String roomId;
  final String applicantId;
  final bool isAccepted;
  final String? roomLabel;
  final String? applicantName;

  RoomEvent({
    this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.roomId,
    required this.applicantId,
    this.isAccepted = true,
    this.roomLabel,
    this.applicantName,
  });

  factory RoomEvent.fromJson(Map<String, dynamic> json) {
    final roomData = json['room'] is String
        ? {'_id': json['room']}
        : json['room'] as Map<String, dynamic>? ?? {'_id': json['room']};
    final applicantData = json['applicant'] is String
        ? {'_id': json['applicant']}
        : json['applicant'] as Map<String, dynamic>? ?? {'_id': json['applicant']};

    return RoomEvent(
      id: json['_id'] as String?,
      title: json['title'] as String,
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      roomId: roomData['_id'] as String,
      applicantId: applicantData['_id'] as String,
      isAccepted: json['isAccepted'] ?? true,
      roomLabel: roomData['label'] as String? ?? null,
      applicantName: applicantData['firstName'] != null && applicantData['lastName'] != null
          ? '${applicantData['firstName']} ${applicantData['lastName']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'room': roomId,
      'applicant': applicantId,
      'isAccepted': isAccepted,
    };
  }
}