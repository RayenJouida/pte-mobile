import 'package:flutter/material.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/screens/vehicules/update_vehicle.dart';
import 'package:pte_mobile/screens/vehicules/all_vehicles.dart'; // Import AllVehiclesScreen
import 'package:flutter_animate/flutter_animate.dart';

class VehicleDetailsScreen extends StatelessWidget {
  final Vehicle vehicle;

  VehicleDetailsScreen({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
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
                          builder: (context) => AllVehiclesScreen(),
                        ),
                      );
                    },
                    tooltip: 'Back to All Vehicles',
                  ),
                  Text(
                    'Vehicle Details',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard(
                    icon: Icons.directions_car,
                    label: 'Model',
                    value: vehicle.model ?? 'N/A',
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                  SizedBox(height: 16),
                  _buildDetailCard(
                    icon: Icons.confirmation_number,
                    label: 'Registration Number',
                    value: vehicle.registrationNumber ?? 'N/A',
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                  SizedBox(height: 16),
                  _buildDetailCard(
                    icon: Icons.category,
                    label: 'Type',
                    value: vehicle.type ?? 'N/A',
                  ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateVehicleScreen(vehicle: vehicle),
                          ),
                        );
                      },
                      child: Text(
                        'Update Vehicle',
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