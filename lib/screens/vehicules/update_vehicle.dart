import 'package:flutter/material.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/screens/vehicules/all_vehicles.dart'; // Import the AllVehiclesScreen
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class UpdateVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  UpdateVehicleScreen({required this.vehicle});

  @override
  _UpdateVehicleScreenState createState() => _UpdateVehicleScreenState();
}

class _UpdateVehicleScreenState extends State<UpdateVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();

  late TextEditingController _modelController;
  late TextEditingController _registrationController;
  late TextEditingController _typeController;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.vehicle.model);
    _registrationController = TextEditingController(text: widget.vehicle.registrationNumber);
    _typeController = TextEditingController(text: widget.vehicle.type);
  }

  Future<void> _updateVehicle() async {
    if (_formKey.currentState!.validate()) {
      final updatedVehicle = Vehicle(
        id: widget.vehicle.id,
        model: _modelController.text,
        registrationNumber: _registrationController.text,
        type: _typeController.text,
      );

      try {
        await _vehicleService.updateVehicle(updatedVehicle);

        // Show Sweet Alert
        _showSuccessDialog(context);

        // Redirect to AllVehiclesScreen after a delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AllVehiclesScreen(),
            ),
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vehicle: $e')),
        );
      }
    }
  }

  // Sweet Alert Dialog
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
              'Vehicle Updated Successfully!',
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
      backgroundColor: Color(0xFFF5F5F5), // Light gray background
      body: Column(
        children: [
          // Custom Header
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Center(
              child: Text(
                'Update Vehicle',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),

          // Floating Action Cards (Horizontal Scroll)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Horizontal Scroll for Input Fields
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Model Card
                          _buildFloatingCard(
                            controller: _modelController,
                            label: 'Model',
                            icon: Icons.directions_car,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the model';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 300.ms),
                          SizedBox(width: 16),

                          // Registration Number Card
                          _buildFloatingCard(
                            controller: _registrationController,
                            label: 'Registration Number',
                            icon: Icons.confirmation_number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the registration number';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 400.ms),
                          SizedBox(width: 16),

                          // Type Card
                          _buildFloatingCard(
                            controller: _typeController,
                            label: 'Type',
                            icon: Icons.category,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the type';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 500.ms),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),

                    // Update Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateVehicle,
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
          ),
        ],
      ),
    );
  }

  // Floating Card Widget
  Widget _buildFloatingCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Container(
      width: 200, // Fixed width for each card
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