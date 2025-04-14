import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import '../../services/vehicle_service.dart';
import '../../models/vehicle.dart';
import '../../models/vehicule_event.dart';

class VehiclePanel extends StatefulWidget {
  const VehiclePanel({Key? key}) : super(key: key);

  @override
  _VehiclePanelState createState() => _VehiclePanelState();
}

class _VehiclePanelState extends State<VehiclePanel> {
  final VehicleService _vehicleService = VehicleService();
  List<Vehicle> _vehicles = [];
  List<VehicleEvent> _events = [];
  bool _isLoading = true;
  List<Vehicle> _filteredVehicles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final vehicles = await _vehicleService.getVehicles();
      final events = await _vehicleService.getAllEvents();

      setState(() {
        _vehicles = vehicles;
        _events = events;
        _filteredVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVehicles = _vehicles.where((vehicle) {
        final model = vehicle.model?.toLowerCase() ?? '';
        final registrationNumber = vehicle.registrationNumber?.toLowerCase() ?? '';
        final type = vehicle.type?.toLowerCase() ?? '';
        return model.contains(query) ||
            registrationNumber.contains(query) ||
            type.contains(query);
      }).toList();
    });
  }

  List<ChartData> _getVehicleEventCounts() {
    final Map<String, int> vehicleEventCounts = {};

    for (var vehicle in _vehicles) {
      vehicleEventCounts[vehicle.id!] = 0;
    }

    for (var event in _events) {
      if (vehicleEventCounts.containsKey(event.vehicleId)) {
        vehicleEventCounts[event.vehicleId] = vehicleEventCounts[event.vehicleId]! + 1;
      }
    }

    return vehicleEventCounts.entries.map((entry) {
      final vehicle = _vehicles.firstWhere(
        (vehicle) => vehicle.id == entry.key,
        orElse: () => Vehicle(id: '', model: 'Unknown', registrationNumber: '', type: '', userId: ''),
      );
      return ChartData(vehicle.model ?? 'Unknown', entry.value);
    }).toList();
  }

  List<LineChartData> _getEventTrends() {
    final Map<String, int> eventTrends = {};

    for (var event in _events) {
      final month = '${event.start.year}-${event.start.month}';
      eventTrends[month] = (eventTrends[month] ?? 0) + 1;
    }

    return eventTrends.entries
        .map((entry) => LineChartData(entry.key, entry.value))
        .toList();
  }

  List<RangeColumnData> _getRangeColumnData() {
    return _vehicles.map((vehicle) {
      final eventsForVehicle = _events.where((event) => event.vehicleId == vehicle.id).toList();
      final minEvents = eventsForVehicle.isEmpty ? 0 : eventsForVehicle.length;
      final maxEvents = eventsForVehicle.isEmpty ? 0 : eventsForVehicle.length + 2; // Example range
      return RangeColumnData(vehicle.model ?? 'Unknown', minEvents, maxEvents);
    }).toList();
  }

  List<BubbleData> _getBubbleData() {
    return _vehicles.map((vehicle) {
      final eventsForVehicle = _events.where((event) => event.vehicleId == vehicle.id).toList();
      final eventCount = eventsForVehicle.length;
      return BubbleData(vehicle.model ?? 'Unknown', eventCount, eventCount * 10); // Adjust size as needed
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Usage Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickOverview(),
                  const SizedBox(height: 30),

                  // Vehicle List with Search Bar
                  _buildSection('Vehicle List', [
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildVehicleList(),
                  ]),
                  const SizedBox(height: 30),

                  // Vehicle Event Frequency
                  _buildSection('Vehicle Event Frequency', [
                    _buildChartContainer(
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        title: ChartTitle(text: 'Events per Vehicle'),
                        legend: Legend(isVisible: true),
                        series: <ChartSeries<ChartData, String>>[
                          BarSeries<ChartData, String>(
                            dataSource: _getVehicleEventCounts(),
                            xValueMapper: (ChartData data, _) => data.label,
                            yValueMapper: (ChartData data, _) => data.value,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            color: Colors.deepPurpleAccent,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),

                  // Event Distribution by Vehicle
                  _buildSection('Event Distribution by Vehicle', [
                    _buildChartContainer(
                      SfCircularChart(
                        title: ChartTitle(text: 'Event Distribution'),
                        legend: Legend(isVisible: true),
                        series: <CircularSeries<ChartData, String>>[
                          PieSeries<ChartData, String>(
                            dataSource: _getVehicleEventCounts(),
                            xValueMapper: (ChartData data, _) => data.label,
                            yValueMapper: (ChartData data, _) => data.value,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            pointColorMapper: (ChartData data, _) => _getRandomColor(),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),

                  // Event Trends Over Time
                  _buildSection('Event Trends Over Time', [
                    _buildChartContainer(
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        title: ChartTitle(text: 'Monthly Event Trends'),
                        legend: Legend(isVisible: true),
                        series: <ChartSeries<LineChartData, String>>[
                          LineSeries<LineChartData, String>(
                            dataSource: _getEventTrends(),
                            xValueMapper: (LineChartData data, _) => data.label,
                            yValueMapper: (LineChartData data, _) => data.value,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),

                  // Event Range by Vehicle
                  _buildSection('Event Range by Vehicle', [
                    _buildChartContainer(
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        title: ChartTitle(text: 'Event Range by Vehicle'),
                        legend: Legend(isVisible: true),
                        series: <ChartSeries<RangeColumnData, String>>[
                          RangeColumnSeries<RangeColumnData, String>(
                            dataSource: _getRangeColumnData(),
                            xValueMapper: (RangeColumnData data, _) => data.label,
                            lowValueMapper: (RangeColumnData data, _) => data.min,
                            highValueMapper: (RangeColumnData data, _) => data.max,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 30),

                  // Bubble Chart
                  _buildSection('Bubble Chart', [
                    _buildChartContainer(
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        title: ChartTitle(text: 'Bubble Chart'),
                        legend: Legend(isVisible: true),
                        series: <ChartSeries<BubbleData, String>>[
                          BubbleSeries<BubbleData, String>(
                            dataSource: _getBubbleData(),
                            xValueMapper: (BubbleData data, _) => data.label,
                            yValueMapper: (BubbleData data, _) => data.value,
                            sizeValueMapper: (BubbleData data, _) => data.size,
                            dataLabelSettings: const DataLabelSettings(isVisible: true),
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  // Quick Overview Section
  Widget _buildQuickOverview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Overview Title
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            children: [
              _buildActionButton(
                icon: Icons.directions_car,
                label: 'Manage All Vehicles',
                color: Colors.blueAccent,
                onPressed: () {
                  // Navigate to manage vehicles screen
                },
              ),
              _buildActionButton(
                icon: Icons.event,
                label: 'Manage All Events',
                color: Colors.green,
                onPressed: () {
                  // Navigate to manage events screen
                },
              ),
              _buildActionButton(
                icon: Icons.add,
                label: 'Add New Vehicle',
                color: Colors.orange,
                onPressed: () {
                  // Navigate to add vehicle screen
                },
              ),
              _buildActionButton(
                icon: Icons.add_circle,
                label: 'Add New Event',
                color: Colors.purple,
                onPressed: () {
                  // Navigate to add event screen
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action Button Widget
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by model, registration, or type...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade600),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                )
              : null,
        ),
      ),
    );
  }

  // Vehicle List Widget
  Widget _buildVehicleList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _filteredVehicles[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(vehicle.model ?? 'Unknown Model'),
            subtitle: Text(vehicle.registrationNumber ?? 'No Registration'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    // Navigate to edit vehicle screen
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    // Delete vehicle
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Section for charts and other information
  Widget _buildSection(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...content,
        ],
      ),
    );
  }

  Widget _buildChartContainer(Widget chart) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
      ),
      child: chart,
    );
  }

  // For random colors in charts
  Color _getRandomColor() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
      1.0,
    );
  }
}

class ChartData {
  final String label;
  final int value;

  ChartData(this.label, this.value);
}

class LineChartData {
  final String label;
  final int value;

  LineChartData(this.label, this.value);
}

class RangeColumnData {
  final String label;
  final int min;
  final int max;

  RangeColumnData(this.label, this.min, this.max);
}

class BubbleData {
  final String label;
  final int value;
  final double size;

  BubbleData(this.label, this.value, this.size);
}