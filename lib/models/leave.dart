import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/config/env.dart'; // Ensure Env is imported

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
  final String? certif; // Full URL or filename
  final DateTime localCreationTime; // New field for sorting

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
    this.certif,
    DateTime? localCreationTime, // Optional for manual override
  }) : localCreationTime = localCreationTime ?? DateTime.now(); // Default to now if not provided

  factory Leave.fromJson(Map<String, dynamic> json) {
    print('Parsing leave from JSON: $json'); // Log full JSON for debugging
    print('Parsing certif from JSON: ${json['certif']}');
    
    String? certifUrl = json['certif'];
    if (certifUrl != null && !certifUrl.startsWith('http')) {
      certifUrl = '${Env.certBaseUrl}$certifUrl';
    }

    // Handle applicant as ID or user object
    final applicantData = json['applicant'];
    User applicant = _parseUser(applicantData);

    // Handle supervisor as ID or user object
    final supervisorData = json['supervisor'];
    User? supervisor = supervisorData != null ? _parseUser(supervisorData) : null;

    return Leave(
      id: json['_id'] ?? '',
      applicant: applicant,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      type: json['type'] ?? '',
      note: json['note'],
      code: json['code'],
      status: json['status'],
      supervisor: supervisor,
      managerAccepted: json['managerAccepted'],
      supervisorAccepted: json['supervisorAccepted'],
      certif: certifUrl,
      localCreationTime: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static User _parseUser(dynamic userData) {
    if (userData == null) {
      print('Warning: User data is null, using placeholder');
      return User(
        id: 'unknown',
        matricule: '',
        firstName: 'Unknown',
        lastName: '',
        email: '',
        roles: [],
        isEnabled: 'Inactive', // Default value for required field
        experience: 0,         // Default value for required field
      );
    }
    if (userData is Map<String, dynamic>) {
      return User.fromJson(userData);
    } else if (userData is String) {
      print('Warning: User data is ID string ($userData), creating minimal User');
      return User(
        id: userData,
        matricule: '',
        firstName: 'Unknown',
        lastName: '',
        email: '',
        roles: [],
        isEnabled: 'Inactive', // Default value for required field
        experience: 0,         // Default value for required field
      );
    }
    throw Exception('Invalid User data: $userData (type: ${userData.runtimeType})');
  }

  // Add copyWith method
  Leave copyWith({
    String? id,
    User? applicant,
    String? fullName,
    String? email,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    String? note,
    String? code,
    String? status,
    User? supervisor,
    bool? managerAccepted,
    bool? supervisorAccepted,
    String? certif,
    DateTime? localCreationTime,
  }) {
    return Leave(
      id: id ?? this.id,
      applicant: applicant ?? this.applicant,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      note: note ?? this.note,
      code: code ?? this.code,
      status: status ?? this.status,
      supervisor: supervisor ?? this.supervisor,
      managerAccepted: managerAccepted ?? this.managerAccepted,
      supervisorAccepted: supervisorAccepted ?? this.supervisorAccepted,
      certif: certif ?? this.certif,
      localCreationTime: localCreationTime ?? this.localCreationTime,
    );
  }

  @override
  String toString() {
    return 'Leave{id: $id, applicant: $applicant, fullName: $fullName, email: $email, startDate: $startDate, endDate: $endDate, type: $type, note: $note, code: $code, status: $status, supervisor: $supervisor, managerAccepted: $managerAccepted, supervisorAccepted: $supervisorAccepted, certif: $certif, localCreationTime: $localCreationTime}';
  }
}