import 'package:flutter/material.dart';
import 'package:pte_mobile/models/room.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/screens/room/all_rooms.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UpdateRoomScreen extends StatefulWidget {
  final Room room;

  UpdateRoomScreen({required this.room});

  @override
  _UpdateRoomScreenState createState() => _UpdateRoomScreenState();
}

class _UpdateRoomScreenState extends State<UpdateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final RoomService _roomService = RoomService();

  late TextEditingController _labelController;
  late TextEditingController _locationController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.room.label);
    _locationController = TextEditingController(text: widget.room.location);
    _capacityController = TextEditingController(text: widget.room.capacity);
  }

  Future<void> _updateRoom() async {
    if (_formKey.currentState!.validate()) {
      final updatedRoom = Room(
        id: widget.room.id,
        label: _labelController.text,
        location: _locationController.text,
        capacity: _capacityController.text,
      );

      try {
        await _roomService.editRoom(updatedRoom.id, updatedRoom);

        _showSuccessDialog(context);

        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AllRoomsScreen(),
            ),
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update room: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Room Updated Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllRoomsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Back to All Rooms',
                  ),
                  Text(
                    'Update Room',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
                  SizedBox(width: 48), // Spacer for balance
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFloatingCard(
                            controller: _labelController,
                            label: 'Label',
                            icon: Icons.meeting_room,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the label';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 300.ms),
                          SizedBox(width: 16),
                          _buildFloatingCard(
                            controller: _locationController,
                            label: 'Location',
                            icon: Icons.location_on,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the location';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 400.ms),
                          SizedBox(width: 16),
                          _buildFloatingCard(
                            controller: _capacityController,
                            label: 'Capacity',
                            icon: Icons.people,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the capacity';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 500.ms),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateRoom,
                        child: Text(
                          'Update Room',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0632A1),
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

  Widget _buildFloatingCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xFF0632A1), size: 30),
            SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: controller,
              style: TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
              validator: validator,
            ),
          ],
        ),
      ),
    );
  }
}