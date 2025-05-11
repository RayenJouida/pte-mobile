import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pte_mobile/screens/feed/all_posts_screen.dart';
import 'package:pte_mobile/screens/feed/manage_posts_screen.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class PostsDashboardScreen extends StatefulWidget {
  const PostsDashboardScreen({Key? key}) : super(key: key);

  @override
  _PostsDashboardScreenState createState() => _PostsDashboardScreenState();
}

class _PostsDashboardScreenState extends State<PostsDashboardScreen> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;
  Map<String, int> _statusDistribution = {};
  Map<String, int> _postsPerUser = {};
  Map<DateTime, int> _postsOverTime = {};
  Map<String, Map<DateTime, int>> _postsByStatus = {};

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
      final postsData = await _postService.getAllPosts();
      setState(() {
        _posts = postsData;
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
    // Status Distribution
    _statusDistribution = {};
    for (var post in _posts) {
      final status = post.status;
      _statusDistribution[status] = (_statusDistribution[status] ?? 0) + 1;
    }

    // Posts per User
    _postsPerUser = {};
    for (var post in _posts) {
      final userName = '${post.user.firstName} ${post.user.lastName}';
      _postsPerUser[userName] = (_postsPerUser[userName] ?? 0) + 1;
    }

    // Posts Over Time
    _postsOverTime = {};
    for (var post in _posts) {
      final date = DateTime(post.date.year, post.date.month);
      _postsOverTime[date] = (_postsOverTime[date] ?? 0) + 1;
    }

    // Posts by Status Over Time
    _postsByStatus = {};
    for (var post in _posts) {
      final status = post.status;
      final date = DateTime(post.date.year, post.date.month);
      if (!_postsByStatus.containsKey(status)) {
        _postsByStatus[status] = {};
      }
      _postsByStatus[status]![date] = (_postsByStatus[status]![date] ?? 0) + 1;
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
                    automaticallyImplyLeading: false,
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
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const Spacer(),
                                Text(
                                  'Posts Insights',
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
                                        builder: (context) => AllPostsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Total Posts: ${_posts.length}',
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
                                        builder: (context) => ManagePostsScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Pending: ${_statusDistribution['Pending'] ?? 0}',
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
                  MaterialPageRoute(builder: (context) => AllPostsScreen()),
                );
              },
              child: _buildSummaryCard(
                title: 'Total Posts',
                value: _posts.length.toString(),
                icon: Icons.feed,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ManagePostsScreen()),
                );
              },
              child: _buildSummaryCard(
                title: 'Pending Posts',
                value: (_statusDistribution['Pending'] ?? 0).toString(),
                icon: Icons.pending,
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
              'Status Distribution',
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
                  sections: _statusDistribution.entries.map((entry) {
                    final index = _statusDistribution.keys.toList().indexOf(entry.key);
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
              'Posts per User',
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
                  barGroups: _postsPerUser.entries.toList().asMap().entries.map((entry) {
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
                      showingTooltipIndicators: [0],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final userName = _postsPerUser.keys.elementAt(value.toInt());
                          final label = userName.length > 8 ? '${userName.substring(0, 8)}...' : userName;
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
                        final userName = _postsPerUser.keys.elementAt(group.x.toInt());
                        return BarTooltipItem(
                          '$userName\n${rod.toY.toInt()} Posts',
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
              'Posts Over Time',
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
                      spots: _postsOverTime.entries.toList().asMap().entries.map((entry) {
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
                          final date = _postsOverTime.keys.elementAt(value.toInt());
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
                          final date = _postsOverTime.keys.elementAt(spot.x.toInt());
                          return LineTooltipItem(
                            '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} Posts',
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
    final statuses = _postsByStatus.keys.toList();
    final dates = _postsByStatus.values
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
              'Posts by Status Over Time',
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
                          toY: statuses.fold(0, (sum, status) => sum + (_postsByStatus[status]![date] ?? 0).toDouble()),
                          rodStackItems: statuses.asMap().entries.map((statusEntry) {
                            final statusIndex = statusEntry.key;
                            final status = statusEntry.value;
                            return BarChartRodStackItem(
                              0,
                              (_postsByStatus[status]![date] ?? 0).toDouble(),
                              _getChartColor(statusIndex),
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
                          '${DateFormat('MMM yyyy').format(date)}\n${rod.toY.toInt()} Posts',
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
              children: statuses.asMap().entries.map((entry) {
                final status = entry.value;
                final index = entry.key;
                return Chip(
                  label: Text(
                    status,
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