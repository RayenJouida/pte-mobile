import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pte_mobile/screens/labmanager/lab_request.dart';
import 'package:pte_mobile/screens/labmanager/request_lab.dart';
import 'package:pte_mobile/services/virtualization_env_service.dart';
import 'package:pte_mobile/services/auth_service.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:pte_mobile/widgets/lab_manager_navbar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class HomeLabScreen extends StatefulWidget {
  const HomeLabScreen({Key? key}) : super(key: key);

  @override
  _HomeLabScreenState createState() => _HomeLabScreenState();
}

class _HomeLabScreenState extends State<HomeLabScreen> {
  int _currentIndex = 1;
  final VirtualizationEnvService _envService = VirtualizationEnvService();
  final AuthService _authService = AuthService();

  // Stats variables
  int _totalLabs = 0;
  int _activeLabs = 0;
  int _pendingRequests = 0;
  int _expiredLabs = 0;
  int _upcomingExpirations = 0;
  double _activeLabsPercentage = 0.0;
  double _avgLabDuration = 0.0;
  Map<String, int> _requestsByUser = {};
  Map<String, String> _userNames = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch all virtualization environments
      final allEnvs = await _envService.getAllVirtualizationEnvs();
      final activeLabs = await _envService.getActiveLabs();
      final now = DateTime.now();
      final oneWeekFromNow = now.add(const Duration(days: 7));

      // Calculate stats
      final totalLabs = allEnvs.length;
      final activeLabsCount = activeLabs.length;
      final pendingRequests = allEnvs.where((env) => env.status == 'Pending' && !env.isAccepted).length;
      final expiredLabs = allEnvs.where((env) => env.end.isBefore(now) && env.status != 'Expired').length;
      final upcomingExpirations = allEnvs.where((env) =>
          env.status == 'Active' &&
          env.isAccepted &&
          env.end.isAfter(now) &&
          env.end.isBefore(oneWeekFromNow)).length;

      // Calculate average lab duration for active labs
      final activeDurations = activeLabs
          .map((env) => env.end.difference(env.start).inDays)
          .where((duration) => duration > 0);
      final avgLabDuration = activeDurations.isNotEmpty
          ? activeDurations.reduce((a, b) => a + b) / activeDurations.length
          : 0.0;

      // Calculate requests by user
      final requestsByUser = <String, int>{};
      for (var env in allEnvs) {
        final userId = env.applicantId;
        if (userId.isNotEmpty) {
          requestsByUser[userId] = (requestsByUser[userId] ?? 0) + 1;
        }
      }

      // Fetch user names for the top 5 users by request count
      final userNames = <String, String>{};
      final topUsers = requestsByUser.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (var entry in topUsers.take(5)) {
        try {
          final user = await _authService.fetchUser(entry.key);
          if (user != null) {
            userNames[entry.key] = '${user.firstName} ${user.lastName}';
          } else {
            userNames[entry.key] = 'User ${entry.key.substring(0, 6)}';
          }
        } catch (e) {
          userNames[entry.key] = 'User ${entry.key.substring(0, 6)}';
        }
      }

      final activeLabsPercentage = totalLabs > 0 ? (activeLabsCount / totalLabs * 100) : 0.0;

      setState(() {
        _totalLabs = totalLabs;
        _activeLabs = activeLabsCount;
        _pendingRequests = pendingRequests;
        _expiredLabs = expiredLabs;
        _upcomingExpirations = upcomingExpirations;
        _activeLabsPercentage = activeLabsPercentage;
        _avgLabDuration = avgLabDuration;
        _requestsByUser = requestsByUser;
        _userNames = userNames;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load stats: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToLabRequest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RequestLabScreen()),
    );
  }

  void _navigateToSeeAllRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LabRequestsScreen()),
    );
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColorScheme.surfaceVariant,
      drawer: LabManagerSidebar(
        currentIndex: _currentIndex + 3,
        onTabChange: _onTabChange,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, size: 28),
                color: lightColorScheme.onPrimary,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Lab Control Hub',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: lightColorScheme.onPrimary,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      lightColorScheme.primary,
                      lightColorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildQuickActionsCard(context),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.check_circle,
                        title: 'Active Labs',
                        count: _activeLabs,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        icon: Icons.hourglass_empty,
                        title: 'Pending Requests',
                        count: _pendingRequests,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatsCard(),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Powered by Prologic',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: lightColorScheme.onSurface.withOpacity(0.5),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LabManagerNavbar(
        currentIndex: _currentIndex,
        onTabChange: _onTabChange,
        unreadMessageCount: 0,
        unreadNotificationCount: 0,
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _navigateToLabRequest(context),
                    icon: const Icon(Icons.add_circle, size: 22),
                    label: const Text('Request New Lab'),
                    style: FilledButton.styleFrom(
                      backgroundColor: lightColorScheme.primary,
                      foregroundColor: lightColorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      minimumSize: const Size(0, 60),
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _navigateToSeeAllRequests(context),
                    icon: const Icon(Icons.visibility, size: 22),
                    label: const Text('Show All Requests'),
                    style: FilledButton.styleFrom(
                      backgroundColor: lightColorScheme.primary,
                      foregroundColor: lightColorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      minimumSize: const Size(0, 60),
                    ),
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lightColorScheme.outline.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: lightColorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildStatsCard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lab Stats',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _buildStatItem('Total Labs', '$_totalLabs', Icons.computer),
                _buildStatItem('Active Labs', '$_activeLabs', Icons.check_circle, color: Colors.green),
                _buildStatItem('Pending', '$_pendingRequests', Icons.hourglass_empty, color: Colors.orange),
                _buildStatItem('Expired Labs', '$_expiredLabs', Icons.timer_off, color: Colors.red),
                _buildStatItem('Upcoming Expirations', '$_upcomingExpirations', Icons.event, color: Colors.blue),
                _buildStatItem('Avg Duration (Days)', _avgLabDuration.toStringAsFixed(1), Icons.schedule),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Requests by User',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: lightColorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (_requestsByUser.values.isNotEmpty
                          ? _requestsByUser.values.reduce((a, b) => a > b ? a : b)
                          : 1)
                      .toDouble() +
                      2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final userId = _requestsByUser.keys.toList()[groupIndex];
                        final userName = _userNames[userId] ?? 'Unknown';
                        return BarTooltipItem(
                          '$userName\n${rod.toY.toInt()} requests',
                          GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 || value.toInt() >= _requestsByUser.length) {
                            return const SizedBox.shrink();
                          }
                          final userId = _requestsByUser.keys.toList()[value.toInt()];
                          final userName = _userNames[userId]?.split(' ')[0] ?? 'Unknown';
                          return SideTitleWidget(
                            space: 8,
                            angle: 45 * math.pi / 180, // Rotate 45 degrees
                            child: SizedBox(
                              width: 50, // Constrain width to prevent overlap
                              child: Text(
                                userName,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: lightColorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            meta: meta,
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: lightColorScheme.onSurface,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _requestsByUser.entries.toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final count = entry.value.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          color: lightColorScheme.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem(String title, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color ?? lightColorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: lightColorScheme.onSurface.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color ?? lightColorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 450.ms).scale();
  }
}