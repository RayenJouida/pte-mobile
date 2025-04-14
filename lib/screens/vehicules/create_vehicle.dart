import 'package:flutter/material.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class CreateVehicleScreen extends StatefulWidget {
  @override
  _CreateVehicleScreenState createState() => _CreateVehicleScreenState();
}

class _CreateVehicleScreenState extends State<CreateVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  Future<void> _createVehicle() async {
    if (_formKey.currentState!.validate()) {
      final vehicle = Vehicle(
        model: _modelController.text,
        registrationNumber: _registrationController.text,
        type: _typeController.text,
      );

      try {
        await _vehicleService.addVehicle(vehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle created successfully')),
        );
        Navigator.pop(context); // Go back to the previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create vehicle: $e')),
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
                'Create Vehicle',
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
                    // Model Field
                    _buildCard(
                      child: TextFormField(
                        controller: _modelController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Model',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.directions_car, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the model';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 300.ms),
                    SizedBox(height: 16),

                    // Registration Number Field
                    _buildCard(
                      child: TextFormField(
                        controller: _registrationController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Registration Number',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.confirmation_number, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the registration number';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 400.ms),
                    SizedBox(height: 16),

                    // Type Field
                    _buildCard(
                      child: TextFormField(
                        controller: _typeController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Type',
                          labelStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.category, color: Color(0xFF0632A1)),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the type';
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
                        onPressed: _createVehicle,
                        child: Text(
                          'Create Vehicle',
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