import 'package:flutter/material.dart';
import 'package:pte_mobile/models/room.dart'; // Import your Room model
import 'package:pte_mobile/screens/room/update_room.dart'; // Import the UpdateRoomScreen
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class RoomDetailsScreen extends StatelessWidget {
  final Room room;

  RoomDetailsScreen({required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // App Bar Section
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
                'Room Details',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),

          // Details Section
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label Card
                  _buildDetailCard(
                    icon: Icons.meeting_room,
                    label: 'Label',
                    value: room.label,
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                  SizedBox(height: 16),

                  // Location Card
                  _buildDetailCard(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: room.location,
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                  SizedBox(height: 16),

                  // Capacity Card
                  _buildDetailCard(
                    icon: Icons.people,
                    label: 'Capacity',
                    value: room.capacity,
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                  SizedBox(height: 24),

                  // Update Button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateRoomScreen(room: room),
                          ),
                        );
                      },
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
        ],
      ),
    );
  }

  // Card Widget for Details
  Widget _buildDetailCard({required IconData icon, required String label, required String value}) {
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
        child: Row(
          children: [
            Icon(icon, color: Color(0xFF0632A1), size: 24),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}