class VehicleEvent {
  final String? id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String vehicleId;
  final String driverId;
  final String destination;
  final String applicantId;

  VehicleEvent({
    this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.vehicleId,
    required this.driverId,
    required this.destination,
    required this.applicantId,
  });

  // Convert from JSON
factory VehicleEvent.fromJson(Map<String, dynamic> json) {
  return VehicleEvent(
    id: json['_id'] as String?, // Extract the event ID
    title: json['title'] as String,
    start: DateTime.parse(json['start']), // Parse ISO 8601 string to DateTime
    end: DateTime.parse(json['end']), // Parse ISO 8601 string to DateTime
    vehicleId: json['vehicle'] is String
        ? json['vehicle'] as String // Flat structure (for create event response)
        : json['vehicle']['_id'] as String, // Nested structure (for fetch events response)
    driverId: json['driver'] is String
        ? json['driver'] as String // Flat structure (for create event response)
        : json['driver']['_id'] as String, // Nested structure (for fetch events response)
    destination: json['destination'] as String,
    applicantId: json['applicant'] is String
        ? json['applicant'] as String // Flat structure (for create event response)
        : json['applicant']['_id'] as String, // Nested structure (for fetch events response)
  );
}
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'vehicle': vehicleId,
      'driver': driverId,
      'destination': destination,
      'applicant': applicantId,
    };
  }
}