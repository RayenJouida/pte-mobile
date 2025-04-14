import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math';
import '../../services/room_service.dart';
import '../../models/room.dart';
import '../../models/room_event.dart';

class RoomPanel extends StatefulWidget {
  const RoomPanel({Key? key}) : super(key: key);

  @override
  _RoomPanelState createState() => _RoomPanelState();
}

class _RoomPanelState extends State<RoomPanel> {
  final RoomService _roomService = RoomService();
  List<Room> _rooms = [];
  List<RoomEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final rooms = await _roomService.getAllRooms();
      final events = await _roomService.getAllEvents();

      setState(() {
        _rooms = rooms;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ChartData> _getRoomEventCounts() {
    final Map<String, int> roomEventCounts = {};

    for (var room in _rooms) {
      roomEventCounts[room.id] = 0;
    }

    for (var event in _events) {
      if (roomEventCounts.containsKey(event.roomId)) {
        roomEventCounts[event.roomId] = roomEventCounts[event.roomId]! + 1;
      }
    }

    return roomEventCounts.entries.map((entry) {
      final room = _rooms.firstWhere(
        (room) => room.id == entry.key,
        orElse: () => Room(id: '', label: 'Unknown', location: '', capacity: ''),
      );
      return ChartData(room.label, entry.value);
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
    return _rooms.map((room) {
      final eventsForRoom = _events.where((event) => event.roomId == room.id).toList();
      final minEvents = eventsForRoom.isEmpty ? 0 : eventsForRoom.length;
      final maxEvents = eventsForRoom.isEmpty ? 0 : eventsForRoom.length + 2; // Example range
      return RangeColumnData(room.label, minEvents, maxEvents);
    }).toList();
  }

  List<BubbleData> _getBubbleData() {
    return _rooms.map((room) {
      final eventsForRoom = _events.where((event) => event.roomId == room.id).toList();
      final eventCount = eventsForRoom.length;
      return BubbleData(room.label, eventCount, eventCount * 10); // Adjust size as needed
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Usage Dashboard'),
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

                  // Room Event Frequency
                  _buildSection('Room Event Frequency', [
                    _buildChartContainer(
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        title: ChartTitle(text: 'Events per Room'),
                        legend: Legend(isVisible: true),
                        series: <ChartSeries<ChartData, String>>[
                          BarSeries<ChartData, String>(
                            dataSource: _getRoomEventCounts(),
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

                  // Event Distribution by Room
                  _buildSection('Event Distribution by Room', [
                    _buildChartContainer(
                      SfCircularChart(
                        title: ChartTitle(text: 'Event Distribution'),
                        legend: Legend(isVisible: true),
                        series: <CircularSeries<ChartData, String>>[
                          PieSeries<ChartData, String>(
                            dataSource: _getRoomEventCounts(),
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

                  // Event Range by Room
                  _buildSection('Event Range by Room', [
                    _buildChartContainer(
                      SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        title: ChartTitle(text: 'Event Range by Room'),
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
                icon: Icons.room,
                label: 'Manage All Rooms',
                color: Colors.blueAccent,
                onPressed: () {
                  // Navigate to manage rooms screen
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
                label: 'Create New Room',
                color: Colors.orange,
                onPressed: () {
                  // Navigate to create room screen
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
