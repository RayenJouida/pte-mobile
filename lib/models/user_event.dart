import 'package:intl/intl.dart';

class UserEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String engineer;
  final String applicant;
  final String job;
  final String address;
  final bool isAccepted;

  UserEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.engineer,
    required this.applicant,
    required this.job,
    required this.address,
    required this.isAccepted,
  });

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    return UserEvent(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      start: DateTime.parse(json['start']?.toString() ?? DateTime.now().toIso8601String()),
      end: DateTime.parse(json['end']?.toString() ?? DateTime.now().toIso8601String()),
      engineer: json['engineer']?.toString() ?? '',
      applicant: json['applicant']?.toString() ?? '',
      job: json['job']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isAccepted: json['isAccepted'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'engineer': engineer,
      'applicant': applicant,
      'job': job,
      'address': address,
      'isAccepted': isAccepted,
    };
  }
}