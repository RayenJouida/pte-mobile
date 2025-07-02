import 'package:flutter/material.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateVehicleScreen extends StatefulWidget {
  const CreateVehicleScreen({Key? key}) : super(key: key);

  @override
  _CreateVehicleScreenState createState() => _CreateVehicleScreenState();
}

class _CreateVehicleScreenState extends State<CreateVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final VehicleService _vehicleService = VehicleService();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  String? _type;

  Future<void> _createVehicle() async {
    if (_formKey.currentState!.validate() && _type != null) {
      final vehicle = Vehicle(
        model: _modelController.text,
        registrationNumber: _registrationController.text,
        type: _type,
      );

      try {
        await _vehicleService.addVehicle(vehicle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle created successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create vehicle: $e')),
        );
      }
    } else if (_type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle type')),
      );
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _registrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: const BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Center(
              child: Text(
                'Create Vehicle',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(delay: 200.ms),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCard(
                      child: TextFormField(
                        controller: _modelController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    _buildCard(
                      child: TextFormField(
                        controller: _registrationController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Type',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _type = 'Commercial'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _type == 'Commercial'
                                        ? const Color(0xFF0632A1)
                                        : Colors.grey[300],
                                    foregroundColor: _type == 'Commercial' ? Colors.white : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Commercial'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _type = 'Civil'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _type == 'Civil'
                                        ? const Color(0xFF0632A1)
                                        : Colors.grey[300],
                                    foregroundColor: _type == 'Civil' ? Colors.white : Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Civil'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(delay: 500.ms),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0632A1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Vehicle',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}