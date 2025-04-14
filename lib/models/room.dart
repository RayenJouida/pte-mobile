class Room {
  final String id; // Make this optional
  final String label;
  final String location;
  final String capacity;

  Room({
    this.id = '', // Default to an empty string or null
    required this.label,
    required this.location,
    required this.capacity,
  });

  // Factory method to create a Room object from JSON
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'], // Assuming your backend uses '_id' for the room ID
      label: json['label'],
      location: json['location'],
      capacity: json['capacity'],
    );
  }

  // Method to convert a Room object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'label': label,
      'location': location,
      'capacity': capacity,
    };
  }
}