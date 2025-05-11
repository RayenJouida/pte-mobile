import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/models/user_event.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final UserService _userService = UserService();
  List<User> _users = [];
  List<UserEvent> _userEvents = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  Map<String, int> _roleDistribution = {};
  Map<String, int> _eventsPerTechnician = {};
  Map<DateTime, int> _eventsOverTime = {};
  Map<String, Map<DateTime, int>> _eventsByDepartment = {};

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
      final usersData = await _userService.fetchUsers();
      final eventsData = await _userService.getAllUserEvents();
      setState(() {
        _users = usersData.map((user) => User.fromJson(user)).toList();
        _userEvents = eventsData;
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
    _roleDistribution = {};
    for (var user in _users) {
      for (var role in user.roles) {
        _roleDistribution[role] = (_roleDistribution[role] ?? 0) + 1;
      }
    }

    _eventsPerTechnician = {};
    for (var event in _userEvents) {
      final engineerId = event.engineer;
      _eventsPerTechnician[engineerId] = (_eventsPerTechnician[engineerId] ?? 0) + 1;
    }

    _eventsOverTime = {};
    for (var event in _userEvents) {
      final date = DateTime(event.start.year, event.start.month);
      _eventsOverTime[date] = (_eventsOverTime[date] ?? 0) + 1;
    }

    _eventsByDepartment = {};
    for (var event in _userEvents) {
      final user = _users.firstWhere(
        (u) => u.id == event.engineer,
        orElse: () => User(
          id: '',
          email: '',
          roles: [],
          firstName: '',
          lastName: '',
          department: 'Unknown',
          matricule: '',
          isEnabled: 'false',
          experience: 0,
        ),
      );
      final department = user.department ?? 'Unknown';
      final date = DateTime(event.start.year, event.start.month);
      if (!_eventsByDepartment.containsKey(department)) {
        _eventsByDepartment[department] = {};
      }
      _eventsByDepartment[department]![date] = (_eventsByDepartment[department]![date] ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? _darkTheme() : _lightTheme(),
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
                    expandedHeight: 140,
                    automaticallyImplyLeading: false, // Prevent default black arrow
                    flexibleSpace: Container(
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
                                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              Text(
                                'User Insights',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                onPressed: _fetchData,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Users: ${_users.length} | Total Events: ${_userEvents.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummarySection(),
                          const SizedBox(height: 24),
                          _buildChartSection(),
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
      primaryColor: const Color(0xFF006D77),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF006D77),
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
      primaryColor: const Color(0xFF006D77),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF006D77),
        secondary: Color(0xFFFF6F61),
        surface: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildSummarySection() {
    return FadeInUp(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryCard(
            title: 'Total Users',
            value: _users.length.toString(),
            icon: Icons.people,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            title: 'Total Events',
            value: _userEvents.length.toString(),
            icon: Icons.event,
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
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: const Color(0xFF006D77),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006D77),
                ),
              ),
            ],
          ),
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
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Distribution',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _roleDistribution.entries.map((entry) {
                    final index = _roleDistribution.keys.toList().indexOf(entry.key);
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
                          entry.key,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                          ),
                        ),
                        backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events per Technician',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _eventsPerTechnician.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final tech = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: tech.value.toDouble(),
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
                          final techId = _eventsPerTechnician.keys.elementAt(value.toInt());
                          final user = _users.firstWhere(
                            (u) => u.id == techId,
                            orElse: () => User(
                              id: '',
                              email: '',
                              roles: [],
                              firstName: techId,
                              lastName: '',
                              matricule: '',
                              isEnabled: 'false',
                              experience: 0,
                            ),
                          );
                          return SideTitleWidget(
                            child: Text(
                              user.firstName,
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
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF006D77).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final techId = _eventsPerTechnician.keys.elementAt(group.x.toInt());
                        final user = _users.firstWhere(
                          (u) => u.id == techId,
                          orElse: () => User(
                            id: '',
                            email: '',
                            roles: [],
                            firstName: techId,
                            lastName: '',
                            matricule: '',
                            isEnabled: 'false',
                            experience: 0,
                          ),
                        );
                        return BarTooltipItem(
                          '${user.firstName}\n${rod.toY.toInt()} Events',
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
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
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
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
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
    final departments = _eventsByDepartment.keys.toList();
    final dates = _eventsByDepartment.values
        .expand((e) => e.keys)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? const Color(0xFF2D3748) : const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events by Department',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
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
                          toY: departments.fold(0, (sum, dept) => sum + (_eventsByDepartment[dept]![date] ?? 0).toDouble()),
                          rodStackItems: departments.asMap().entries.map((deptEntry) {
                            final deptIndex = deptEntry.key;
                            final dept = deptEntry.value;
                            return BarChartRodStackItem(
                              0,
                              (_eventsByDepartment[dept]![date] ?? 0).toDouble(),
                              _getChartColor(deptIndex),
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
              children: departments.asMap().entries.map((entry) {
                final dept = entry.value;
                final index = entry.key;
                return Chip(
                  label: Text(
                    dept,
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