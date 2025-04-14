import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/screens/vehicules/create_vehicle.dart';
import 'package:pte_mobile/screens/vehicules/update_vehicle.dart';
import 'package:pte_mobile/screens/vehicules/vehicle_details.dart';
import 'package:pte_mobile/services/vehicle_service.dart';

class AllVehiclesScreen extends StatefulWidget {
  @override
  _AllVehiclesScreenState createState() => _AllVehiclesScreenState();
}

class _AllVehiclesScreenState extends State<AllVehiclesScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> _vehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = vehicles;
        _filteredVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load vehicles: $e')),
      );
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    try {
      await _vehicleService.deleteVehicle(vehicleId);
      setState(() {
        _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
        _filteredVehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehicle deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete vehicle: $e')),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredVehicles = _vehicles;
      }
    });
  }

  void _performSearch(String query) {
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        final model = vehicle.model?.toLowerCase() ?? '';
        final registration = vehicle.registrationNumber?.toLowerCase() ?? '';
        final type = vehicle.type?.toLowerCase() ?? '';
        return model.contains(query.toLowerCase()) ||
            registration.contains(query.toLowerCase()) ||
            type.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5), // Light gray background
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Model, Registration, or Type...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _performSearch,
              )
            : Text(
                'All Vehicles',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0632A1), Color(0xFF3D5AFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchVehicles,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateVehicleScreen(),
            ),
          ).then((_) => _fetchVehicles());
        },
        backgroundColor: Color(0xFF0632A1),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _filteredVehicles.isEmpty
              ? Center(child: Text('No vehicles found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _filteredVehicles[index];
                    return Dismissible(
                      key: Key(vehicle.id!), // Unique key for each item
                      direction: DismissDirection.endToStart, // Swipe from right to left
                      background: Container(
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20), // Match card border radius
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white, size: 30),
                      ),
                      confirmDismiss: (direction) async {
                        // Show a confirmation dialog with the vehicle's name
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Vehicle'),
                            content: Text('Are you sure you want to delete "${vehicle.model}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteVehicle(vehicle.id!); // Delete the vehicle
                      },
                      child: GestureDetector(
                        onDoubleTap: () {
                          // Navigate to VehicleDetailsScreen on double tap
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
                            ),
                          );
                        },
                        child: Container(
                          height: 150, // Uniform height for all cards
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3), // Translucent background
                            borderRadius: BorderRadius.circular(20), // Rounded corners
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur effect
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Model with icon
                                    Row(
                                      children: [
                                        Icon(Icons.directions_car, color: Color(0xFF0632A1), size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          vehicle.model ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0632A1),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Registration Number
                                    Text(
                                      'Registration: ${vehicle.registrationNumber ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold, // Bold label
                                        color: Colors.black87,
                                      ),
                                    ),
                                    // Type
                                    Text(
                                      'Type: ${vehicle.type ?? 'N/A'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold, // Bold label
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 150,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[300],
          ),
        );
      },
    );
  }
}