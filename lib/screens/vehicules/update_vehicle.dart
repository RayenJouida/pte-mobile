import 'package:flutter/material.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/screens/vehicules/all_vehicles.dart';
import 'package:flutter_animate/flutter_animate.dart';

class UpdateVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  const UpdateVehicleScreen({Key? key, required this.vehicle}) : super(key: key);

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
      if (widget.vehicle.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle ID is missing. Cannot update vehicle.')),
        );
        return;
      }

      final updatedVehicle = Vehicle(
        id: widget.vehicle.id,
        model: _modelController.text,
        registrationNumber: _registrationController.text,
        type: _typeController.text,
        userId: widget.vehicle.userId,
        log: widget.vehicle.log,
        kmTotal: widget.vehicle.kmTotal,
        available: widget.vehicle.available,
      );

      try {
        await _vehicleService.updateVehicle(widget.vehicle.id!, updatedVehicle);
        _showSuccessDialog(context);
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AllVehiclesScreen()),
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vehicle: $e')),
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
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
  void dispose() {
    _modelController.dispose();
    _registrationController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            decoration: const BoxDecoration(
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
                          builder: (context) => AllVehiclesScreen(),
                        ),
                      );
                    },
                    tooltip: 'Back to All Vehicles',
                  ),
                  Text(
                    'Update Vehicle',
                    style: const TextStyle(
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
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFloatingCard(
                            controller: _modelController,
                            label: 'Model',
                            icon: Icons.directions_car,
                            validator: (value) {
                              if ( value == null || value.isEmpty) {
                                return 'Please enter the model';
                              }
                              return null;
                            },
                          ).animate().fadeIn(duration: 500.ms).slideX(delay: 300.ms),
                          const SizedBox(width: 16),
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
                          const SizedBox(width: 16),
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
                    const SizedBox(height: 40),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0632A1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update Vehicle',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0632A1), size: 30),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              style: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
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