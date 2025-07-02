import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/screens/vehicules/create_vehicle.dart';
import 'package:pte_mobile/screens/vehicules/update_vehicle.dart';
import 'package:pte_mobile/screens/vehicules/vehicle_details.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AllVehiclesScreen extends StatefulWidget {
  final int? currentIndex;

  const AllVehiclesScreen({Key? key, this.currentIndex}) : super(key: key);

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
  String? _currentUserRole;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex ?? 0;
    _fetchCurrentUserRole();
    _fetchVehicles();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
    });
  }

  Future<void> _fetchVehicles() async {
    setState(() {
      _isLoading = true;
    });
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

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    _fetchVehicles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _currentUserRole == 'ADMIN'
          ? AdminSidebar(currentIndex: _currentIndex, onTabChange: _handleTabChange)
          : _currentUserRole == 'LAB-MANAGER'
              ? LabManagerSidebar(currentIndex: _currentIndex, onTabChange: _handleTabChange)
              : _currentUserRole == 'ENGINEER'
                  ? EngineerSidebar(currentIndex: _currentIndex, onTabChange: _handleTabChange)
                  : AssistantSidebar(currentIndex: _currentIndex, onTabChange: _handleTabChange),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0632A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'All Vehicles',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () {
                        showSearch(context: context, delegate: VehicleSearchDelegate(_vehicles));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchVehicles,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : _filteredVehicles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_car, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No vehicles available',
                              style: const TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchVehicles,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredVehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = _filteredVehicles[index];
                            return Dismissible(
                              key: Key(vehicle.id ?? index.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Vehicle'),
                                    content: Text('Are you sure you want to delete "${vehicle.model}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) {
                                if (vehicle.id != null) _deleteVehicle(vehicle.id!);
                              },
                              child: _buildVehicleCard(vehicle)
                                  .animate()
                                  .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                                  .slideY(begin: 0.1, delay: (50 * index).ms),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) =>  CreateVehicleScreen()),
          ).then((_) => _fetchVehicles());
        },
        backgroundColor: const Color(0xFF0632A1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsScreen(vehicle: vehicle),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vehicle.model ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateVehicleScreen(vehicle: vehicle),
                        ),
                      ).then((_) => _fetchVehicles());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    vehicle.registrationNumber ?? 'N/A',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    vehicle.type ?? 'N/A',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ).animate().shimmer(duration: 1000.ms);
      },
    );
  }
}

class VehicleSearchDelegate extends SearchDelegate {
  final List<Vehicle> vehicles;

  VehicleSearchDelegate(this.vehicles);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = vehicles.where((vehicle) {
      final model = vehicle.model?.toLowerCase() ?? '';
      final registration = vehicle.registrationNumber?.toLowerCase() ?? '';
      final type = vehicle.type?.toLowerCase() ?? '';
      return model.contains(query.toLowerCase()) ||
          registration.contains(query.toLowerCase()) ||
          type.contains(query.toLowerCase());
    }).toList();
    return _buildSearchResults(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }

  Widget _buildSearchResults(List<Vehicle> results) {
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final vehicle = results[index];
        return ListTile(
          title: Text(vehicle.model ?? 'N/A'),
          subtitle: Text(vehicle.registrationNumber ?? 'N/A'),
          onTap: () {
            close(context, vehicle);
          },
        );
      },
    );
  }
}