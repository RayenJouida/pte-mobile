import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pte_mobile/services/leave_service.dart';
import 'package:pte_mobile/models/leave.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/models/user.dart';

class LeaveDashboardScreen extends StatefulWidget {
  const LeaveDashboardScreen({Key? key}) : super(key: key);

  @override
  _LeaveDashboardScreenState createState() => _LeaveDashboardScreenState();
}

class _LeaveDashboardScreenState extends State<LeaveDashboardScreen> {
  final LeaveService _leaveService = LeaveService();
  final UserService _userService = UserService();
  List<Leave> _leaves = [];
  List<User> _users = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  Map<String, int> _leaveTypeDistribution = {};
  Map<String, int> _leavesPerUser = {};
  Map<DateTime, int> _leavesOverTime = {};
  Map<String, Map<DateTime, int>> _leavesByStatus = {};
  String? _currentUserRole;
  int _currentIndex = 0;

  // Maps to track legend visibility
  Map<String, bool> _typeVisibility = {};
  Map<String, bool> _userVisibility = {};
  Map<DateTime, bool> _timeVisibility = {};
  Map<String, bool> _statusVisibility = {};
  Map<String, bool> _userTooltipVisibility = {};
  Map<String, bool> _statusTooltipVisibility = {};
  Set<DateTime> _selectedMonths = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
    _fetchData();
  }

  Future<void> _fetchCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserRole = prefs.getString('userRole') ?? 'Assistant';
      _initializeIndex();
    });
  }

  void _initializeIndex() {
    switch (_currentUserRole?.toUpperCase()) {
      case 'ADMIN':
        _currentIndex = 16;
        break;
      case 'ASSISTANT':
        _currentIndex = 9;
        break;
      case 'ENGINEER':
      case 'LAB-MANAGER':
      default:
        _currentIndex = 0;
        _showAccessDenied();
        break;
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final leavesData = await _leaveService.fetchAllLeaves();
      final usersData = await _userService.fetchUsers();
      setState(() {
        _leaves = leavesData;
        _users = usersData.map((userJson) => User.fromJson(userJson)).toList();
        _processData();
        _isLoading = false;
        _typeVisibility = Map.fromEntries(_leaveTypeDistribution.keys.map((key) => MapEntry(key, true)));
        _userVisibility = Map.fromEntries(_leavesPerUser.keys.map((key) => MapEntry(key, true)));
        _timeVisibility = Map.fromEntries(_leavesOverTime.keys.map((key) => MapEntry(key, true)));
        _statusVisibility = Map.fromEntries(_leavesByStatus.keys.map((key) => MapEntry(key, true)));
        _userTooltipVisibility = Map.fromEntries(_leavesPerUser.keys.map((key) => MapEntry(key, false)));
        _statusTooltipVisibility = Map.fromEntries(_leavesByStatus.keys.map((key) => MapEntry(key, false)));
        _selectedMonths = _leavesOverTime.keys.toSet();
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
    _leaveTypeDistribution = {};
    for (var leave in _leaves) {
      final type = leave.type ?? 'Unknown';
      _leaveTypeDistribution[type] = (_leaveTypeDistribution[type] ?? 0) + 1;
    }

    _leavesPerUser = {};
    for (var leave in _leaves) {
      final applicant = leave.applicant;
      String userName = 'Unknown';
      if (applicant != null) {
        final applicantString = applicant.toString();
        final nameMatch = RegExp(r'name: ([^,]+)').firstMatch(applicantString);
        if (nameMatch != null) {
          userName = nameMatch.group(1)?.trim() ?? 'Unknown';
          // Extract last name only
          userName = userName.split(' ').isNotEmpty ? userName.split(' ').last : userName;
        }
      }
      _leavesPerUser[userName] = (_leavesPerUser[userName] ?? 0) + 1;
    }

    _leavesOverTime = {};
    for (var leave in _leaves) {
      final date = DateTime(leave.startDate.year, leave.startDate.month);
      _leavesOverTime[date] = (_leavesOverTime[date] ?? 0) + 1;
    }

    _leavesByStatus = {};
    for (var leave in _leaves) {
      final status = leave.status ?? 'Unknown';
      final date = DateTime(leave.startDate.year, leave.startDate.month);
      if (!_leavesByStatus.containsKey(status)) {
        _leavesByStatus[status] = {};
      }
      _leavesByStatus[status]![date] = (_leavesByStatus[status]![date] ?? 0) + 1;
    }
  }

  void _showAccessDenied() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_currentUserRole == 'ENGINEER' || _currentUserRole == 'LAB-MANAGER')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Access to Leave Dashboard is restricted to Admin and Assistant roles.',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF6F61),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.pop(context);
              },
            ),
          ),
        );
      }
    });
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
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              )
            : _currentUserRole == 'LAB-MANAGER'
                ? LabManagerSidebar(
                    currentIndex: _currentIndex,
                    onTabChange: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                  )
                : _currentUserRole == 'ENGINEER'
                    ? EngineerSidebar(
                        currentIndex: _currentIndex,
                        onTabChange: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                      )
                    : AssistantSidebar(
                        currentIndex: _currentIndex,
                        onTabChange: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
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
            : (_currentUserRole == 'ENGINEER' || _currentUserRole == 'LAB-MANAGER')
                ? Center(
                    child: Text(
                      'Access Denied: Leave Dashboard is only available for Admin and Assistant roles.',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w500,
                        color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.center,
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
                                    'Leave Insights',
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
          _buildSummaryCard(
            title: 'Total Leaves',
            value: _leaves.length.toString(),
            icon: Icons.event,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            title: 'Pending Leaves',
            value: _leaves.where((leave) => leave.status == 'Pending').length.toString(),
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
              'Leave Type Distribution',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth * 0.6,
                          child: PieChart(
                            PieChartData(
                              sections: _leaveTypeDistribution.entries.where((entry) => _typeVisibility[entry.key] ?? true).map((entry) {
                                final index = _leaveTypeDistribution.keys.toList().indexOf(entry.key);
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
                        SizedBox(
                          width: constraints.maxWidth * 0.4,
                          child: SingleChildScrollView(
                            child: _buildLegend(
                              items: _leaveTypeDistribution.keys.map((key) => LegendItem(
                                    label: key,
                                    isVisible: _typeVisibility[key] ?? true,
                                    onTap: () {
                                      setState(() {
                                        _typeVisibility[key] = !(_typeVisibility[key] ?? true);
                                      });
                                    },
                                  )).toList(),
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
              'Leaves per User',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
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
                  barGroups: _leavesPerUser.entries.where((entry) => _userVisibility[entry.key] ?? true).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: user.value.toDouble(),
                          color: _getChartColor(index),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: _userTooltipVisibility[user.key] ?? false ? [0] : [],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final userName = _leavesPerUser.keys.elementAt(value.toInt());
                          if (_userVisibility[userName] ?? true) {
                            return SideTitleWidget(
                              child: Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
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
                        final userName = _leavesPerUser.keys.elementAt(group.x.toInt());
                        if (_userVisibility[userName] ?? true) {
                          return BarTooltipItem(
                            '$userName\n${rod.toY.toInt()} Leaves',
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
                        final userName = _leavesPerUser.keys.elementAt(barTouchResponse.spot!.touchedBarGroupIndex);
                        setState(() {
                          _userTooltipVisibility[userName] = !(_userTooltipVisibility[userName] ?? false);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _leavesPerUser.keys.map((key) => LegendItem(
                    label: key,
                    isVisible: _userVisibility[key] ?? true,
                    onTap: () {
                      setState(() {
                        _userVisibility[key] = !(_userVisibility[key] ?? true);
                      });
                    },
                  )).toList(),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(bool isSmallScreen) {
    final uniqueDates = _leavesOverTime.keys.toList()..sort((a, b) => a.compareTo(b));
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
              'Leaves Over Time',
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
                        return FlSpot(index.toDouble(), _leavesOverTime[date]!.toDouble());
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
                        interval: 1,
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
                  minX: 0,
                  maxX: uniqueDates.where((date) => _selectedMonths.contains(date)).length > 0
                      ? uniqueDates.where((date) => _selectedMonths.contains(date)).length - 1
                      : 0,
                  minY: 0,
                  maxY: _leavesOverTime.values.isNotEmpty
                      ? _leavesOverTime.values.reduce((a, b) => a > b ? a : b) * 1.1
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
                                '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} Leaves',
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
              items: _leavesOverTime.keys.map((key) {
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
    final statuses = _leavesByStatus.keys.toList();
    final dates = _leavesByStatus.values
        .expand((e) => e.keys)
        .toSet()
        .toList()
      ..sort((a, b) => a.compareTo(b));

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
              'Leaves by Status',
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
                    final visibleStatuses = statuses.where((status) => _statusVisibility[status] ?? true).toList();
                    final totalHeight = visibleStatuses.fold(0.0, (sum, status) => sum + (_leavesByStatus[status]![date] ?? 0).toDouble());
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: totalHeight,
                          rodStackItems: visibleStatuses.asMap().entries.map((statusEntry) {
                            final statusIndex = statusEntry.key;
                            final status = statusEntry.value;
                            return BarChartRodStackItem(
                              0,
                              (_leavesByStatus[status]![date] ?? 0).toDouble(),
                              _getChartColor(statusIndex),
                            );
                          }).toList(),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                      showingTooltipIndicators: _statusTooltipVisibility[statuses[index]] ?? false ? [0] : [],
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
                          '${DateFormat('MMM yyyy').format(date)}\n${rod.toY.toInt()} Leaves',
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
                        final statusIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                        final status = statuses[statusIndex];
                        setState(() {
                          _statusTooltipVisibility[status] = !(_statusTooltipVisibility[status] ?? false);
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _leavesByStatus.keys.map((key) {
                return LegendItem(
                  label: key,
                  isVisible: _statusVisibility[key] ?? true,
                  onTap: () {
                    setState(() {
                      _statusVisibility[key] = !(_statusVisibility[key] ?? true);
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
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
      ),
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