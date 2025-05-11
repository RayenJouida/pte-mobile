import 'package:pte_mobile/models/user.dart';

class Leave {
  final String id;
  final User applicant;
  final String fullName;
  final String email;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final String? note;
  final String? code;
  final String? status;
  final User? supervisor;
  final bool? managerAccepted;
  final bool? supervisorAccepted;

  Leave({
    required this.id,
    required this.applicant,
    required this.fullName,
    required this.email,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.note,
    this.code,
    this.status,
    this.supervisor,
    this.managerAccepted,
    this.supervisorAccepted,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['_id'] ?? '',
      applicant: _parseUser(json['applicant']),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: json['type'] ?? '',
      note: json['note'],
      code: json['code'],
      status: json['status'],
      supervisor: json['supervisor'] != null ? _parseUser(json['supervisor']) : null,
      managerAccepted: json['managerAccepted'],
      supervisorAccepted: json['supervisorAccepted'],
    );
  }

  static User _parseUser(dynamic userData) {
    if (userData == null) {
      throw Exception('User data cannot be null');
    }
    if (userData is Map<String, dynamic>) {
      return User.fromJson(userData);
    }
    throw Exception('Invalid User data: $userData');
  }

  @override
  String toString() {
    return 'Leave{id: $id, applicant: $applicant, fullName: $fullName, email: $email, startDate: $startDate, endDate: $endDate, type: $type, note: $note, code: $code, status: $status, supervisor: $supervisor, managerAccepted: $managerAccepted, supervisorAccepted: $supervisorAccepted}';
  }
}