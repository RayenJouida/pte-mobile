import 'package:flutter/material.dart';
import 'package:pte_mobile/services/vehicle_service.dart';
import 'package:pte_mobile/models/vehicle.dart';
import 'package:pte_mobile/models/vehicule_event.dart';
import 'package:pte_mobile/widgets/assistant_navbar.dart';
import 'reservation_calendar_screen.dart';
import 'all_vehicles.dart';

class HomeVehicScreen extends StatefulWidget {
  @override
  _HomeVehicScreenState createState() => _HomeVehicScreenState();
}

class _HomeVehicScreenState extends State<HomeVehicScreen> {
  final VehicleService _vehicleService = VehicleService();
  int totalVehicles = 0;
  int availableVehicles = 0;
  int reservedVehicles = 0;
  int upcomingReservations = 0;
  bool isLoading = true;
  int _currentIndex = 1; // Index 1 for Vehicle tab

  void _onTabChange(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchVehicleStats();
  }

  Future<void> _fetchVehicleStats() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      final reservations = await _vehicleService.getAllEvents();
      final now = DateTime.now();
      final upcoming = reservations.where((reservation) => reservation.start.isAfter(now)).toList();

      setState(() {
        totalVehicles = vehicles.length;
        availableVehicles = vehicles.where((vehicle) => _isVehicleAvailable(vehicle, reservations)).length;
        reservedVehicles = totalVehicles - availableVehicles;
        upcomingReservations = upcoming.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load vehicle stats: $e')),
      );
    }
  }

  bool _isVehicleAvailable(Vehicle vehicle, List<VehicleEvent> reservations) {
    final now = DateTime.now();
    for (var reservation in reservations) {
      if (reservation.vehicleId == vehicle.id && 
          reservation.start.isBefore(now) && 
          reservation.end.isAfter(now)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vehicle Analytics',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        centerTitle: true,
      ),
      backgroundColor: colorScheme.background,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 40,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Vehicules Management',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildStatCard(
                          title: 'Total Vehicles',
                          value: totalVehicles.toString(),
                          imagePath: 'assets/illustrations/vehicles.jpg',
                          colorScheme: colorScheme,
                        ),
                        _buildStatCard(
                          title: 'Available',
                          value: availableVehicles.toString(),
                          imagePath: 'assets/illustrations/available.png',
                          colorScheme: colorScheme,
                        ),
                        _buildStatCard(
                          title: 'Reserved',
                          value: reservedVehicles.toString(),
                          imagePath: 'assets/illustrations/reserved.png',
                          colorScheme: colorScheme,
                        ),
                        _buildStatCard(
                          title: 'Upcoming',
                          value: upcomingReservations.toString(),
                          imagePath: 'assets/illustrations/upcoming.png',
                          colorScheme: colorScheme,
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Management Actions',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: colorScheme.outlineVariant,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehicleReservationCalendarScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Manage Events',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: colorScheme.onPrimary,
                              backgroundColor: colorScheme.primary,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllVehiclesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Manage Vehicles',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              backgroundColor: colorScheme.surface,
                              side: BorderSide(color: colorScheme.primary),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AssistantNavbar(
        currentIndex: _currentIndex,
        onTabChange: _onTabChange,
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String imagePath,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 66,
              width: 180,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}