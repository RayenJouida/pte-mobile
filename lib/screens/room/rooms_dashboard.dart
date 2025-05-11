import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pte_mobile/screens/room/all_rooms.dart';
import 'package:pte_mobile/services/room_service.dart';
import 'package:pte_mobile/models/room.dart';
import 'package:pte_mobile/models/room_event.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pte_mobile/screens/room/room_reservation_calendar_screen.dart';

class RoomsDashboardScreen extends StatefulWidget {
  const RoomsDashboardScreen({Key? key}) : super(key: key);

  @override
  _RoomsDashboardScreenState createState() => _RoomsDashboardScreenState();
}

class _RoomsDashboardScreenState extends State<RoomsDashboardScreen> {
  final RoomService _roomService = RoomService();
  List<Room> _rooms = [];
  List<RoomEvent> _roomEvents = [];
  bool _isLoading = true;
  Map<String, int> _locationDistribution = {};
  Map<String, int> _eventsPerRoom = {};
  Map<DateTime, int> _eventsOverTime = {};
  Map<String, Map<DateTime, int>> _eventsByLocation = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final roomsData = await _roomService.getAllRooms();
      final eventsData = await _roomService.getAllEvents();
      setState(() {
        _rooms = roomsData;
        _roomEvents = eventsData;
        _processData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load dashboard data: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF6F61),
        ),
      );
    }
  }

  void _processData() {
    _locationDistribution = {};
    for (var room in _rooms) {
      final location = room.location ?? 'Unknown';
      _locationDistribution[location] = (_locationDistribution[location] ?? 0) + 1;
    }

    _eventsPerRoom = {};
    for (var event in _roomEvents) {
      final roomId = event.roomId;
      _eventsPerRoom[roomId] = (_eventsPerRoom[roomId] ?? 0) + 1;
    }

    _eventsOverTime = {};
    for (var event in _roomEvents) {
      final date = DateTime(event.start.year, event.start.month);
      _eventsOverTime[date] = (_eventsOverTime[date] ?? 0) + 1;
    }

    _eventsByLocation = {};
    for (var event in _roomEvents) {
      final room = _rooms.firstWhere(
        (r) => r.id == event.roomId,
        orElse: () => Room(
          id: '',
          label: 'Unknown',
          location: 'Unknown',
          capacity: '0',
        ),
      );
      final location = room.location ?? 'Unknown';
      final date = DateTime(event.start.year, event.start.month);
      if (!_eventsByLocation.containsKey(location)) {
        _eventsByLocation[location] = {};
      }
      _eventsByLocation[location]![date] = (_eventsByLocation[location]![date] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _lightTheme(),
      child: Scaffold(
        body: _isLoading
            ? Center(
                child: FadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFF006D77),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Insights...',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    pinned: true,
                    expandedHeight: 140,
                    automaticallyImplyLeading: false, // Prevent default black arrow
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 16,
                          bottom: 24,
                          left: 16,
                          right: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white, // White back arrow
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                Text(
                                  'Rooms Insights',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: _fetchData,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AllRoomsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Total Rooms: ${_rooms.length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '|',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RoomReservationCalendarScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Total Events: ${_roomEvents.length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSummarySection(),
                        const SizedBox(height: 24),
                        _buildChartSection(),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFF1F2937),
        displayColor: const Color(0xFF1F2937),
      ),
      cardColor: const Color(0xFFFFFFFF),
      primaryColor: const Color(0xFF006D77),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF006D77),
        secondary: Color(0xFFFF6F61),
        surface: Color(0xFFFFFFFF),
      ),
    );
  }

  Widget _buildSummarySection() {
    return FadeInUp(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllRoomsScreen()),
                );
              },
              child: _buildSummaryCard(
                title: 'Total Rooms',
                value: _rooms.length.toString(),
                icon: Icons.meeting_room,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoomReservationCalendarScreen()),
                );
              },
              child: _buildSummaryCard(
                title: 'Total Events',
                value: _roomEvents.length.toString(),
                icon: Icons.event,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF006D77),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF006D77),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Column(
      children: [
        FadeInUp(child: _buildPieChart()),
        const SizedBox(height: 24),
        FadeInUp(child: _buildBarChart()),
        const SizedBox(height: 24),
        FadeInUp(child: _buildLineChart()),
        const SizedBox(height: 24),
        FadeInUp(child: _buildStackedBarChart()),
      ],
    );
  }

  Widget _buildPieChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Distribution',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _locationDistribution.entries.map((entry) {
                    final index = _locationDistribution.keys.toList().indexOf(entry.key);
                    return PieChartSectionData(
                      color: _getChartColor(index),
                      value: entry.value.toDouble(),
                      title: '${entry.value}',
                      radius: 80,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      badgeWidget: Chip(
                        label: Text(
                          entry.key.length > 10 ? '${entry.key.substring(0, 10)}...' : entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: _getChartColor(index), width: 1),
                        ),
                      ),
                      badgePositionPercentageOffset: 1.3,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events per Room',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _eventsPerRoom.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final room = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: room.value.toDouble(),
                          color: _getChartColor(index),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final roomId = _eventsPerRoom.keys.elementAt(value.toInt());
                          final room = _rooms.firstWhere(
                            (r) => r.id == roomId,
                            orElse: () => Room(
                              id: '',
                              label: 'Unknown',
                              location: '',
                              capacity: '0',
                            ),
                          );
                          final label = room.label.length > 8 ? '${room.label.substring(0, 8)}...' : room.label;
                          return SideTitleWidget(
                            child: Transform.rotate(
                              angle: -45 * 3.1415927 / 180,
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            meta: meta,
                            space: 4,
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1F2937),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.black.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF006D77).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final roomId = _eventsPerRoom.keys.elementAt(group.x.toInt());
                        final room = _rooms.firstWhere(
                          (r) => r.id == roomId,
                          orElse: () => Room(
                            id: '',
                            label: 'Unknown',
                            location: '',
                            capacity: '0',
                          ),
                        );
                        return BarTooltipItem(
                          '${room.label}\n${rod.toY.toInt()} Events',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events Over Time',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _eventsOverTime.entries.toList().asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFFFF6F61),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFFF6F61).withOpacity(0.2),
                      ),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = _eventsOverTime.keys.elementAt(value.toInt());
                          return SideTitleWidget(
                            child: Text(
                              DateFormat('MMM yyyy').format(date),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            meta: meta,
                            space: 4,
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1F2937),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.black.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => const Color(0xFFFF6F61).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = _eventsOverTime.keys.elementAt(spot.x.toInt());
                          return LineTooltipItem(
                            '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} Events',
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedBarChart() {
    final locations = _eventsByLocation.keys.toList();
    final dates = _eventsByLocation.values
        .expand((e) => e.keys)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events by Location',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: dates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: locations.fold(0, (sum, loc) => sum + (_eventsByLocation[loc]![date] ?? 0).toDouble()),
                          rodStackItems: locations.asMap().entries.map((locEntry) {
                            final locIndex = locEntry.key;
                            final loc = locEntry.value;
                            return BarChartRodStackItem(
                              0,
                              (_eventsByLocation[loc]![date] ?? 0).toDouble(),
                              _getChartColor(locIndex),
                            );
                          }).toList(),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = dates[value.toInt()];
                          return SideTitleWidget(
                            child: Transform.rotate(
                              angle: -45 * 3.1415927 / 180,
                              child: Text(
                                DateFormat('MMM yyyy').format(date),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            meta: meta,
                            space: 4,
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF1F2937),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.black.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF006D77).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = dates[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('MMM yyyy').format(date)}\n${rod.toY.toInt()} Events',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: locations.asMap().entries.map((entry) {
                final loc = entry.value;
                final index = entry.key;
                return Chip(
                  label: Text(
                    loc.length > 10 ? '${loc.substring(0, 10)}...' : loc,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getChartColor(index),
                    ),
                  ),
                  backgroundColor: _getChartColor(index).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: _getChartColor(index), width: 1),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChartColor(int index) {
    const colors = [
      Color(0xFF006D77),
      Color(0xFFFF6F61),
      Color(0xFF83C5BE),
      Color(0xFFFFB5A7),
      Color(0xFF468C98),
      Color(0xFFFCD5CE),
    ];
    return colors[index % colors.length];
  }
}