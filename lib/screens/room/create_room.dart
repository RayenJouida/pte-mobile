import 'package:flutter/material.dart';
import 'package:pte_mobile/models/room.dart'; // Import your Room model
import 'package:pte_mobile/services/room_service.dart'; // Import your RoomService
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class CreateRoomScreen extends StatefulWidget {
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoomService _roomService = RoomService();

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  Future<void> _createRoom() async {
    if (_formKey.currentState!.validate()) {
      final room = Room(
        label: _labelController.text,
        location: _locationController.text,
        capacity: _capacityController.text,
      );

      try {
        await _roomService.addRoom(room);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room created successfully')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Upper Section (Primary Color)
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Text(
                'Create Room',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),

          // Lower Section (White Background)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Label Field
                    _buildCard(
                      child: TextFormField(
                        controller: _labelController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Label',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.meeting_room, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the label';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                    SizedBox(height: 16),

                    // Location Field
                    _buildCard(
                      child: TextFormField(
                        controller: _locationController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.location_on, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the location';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                    SizedBox(height: 16),

                    // Capacity Field
                    _buildCard(
                      child: TextFormField(
                        controller: _capacityController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Capacity',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.people, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the capacity';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                    SizedBox(height: 24),

                    // Submit Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createRoom,
                        child: Text(
                          'Create Room',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white, // Set font color to white
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0632A1), // Button background color
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Widget
  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}