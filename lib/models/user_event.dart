class UserEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String engineer; // Changed from User to String
  final String job;
  final String address;
  final String applicant; // Changed from User to String
  final bool isAccepted;

  UserEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.engineer,
    required this.job,
    required this.address,
    required this.applicant,
    required this.isAccepted,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    return UserEvent(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      start: DateTime.parse(json['start'] ?? DateTime.now().toIso8601String()),
      end: DateTime.parse(json['end'] ?? DateTime.now().toIso8601String()),
      engineer: json['engineer']?.toString() ?? '', // Store as String
      job: json['job'] ?? '',
      address: json['address'] ?? '',
      applicant: json['applicant']?.toString() ?? '', // Store as String
      isAccepted: json['isAccepted'] ?? false,
    );
  }
}