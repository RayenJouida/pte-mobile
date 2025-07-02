class VirtualizationEnv {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String departement;
  final String code;
  final String type;
  final bool backup;
  final String ram;
  final String disk;
  final String processor;
  final bool dhcp;
  final DateTime start;
  final DateTime end;
  final String goals;
  final String status;
  final bool isAccepted;
  final String applicantId;
  DateTime? localCreationTime;

  VirtualizationEnv({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.departement,
    required this.code,
    required this.type,
    required this.backup,
    required this.ram,
    required this.disk,
    required this.processor,
    required this.dhcp,
    required this.start,
    required this.end,
    required this.goals,
    required this.status,
    required this.isAccepted,
    required this.applicantId,
    this.localCreationTime,
  });

  factory VirtualizationEnv.fromJson(Map<String, dynamic> json) {
    final applicant = json['applicant'];
    final applicantId = applicant is String 
        ? applicant 
        : (applicant is Map ? applicant['_id']?.toString() ?? '' : '');
    return VirtualizationEnv(
      id: json['_id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      departement: json['departement']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      backup: json['backup'] ?? false,
      ram: json['ram']?.toString() ?? '',
      disk: json['disk']?.toString() ?? '',
      processor: json['processor']?.toString() ?? '',
      dhcp: json['dhcp'] ?? false,
      start: json['start'] != null ? DateTime.parse(json['start']) : DateTime.now(),
      end: json['end'] != null ? DateTime.parse(json['end']) : DateTime.now(),
      goals: json['goals']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      isAccepted: json['isAccepted'] ?? false,
      applicantId: applicantId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'departement': departement,
      'code': code,
      'type': type,
      'backup': backup,
      'ram': ram,
      'disk': disk,
      'processor': processor,
      'dhcp': dhcp,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'goals': goals,
      'status': status,
      'isAccepted': isAccepted,
      'applicant': applicantId,
    };
  }

  VirtualizationEnv copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? departement,
    String? code,
    String? type,
    bool? backup,
    String? ram,
    String? disk,
    String? processor,
    bool? dhcp,
    DateTime? start,
    DateTime? end,
    String? goals,
    String? status,
    bool? isAccepted,
    String? applicantId,
    DateTime? localCreationTime,
  }) {
    return VirtualizationEnv(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      departement: departement ?? this.departement,
      code: code ?? this.code,
      type: type ?? this.type,
      backup: backup ?? this.backup,
      ram: ram ?? this.ram,
      disk: disk ?? this.disk,
      processor: processor ?? this.processor,
      dhcp: dhcp ?? this.dhcp,
      start: start ?? this.start,
      end: end ?? this.end,
      goals: goals ?? this.goals,
      status: status ?? this.status,
      isAccepted: isAccepted ?? this.isAccepted,
      applicantId: applicantId ?? this.applicantId,
      localCreationTime: localCreationTime ?? this.localCreationTime,
    );
  }
}