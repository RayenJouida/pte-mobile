class Vehicle {
  final String? id;
  final String? model;
  final String? registrationNumber;
  final String? type;
  final String? userId;
  final List<LogEntry>? log;
  final int? kmTotal;
  final bool? available;

  Vehicle({
    this.id,
    this.model,
    this.registrationNumber,
    this.type,
    this.userId,
    this.log,
    this.kmTotal,
    this.available,
  });

  // Convert from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['_id'] as String?,
      model: json['model'] as String?,
      registrationNumber: json['registration_number'] as String?,
      type: json['type'] as String?,
      userId: json['user'] != null ? json['user'].toString() : null,
      log: (json['log'] as List<dynamic>?)?.map((logItem) => LogEntry.fromJson(logItem)).toList(),
      kmTotal: json['kmTotal'] as int?,
      available: json['available'] as bool?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'model': model,
      'registration_number': registrationNumber,
      'type': type,
      'user': userId,
      'kmTotal': kmTotal,
      'available': available,
    };
  }
}

class LogEntry {
  final String? eventId;
  final int? kilometrage;
  final DateTime? reservationDate;

  LogEntry({
    this.eventId,
    this.kilometrage,
    this.reservationDate,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      eventId: json['event'] != null ? json['event'].toString() : null,
      kilometrage: json['kilometrage'] as int?,
      reservationDate: json['reservationDate'] != null ? DateTime.parse(json['reservationDate'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': eventId,
      'kilometrage': kilometrage,
      'reservationDate': reservationDate?.toIso8601String(),
    };
  }
}