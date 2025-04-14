class Vehicle {
  final String? id;
  final String? model;
  final String? registrationNumber;
  final String? type;
  final String? userId;

  Vehicle({
    this.id,
    this.model,
    this.registrationNumber,
    this.type,
    this.userId,
  });

  // Convert from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] as String?,
      model: json['model'] as String?,
      registrationNumber: json['registration_number'] as String?,
      type: json['type'] as String?,
      userId: json['user'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'registration_number': registrationNumber,
      'type': type,
      'user': userId,
    };
  }
}
