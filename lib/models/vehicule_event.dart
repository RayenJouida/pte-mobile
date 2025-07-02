class VehicleEvent {
  final String? id;
  final String? title;
  final DateTime? start;
  final DateTime? end;
  final String? vehicleId;
  final String? driverId;
  final String? destination;
  final String? applicantId;
  final bool? isAccepted;
  final String? caseNumber;
  final int? km;
  final String? departure;
  final String? driverFirstName;
  final String? driverLastName;
  final String? driverImage;
  final String? applicantFirstName;
  final String? applicantLastName;
  final String? applicantImage;

  VehicleEvent({
    this.id,
    this.title,
    this.start,
    this.end,
    this.vehicleId,
    this.driverId,
    this.destination,
    this.applicantId,
    this.isAccepted,
    this.caseNumber,
    this.km,
    this.departure,
    this.driverFirstName,
    this.driverLastName,
    this.driverImage,
    this.applicantFirstName,
    this.applicantLastName,
    this.applicantImage,
  });

factory VehicleEvent.fromJson(Map<String, dynamic> json) {
  // Safely extract IDs (handles both String and Object cases)
  dynamic vehicle = json['vehicle'];
  String? vehicleId = (vehicle is String) ? vehicle : vehicle?['_id']?.toString();

  dynamic driver = json['driver'];
  String? driverId = (driver is String) ? driver : driver?['_id']?.toString();
  
  dynamic applicant = json['applicant'];
  String? applicantId = (applicant is String) ? applicant : applicant?['_id']?.toString();

  return VehicleEvent(
    id: json['_id']?.toString(),
    title: json['title']?.toString(),
    start: json['start'] != null ? DateTime.tryParse(json['start'].toString()) : null, // Use tryParse
    end: json['end'] != null ? DateTime.tryParse(json['end'].toString()) : null,
    vehicleId: vehicleId,
    driverId: driverId,
    applicantId: applicantId,
    destination: json['destination']?.toString(),
    km: (json['km'] is int) ? json['km'] : int.tryParse(json['km']?.toString() ?? '0') ?? 0, // Default to 0
    departure: json['departure']?.toString(),
    isAccepted: json['isAccepted'] as bool? ?? false, // Default to false
    caseNumber: json['caseNumber']?.toString(),
    // Driver/applicant details (optional)
    driverFirstName: (driver is Map) ? driver['firstName']?.toString() : null,
    driverLastName: (driver is Map) ? driver['lastName']?.toString() : null,
    driverImage: (driver is Map) ? driver['image']?.toString() : null,
  );
}

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start': start?.toIso8601String(),
      'end': end?.toIso8601String(),
      'vehicle': vehicleId,
      'driver': driverId,
      'destination': destination,
      'applicant': applicantId,
      'caseNumber': caseNumber,
      'km': km,
      'departure': departure,
      'isAccepted': isAccepted,
    };
  }
}