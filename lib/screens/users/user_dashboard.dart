import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/models/user_event.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/theme/theme.dart';

class UserDashboardScreen extends StatefulWidget {
  final int? currentIndex;

  const UserDashboardScreen({Key? key, this.currentIndex}) : super(key: key);

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
  Map<String, Map<DateTime, int>> _eventsByDepartement = {};
  String? _currentUserRole;
  int _currentIndex = 0;

  // Maps to track legend visibility
  Map<String, bool> _roleVisibility = {};
  Map<String, bool> _technicianVisibility = {};
  Map<DateTime, bool> _timeVisibility = {};
  Map<String, bool> _departementVisibility = {};

  // Maps to track tooltip visibility
  Map<String, bool> _technicianTooltipVisibility = {};
  Map<DateTime, bool> _departmentTooltipVisibility = {};

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
      _currentUserRole = prefs.getString('userRole') ?? 'Assistant';
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final usersData = await _userService.fetchUsers();
      final eventsData = await _userService.getAllUserEvents();
      setState(() {
        _users = usersData.map((user) => User.fromJson(user)).toList();
        _userEvents = eventsData;
        _processData();
        _isLoading = false;
        _roleVisibility = Map.fromEntries(_roleDistribution.keys.map((key) => MapEntry(key, true)));
        _technicianVisibility = Map.fromEntries(_eventsPerTechnician.keys.map((key) => MapEntry(key, true)));
        _timeVisibility = Map.fromEntries(_eventsOverTime.keys.map((key) => MapEntry(key, true)));
        _departementVisibility = Map.fromEntries(_eventsByDepartement.keys.map((key) => MapEntry(key, true)));
        _technicianTooltipVisibility = Map.fromEntries(_eventsPerTechnician.keys.map((key) => MapEntry(key, false)));
        _departmentTooltipVisibility = Map.fromEntries(_eventsOverTime.keys.map((key) => MapEntry(key, false)));
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load dashboard data: $e', style: GoogleFonts.poppins(color: lightColorScheme.onError)),
          backgroundColor: lightColorScheme.error,
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

    _eventsByDepartement = {};
    for (var event in _userEvents) {
      final user = _users.firstWhere(
        (u) => u.id == event.engineer,
        orElse: () => User(id: '', email: '', roles: [], firstName: '', lastName: '', departement: 'Unknown', matricule: '', isEnabled: 'false', experience: 0),
      );
      final departement = user.departement ?? 'Unknown';
      final date = DateTime(event.start.year, event.start.month);
      if (!_eventsByDepartement.containsKey(departement)) _eventsByDepartement[departement] = {};
      _eventsByDepartement[departement]![date] = (_eventsByDepartement[departement]![date] ?? 0) + 1;
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
                      CircularProgressIndicator(color: lightColorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Loading Insights...',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: _isDarkMode ? darkColorScheme.onBackground : lightColorScheme.onBackground,
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
                            gradient: LinearGradient(
                              colors: [lightColorScheme.primary, lightColorScheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: lightColorScheme.shadow.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Builder(
                                builder: (context) => IconButton(
                                  icon: Icon(Icons.menu, color: lightColorScheme.onPrimary, size: isSmallScreen ? 24 : 28),
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'User Insights',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: lightColorScheme.onPrimary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.refresh, color: lightColorScheme.onPrimary, size: isSmallScreen ? 24 : 28),
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
      scaffoldBackgroundColor: lightColorScheme.background,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: lightColorScheme.onBackground,
        displayColor: lightColorScheme.onBackground,
      ),
      cardColor: lightColorScheme.surface,
      primaryColor: lightColorScheme.primary,
      colorScheme: lightColorScheme,
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      scaffoldBackgroundColor: darkColorScheme.background,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: darkColorScheme.onBackground,
        displayColor: darkColorScheme.onBackground,
      ),
      cardColor: darkColorScheme.surface,
      primaryColor: darkColorScheme.primary,
      colorScheme: darkColorScheme,
    );
  }

  Widget _buildSummarySection(bool isSmallScreen) {
    return FadeInUp(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryCard(
            title: 'Total Users',
            value: _users.length.toString(),
            icon: Icons.people,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            title: 'Pending Events',
            value: _userEvents.where((event) => event.isAccepted == 'Pending').length.toString(),
            icon: Icons.hourglass_empty,
            isSmallScreen: isSmallScreen,
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
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _isDarkMode ? darkColorScheme.surface : lightColorScheme.surface,
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: lightColorScheme.primary, size: isSmallScreen ? 24 : 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w500,
                        color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
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
                  color: lightColorScheme.primary,
                ),
              ),
            ],
          ),
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
      color: _isDarkMode ? darkColorScheme.surface : lightColorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Distribution',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
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
                        sections: _roleDistribution.entries.where((entry) => _roleVisibility[entry.key] ?? true).map((entry) {
                          final index = _roleDistribution.keys.toList().indexOf(entry.key);
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
                      items: _roleDistribution.keys.map((key) => LegendItem(
                            label: key,
                            isVisible: _roleVisibility[key] ?? true,
                            onTap: () {
                              setState(() => _roleVisibility[key] = !(_roleVisibility[key] ?? true));
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
      color: _isDarkMode ? darkColorScheme.surface : lightColorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events per Technician',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: _eventsPerTechnician.entries.where((entry) => _technicianVisibility[entry.key] ?? true).toList().asMap().entries.map((entry) {
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
                      showingTooltipIndicators: _technicianTooltipVisibility[tech.key] ?? false ? [0] : [],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final techId = _eventsPerTechnician.keys.elementAt(value.toInt());
                          if (_technicianVisibility[techId] ?? true) {
                            final user = _users.firstWhere(
                              (u) => u.id == techId,
                              orElse: () => User(id: '', email: '', roles: [], firstName: techId, lastName: '', departement: 'Unknown', matricule: '', isEnabled: 'false', experience: 0),
                            );
                            return SideTitleWidget(
                              space: 4,
                              meta: meta,
                              child: Text(
                                user.firstName.isNotEmpty ? user.firstName : techId,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
                                ),
                              ),
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
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
                          ),
                        ),
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
                      color: _isDarkMode ? darkColorScheme.outlineVariant : lightColorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => lightColorScheme.primary.withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final techId = _eventsPerTechnician.keys.elementAt(group.x.toInt());
                        if (_technicianVisibility[techId] ?? true) {
                          final user = _users.firstWhere(
                            (u) => u.id == techId,
                            orElse: () => User(id: '', email: '', roles: [], firstName: techId, lastName: '', matricule: '', isEnabled: 'false', experience: 0),
                          );
                          return BarTooltipItem(
                            '${user.firstName}\n${rod.toY.toInt()} Events',
                            GoogleFonts.poppins(
                              color: lightColorScheme.onPrimary,
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
                        final techId = _eventsPerTechnician.keys.elementAt(barTouchResponse.spot!.touchedBarGroupIndex);
                        setState(() {
                          _technicianTooltipVisibility[techId] = !(_technicianTooltipVisibility[techId] ?? false);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _eventsPerTechnician.keys.map((key) {
                final user = _users.firstWhere(
                  (u) => u.id == key,
                  orElse: () => User(id: '', email: '', roles: [], firstName: key, lastName: '', matricule: '', isEnabled: 'false', experience: 0),
                );
                return LegendItem(
                  label: user.firstName.isNotEmpty ? user.firstName : key,
                  isVisible: _technicianVisibility[key] ?? true,
                  onTap: () => setState(() => _technicianVisibility[key] = !(_technicianVisibility[key] ?? true)),
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? darkColorScheme.surface : lightColorScheme.surface,
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
                color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _eventsOverTime.entries.where((entry) => _timeVisibility[entry.key] ?? true).map((entry) {
                        final index = _eventsOverTime.keys.toList().indexOf(entry.key);
                        return FlSpot(index.toDouble(), entry.value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: lightColorScheme.secondary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: lightColorScheme.secondary.withOpacity(0.2),
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
                          if (_timeVisibility[date] ?? true) {
                            return SideTitleWidget(
                              space: 4,
                              meta: meta,
                              child: Text(
                                DateFormat('MMM yyyy').format(date),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 40,
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
                          ),
                        ),
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
                      color: _isDarkMode ? darkColorScheme.outlineVariant : lightColorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => lightColorScheme.primary.withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final date = _eventsOverTime.keys.elementAt(spot.x.toInt());
                        if (_timeVisibility[date] ?? true) {
                          return LineTooltipItem(
                            '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} Events',
                            GoogleFonts.poppins(
                              color: lightColorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }
                        return null;
                      }).whereType<LineTooltipItem>().toList(),
                    ),
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
                  onTap: () => setState(() => _timeVisibility[key] = !(_timeVisibility[key] ?? true)),
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
    final departements = _eventsByDepartement.keys.toList();
    final dates = _eventsByDepartement.values.expand((e) => e.keys).toSet().toList()..sort((a, b) => a.compareTo(b));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _isDarkMode ? darkColorScheme.surface : lightColorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events by Department',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
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
                    final visibleDepartements = departements.where((dept) => _departementVisibility[dept] ?? true).toList();
                    final totalHeight = visibleDepartements.fold(0.0, (sum, dept) => sum + (_eventsByDepartement[dept]![date] ?? 0).toDouble());
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: totalHeight,
                          rodStackItems: visibleDepartements.asMap().entries.map((deptEntry) {
                            final deptIndex = deptEntry.key;
                            final dept = deptEntry.value;
                            return BarChartRodStackItem(
                              0,
                              (_eventsByDepartement[dept]![date] ?? 0).toDouble(),
                              _getChartColor(deptIndex),
                            );
                          }).toList(),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: _departmentTooltipVisibility[date] ?? false ? [0] : [],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final date = dates[value.toInt()];
                          return SideTitleWidget(
                            space: 4,
                            meta: meta,
                            child: Text(
                              DateFormat('MMM yyyy').format(date),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface,
                          ),
                        ),
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
                      color: _isDarkMode ? darkColorScheme.outlineVariant : lightColorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => lightColorScheme.primary.withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = dates[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('MMM yyyy').format(date)}\n${rod.toY.toInt()} Events',
                          GoogleFonts.poppins(
                            color: lightColorScheme.onPrimary,
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
                          _departmentTooltipVisibility[date] = !(_departmentTooltipVisibility[date] ?? false);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _eventsByDepartement.keys.map((key) {
                return LegendItem(
                  label: key,
                  isVisible: _departementVisibility[key] ?? true,
                  onTap: () => setState(() => _departementVisibility[key] = !(_departementVisibility[key] ?? true)),
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
                color: item.isVisible ? (_isDarkMode ? darkColorScheme.onSurface : lightColorScheme.onSurface) : Colors.grey,
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