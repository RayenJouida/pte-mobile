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
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomsDashboardScreen extends StatefulWidget {
  final int? currentIndex;

  const RoomsDashboardScreen({Key? key, this.currentIndex}) : super(key: key);

  @override
  _RoomsDashboardScreenState createState() => _RoomsDashboardScreenState();
}

class _RoomsDashboardScreenState extends State<RoomsDashboardScreen> {
  final RoomService _roomService = RoomService();
  List<Room> _rooms = [];
  List<RoomEvent> _roomEvents = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  Map<String, int> _locationDistribution = {};
  Map<String, int> _eventsPerRoom = {};
  Map<DateTime, int> _eventsOverTime = {};
  Map<String, Map<DateTime, int>> _eventsByLocation = {};
  String? _currentUserRole;
  int _currentIndex = 0;

  // Maps to track legend visibility
  Map<String, bool> _locationVisibility = {};
  Map<String, bool> _roomVisibility = {};
  Map<DateTime, bool> _timeVisibility = {};
  Map<String, bool> _locationStackedVisibility = {};
  Map<String, bool> _roomTooltipVisibility = {};
  Map<DateTime, bool> _locationTooltipVisibility = {};

  // New: Set to track selected months for "Events Over Time" chart
  Set<DateTime> _selectedMonths = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex ?? 0;
    _fetchCurrentUserRole();
    _fetchData();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
    });
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
        _locationVisibility = Map.fromEntries(_locationDistribution.keys.map((key) => MapEntry(key, true)));
        _roomVisibility = Map.fromEntries(_eventsPerRoom.keys.map((key) => MapEntry(key, true)));
        _timeVisibility = Map.fromEntries(_eventsOverTime.keys.map((key) => MapEntry(key, true)));
        _locationStackedVisibility = Map.fromEntries(_eventsByLocation.keys.map((key) => MapEntry(key, true)));
        _roomTooltipVisibility = Map.fromEntries(_eventsPerRoom.keys.map((key) => MapEntry(key, false)));
        _locationTooltipVisibility = Map.fromEntries(_eventsOverTime.keys.map((key) => MapEntry(key, false)));
        _selectedMonths = _eventsOverTime.keys.toSet(); // Initialize with all months
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

  void _handleTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Theme(
      data: _isDarkMode ? _darkTheme() : _lightTheme(),
      child: Scaffold(
        drawer: _currentUserRole == 'ADMIN'
            ? AdminSidebar(
                currentIndex: _currentIndex,
                onTabChange: _handleTabChange,
              )
            : _currentUserRole == 'LAB-MANAGER'
                ? LabManagerSidebar(
                    currentIndex: _currentIndex,
                    onTabChange: _handleTabChange,
                  )
                : _currentUserRole == 'ENGINEER'
                    ? EngineerSidebar(
                        currentIndex: _currentIndex,
                        onTabChange: _handleTabChange,
                      )
                    : AssistantSidebar(
                        currentIndex: _currentIndex,
                        onTabChange: _handleTabChange,
                      ),
        body: _isLoading
            ? Center(
                child: FadeIn(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFF0632A1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Insights...',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
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
                    expandedHeight: isSmallScreen ? 100 : 120,
                    automaticallyImplyLeading: false,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + (isSmallScreen ? 8 : 12),
                            bottom: isSmallScreen ? 12 : 16,
                            left: padding,
                            right: padding,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0632A1),
                                Color(0xFF0632A1),
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
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: Icon(
                                    Icons.menu,
                                    color: Colors.white,
                                    size: isSmallScreen ? 24 : 28,
                                  ),
                                  onPressed: () {
                                    Scaffold.of(context).openDrawer();
                                  },
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Rooms Insights',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: isSmallScreen ? 24 : 28,
                                ),
                                onPressed: _fetchData,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummarySection(isSmallScreen),
                          const SizedBox(height: 24),
                          _buildChartSection(isSmallScreen),
                        ],
                      ),
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
      primaryColor: const Color(0xFF0632A1),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0632A1),
        secondary: Color(0xFFFF6F61),
        surface: Color(0xFFFFFFFF),
      ),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF1E293B),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFFD1D5DB),
        displayColor: const Color(0xFFD1D5DB),
      ),
      cardColor: const Color(0xFF2D3748),
      primaryColor: const Color(0xFF0632A1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0632A1),
        secondary: Color(0xFFFF6F61),
        surface: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildSummarySection(bool isSmallScreen) {
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
                isSmallScreen: isSmallScreen,
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
                isSmallScreen: isSmallScreen,
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
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF0632A1),
                  size: isSmallScreen ? 24 : 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 24 : 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0632A1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(bool isSmallScreen) {
    return Column(
      children: [
        FadeInUp(child: _buildPieChart(isSmallScreen)),
        const SizedBox(height: 24),
        FadeInUp(child: _buildBarChart(isSmallScreen)),
        const SizedBox(height: 24),
        FadeInUp(child: _buildLineChart(isSmallScreen)),
        const SizedBox(height: 24),
        FadeInUp(child: _buildStackedBarChart(isSmallScreen)),
      ],
    );
  }

  Widget _buildPieChart(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Distribution',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: _locationDistribution.entries.where((entry) => _locationVisibility[entry.key] ?? true).map((entry) {
                          final index = _locationDistribution.keys.toList().indexOf(entry.key);
                          return PieChartSectionData(
                            color: _getChartColor(index),
                            value: entry.value.toDouble(),
                            title: '${entry.value}',
                            radius: isSmallScreen ? 60 : 80,
                            titleStyle: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                        centerSpaceRadius: isSmallScreen ? 30 : 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildLegend(
                      items: _locationDistribution.keys.map((key) => LegendItem(
                            label: key,
                            isVisible: _locationVisibility[key] ?? true,
                            onTap: () {
                              setState(() {
                                _locationVisibility[key] = !(_locationVisibility[key] ?? true);
                              });
                            },
                          )).toList(),
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events per Room',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _eventsPerRoom.entries.where((entry) => _roomVisibility[entry.key] ?? true).toList().asMap().entries.map((entry) {
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
                      showingTooltipIndicators: _roomTooltipVisibility[room.key] ?? false ? [0] : [],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final roomId = _eventsPerRoom.keys.elementAt(value.toInt());
                          if (_roomVisibility[roomId] ?? true) {
                            final room = _rooms.firstWhere(
                              (r) => r.id == roomId,
                              orElse: () => Room(
                                id: '',
                                label: 'Unknown',
                                location: '',
                                capacity: '0',
                              ),
                            );
                            return SideTitleWidget(
                              child: Text(
                                room.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                                ),
                              ),
                              meta: meta,
                              space: 4,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 40,
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
                              color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
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
                        color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF0632A1).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final roomId = _eventsPerRoom.keys.elementAt(group.x.toInt());
                        if (_roomVisibility[roomId] ?? true) {
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
                        }
                        return null;
                      },
                    ),
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                        final roomId = _eventsPerRoom.keys.elementAt(barTouchResponse.spot!.touchedBarGroupIndex);
                        setState(() {
                          _roomTooltipVisibility[roomId] = !(_roomTooltipVisibility[roomId] ?? false);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _eventsPerRoom.keys.map((key) {
                final room = _rooms.firstWhere((r) => r.id == key, orElse: () => Room(id: '', label: 'Unknown', location: '', capacity: '0'));
                return LegendItem(
                  label: room.label,
                  isVisible: _roomVisibility[key] ?? true,
                  onTap: () {
                    setState(() {
                      _roomVisibility[key] = !(_roomVisibility[key] ?? true);
                    });
                  },
                );
              }).toList(),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(bool isSmallScreen) {
    final uniqueDates = _eventsOverTime.keys.toList()..sort((a, b) => a.compareTo(b));
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events Over Time',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: uniqueDates.map((date) {
                final isSelected = _selectedMonths.contains(date);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedMonths.remove(date);
                      } else {
                        _selectedMonths.add(date);
                      }
                    });
                  },
                  child: Chip(
                    label: Text(
                      DateFormat('MMM yyyy').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 10 : 12,
                        color: isSelected ? (_isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937)) : Colors.grey,
                      ),
                    ),
                    backgroundColor: isSelected ? const Color(0xFFFF6F61).withOpacity(0.1) : Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? const Color(0xFFFF6F61) : Colors.grey, width: 1),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: uniqueDates
                          .where((date) => _selectedMonths.contains(date) && (_timeVisibility[date] ?? true))
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final date = entry.value;
                        return FlSpot(index.toDouble(), _eventsOverTime[date]!.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFFFF6F61),
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFFF6F61).withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final dateIndex = value.toInt();
                          if (dateIndex >= 0 && dateIndex < uniqueDates.length) {
                            final date = uniqueDates[dateIndex];
                            if (_selectedMonths.contains(date) && (_timeVisibility[date] ?? true)) {
                              return SideTitleWidget(
                                space: 4,
                                child: Text(
                                  DateFormat('MMM yyyy').format(date),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                meta: meta,
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                        interval: 1, // Ensure each selected month gets a title
                        reservedSize: 40,
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
                              color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
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
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: uniqueDates.where((date) => _selectedMonths.contains(date)).length > 0
                      ? uniqueDates.where((date) => _selectedMonths.contains(date)).length - 1
                      : 0,
                  minY: 0,
                  maxY: _eventsOverTime.values.isNotEmpty
                      ? _eventsOverTime.values.reduce((a, b) => a > b ? a : b) * 1.1
                      : 10,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => const Color(0xFF0632A1).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dateIndex = spot.x.toInt();
                          if (dateIndex >= 0 && dateIndex < uniqueDates.length) {
                            final date = uniqueDates[dateIndex];
                            if (_selectedMonths.contains(date) && (_timeVisibility[date] ?? true)) {
                              return LineTooltipItem(
                                '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} Events',
                                GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              );
                            }
                          }
                          return null;
                        }).whereType<LineTooltipItem>().toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, lineTouchResponse) {
                      if (event is FlTapUpEvent && lineTouchResponse != null && lineTouchResponse.lineBarSpots != null) {
                        final spot = lineTouchResponse.lineBarSpots!.first;
                        final dateIndex = spot.x.toInt();
                        if (dateIndex >= 0 && dateIndex < uniqueDates.length) {
                          final date = uniqueDates[dateIndex];
                          setState(() {
                            if (_timeVisibility.containsKey(date)) {
                              _timeVisibility[date] = !(_timeVisibility[date] ?? true);
                            }
                          });
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _eventsOverTime.keys.map((key) {
                return LegendItem(
                  label: DateFormat('MMM yyyy').format(key),
                  isVisible: _timeVisibility[key] ?? true,
                  onTap: () {
                    setState(() {
                      _timeVisibility[key] = !(_timeVisibility[key] ?? true);
                    });
                  },
                );
              }).toList(),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedBarChart(bool isSmallScreen) {
    final locations = _eventsByLocation.keys.toList();
    final dates = _eventsByLocation.values.expand((e) => e.keys).toSet().toList()..sort((a, b) => a.compareTo(b));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events by Location',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 220 : 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: dates.asMap().entries.map((entry) {
                    final index = entry.key;
                    final date = entry.value;
                    final visibleLocations = locations.where((loc) => _locationStackedVisibility[loc] ?? true).toList();
                    final totalHeight = visibleLocations.fold(0.0, (sum, loc) => sum + (_eventsByLocation[loc]![date] ?? 0).toDouble());
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: totalHeight,
                          rodStackItems: visibleLocations.asMap().entries.map((locEntry) {
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
                      showingTooltipIndicators: _locationTooltipVisibility[date] ?? false ? [0] : [],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = dates[value.toInt()];
                          return SideTitleWidget(
                            child: Text(
                              DateFormat('MMM yyyy').format(date),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                              ),
                            ),
                            meta: meta,
                            space: 4,
                          );
                        },
                        reservedSize: 40,
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
                              color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
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
                        color: _isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF0632A1).withOpacity(0.9),
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
                    touchCallback: (FlTouchEvent event, barTouchResponse) {
                      if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                        final date = dates[barTouchResponse.spot!.touchedBarGroupIndex];
                        setState(() {
                          _locationTooltipVisibility[date] = !(_locationTooltipVisibility[date] ?? false);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _eventsByLocation.keys.map((key) {
                return LegendItem(
                  label: key,
                  isVisible: _locationStackedVisibility[key] ?? true,
                  onTap: () {
                    setState(() {
                      _locationStackedVisibility[key] = !(_locationStackedVisibility[key] ?? true);
                    });
                  },
                );
              }).toList(),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend({required List<LegendItem> items, required bool isSmallScreen}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return GestureDetector(
          onTap: item.onTap,
          child: Chip(
            label: Text(
              item.label,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 10 : 12,
                color: item.isVisible ? (_isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937)) : Colors.grey,
              ),
            ),
            backgroundColor: item.isVisible ? _getChartColor(items.indexOf(item) % 6).withOpacity(0.1) : Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: item.isVisible ? _getChartColor(items.indexOf(item) % 6) : Colors.grey, width: 1),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getChartColor(int index) {
    const colors = [
      Color(0xFF0632A1),
      Color(0xFF6EAEE7),
      Color(0xFF83C5BE),
      Color(0xFFFFB5A7),
      Color(0xFF468C98),
      Color(0xFFFCD5CE),
    ];
    return colors[index % colors.length];
  }
}

class LegendItem {
  final String label;
  final bool isVisible;
  final VoidCallback onTap;

  LegendItem({required this.label, required this.isVisible, required this.onTap});
}