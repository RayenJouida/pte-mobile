import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/like.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:pte_mobile/models/user.dart'; // Added for User model
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostsDashboardScreen extends StatefulWidget {
  const PostsDashboardScreen({Key? key}) : super(key: key);

  @override
  _PostsDashboardScreenState createState() => _PostsDashboardScreenState();
}

class _PostsDashboardScreenState extends State<PostsDashboardScreen> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  List<Like> _likes = [];
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isDarkMode = false;
  Map<String, int> _statusDistribution = {};
  Map<String, int> _likesPerPost = {};
  Map<DateTime, int> _commentsOverTime = {};
  Map<String, Map<DateTime, int>> _interactionsByUser = {};
  String? _currentUserRole;

  // Maps to track legend visibility
  Map<String, bool> _statusVisibility = {};
  Map<String, bool> _postVisibility = {};
  Map<DateTime, bool> _timeVisibility = {};
  Map<String, bool> _userVisibility = {};

  @override
  void initState() {
    debugPrint('initState: Starting initialization');
    super.initState();
    _fetchCurrentUserRole();
    _fetchData();
    debugPrint('initState: Initialization complete');
  }

  Future<void> _fetchCurrentUserRole() async {
    debugPrint('fetchCurrentUserRole: Starting');
    final prefs = await SharedPreferences.getInstance();
    debugPrint('fetchCurrentUserRole: Prefs instance created');
    setState(() {
      debugPrint('fetchCurrentUserRole: Setting _currentUserRole');
      _currentUserRole = prefs.getString('userRole') ?? 'Unknown Role';
      debugPrint('fetchCurrentUserRole: Role set to $_currentUserRole');
    });
    debugPrint('fetchCurrentUserRole: Completed');
  }

  Future<void> _fetchData() async {
    debugPrint('_fetchData: Starting data fetch');
    setState(() {
      debugPrint('_fetchData: Setting _isLoading to true');
      _isLoading = true;
    });
    try {
      debugPrint('_fetchData: Calling getAllPostsWithStats');
      final postsData = await _postService.getAllPostsWithStats();
      debugPrint('_fetchData: Received postsData length ${postsData.length}');
      debugPrint('_fetchData: Calling getPostInteractionCount for each post');
      final likesData = (await Future.wait(postsData.map((post) => _postService.getPostInteractionCount(post.id))))
          .expand((counts) => List.generate(counts['likesCount'] ?? 0, (_) => Like(id: '', user: User(id: '', matricule: '', firstName: '', lastName: '', email: '', roles: [], isEnabled: 'Inactive', experience: 0), post: '', createdAt: DateTime.now(), updatedAt: DateTime.now())))
          .toList();
      debugPrint('_fetchData: Received likesData length ${likesData.length}');
      debugPrint('_fetchData: Calling getPostComments for each post');
      final commentsData = (await Future.wait(postsData.map((post) => _postService.getPostComments(post.id))))
          .expand((comments) => comments)
          .toList();
      debugPrint('_fetchData: Received commentsData length ${commentsData.length}');
      setState(() {
        debugPrint('_fetchData: Updating state with new data');
        _posts = postsData;
        _likes = likesData;
        _comments = commentsData;
        _processData();
        _isLoading = false;
        _statusVisibility = Map.fromEntries(_statusDistribution.keys.map((key) => MapEntry(key, true)));
        _postVisibility = Map.fromEntries(_likesPerPost.keys.map((key) => MapEntry(key, true)));
        _timeVisibility = Map.fromEntries(_commentsOverTime.keys.map((key) => MapEntry(key, true)));
        _userVisibility = Map.fromEntries(_interactionsByUser.keys.map((key) => MapEntry(key, true)));
        debugPrint('_fetchData: State updated - posts: ${_posts.length}, likes: ${_likes.length}, comments: ${_comments.length}');
      });
    } catch (e) {
      debugPrint('_fetchData: Error occurred - $e');
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
    debugPrint('_fetchData: Data fetch completed');
  }

  void _processData() {
    debugPrint('_processData: Starting data processing');
    _statusDistribution = {};
    for (var post in _posts) {
      debugPrint('_processData: Processing post ${post.id} with status ${post.status}');
      _statusDistribution[post.status] = (_statusDistribution[post.status] ?? 0) + 1;
    }
    debugPrint('_processData: Status distribution - $_statusDistribution');

    _likesPerPost = {};
    for (var post in _posts) {
      debugPrint('_processData: Processing likes for post ${post.id}');
      _likesPerPost[post.id] = post.likes.length;
    }
    debugPrint('_processData: Likes per post - $_likesPerPost');

    _commentsOverTime = {};
    for (var comment in _comments) {
      debugPrint('_processData: Processing comment ${comment.id} from ${comment.createdAt}');
      final date = DateTime(comment.createdAt.year, comment.createdAt.month);
      _commentsOverTime[date] = (_commentsOverTime[date] ?? 0) + 1;
    }
    debugPrint('_processData: Comments over time - $_commentsOverTime');

    _interactionsByUser = {};
    for (var comment in _comments) {
      debugPrint('_processData: Processing interaction for user ${comment.user.id}');
      final userId = comment.user.id;
      final date = DateTime(comment.createdAt.year, comment.createdAt.month);
      if (!_interactionsByUser.containsKey(userId)) {
        _interactionsByUser[userId] = {};
      }
      _interactionsByUser[userId]![date] = (_interactionsByUser[userId]![date] ?? 0) + 1;
    }
    debugPrint('_processData: Interactions by user - $_interactionsByUser');
    debugPrint('_processData: Data processing completed');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build: Starting build with _isLoading: $_isLoading, _currentUserRole: $_currentUserRole');
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Theme(
      data: _isDarkMode ? _darkTheme() : _lightTheme(),
      child: Scaffold(
        drawer: _currentUserRole == 'ADMIN'
            ? AdminSidebar(
                currentIndex: 0,
                onTabChange: (index) {
                  debugPrint('build: AdminSidebar tab changed to $index');
                  setState(() {});
                },
              )
            : _currentUserRole == 'LAB-MANAGER'
                ? LabManagerSidebar(
                    currentIndex: 0,
                    onTabChange: (index) {
                      debugPrint('build: LabManagerSidebar tab changed to $index');
                      setState(() {});
                    },
                  )
                : _currentUserRole == 'ENGINEER'
                    ? EngineerSidebar(
                        currentIndex: 0,
                        onTabChange: (index) {
                          debugPrint('build: EngineerSidebar tab changed to $index');
                          setState(() {});
                        },
                      )
                    : AssistantSidebar(
                        currentIndex: 0,
                        onTabChange: (index) {
                          debugPrint('build: AssistantSidebar tab changed to $index');
                          setState(() {});
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
                        debugPrint('build: SliverAppBar layout built with constraints $constraints');
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
                                    debugPrint('build: Drawer opened');
                                    Scaffold.of(context).openDrawer();
                                  },
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Posts Insights',
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
    debugPrint('_lightTheme: Applying light theme');
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
    debugPrint('_darkTheme: Applying dark theme');
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
    debugPrint('_buildSummarySection: Building with isSmallScreen $isSmallScreen');
    return FadeInUp(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Posts',
              value: _posts.length.toString(),
              icon: Icons.post_add,
              isSmallScreen: isSmallScreen,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Likes',
              value: _likes.length.toString(),
              icon: Icons.favorite,
              isSmallScreen: isSmallScreen,
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
    debugPrint('_buildSummaryCard: Building card for $title with value $value');
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
    debugPrint('_buildChartSection: Building with isSmallScreen $isSmallScreen');
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
    debugPrint('_buildPieChart: Building with isSmallScreen $isSmallScreen');
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
              'Post Status Distribution',
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
                        sections: _statusDistribution.entries.where((entry) => _statusVisibility[entry.key] ?? true).map((entry) {
                          final index = _statusDistribution.keys.toList().indexOf(entry.key);
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
                      items: _statusDistribution.keys.map((key) => LegendItem(
                            label: key,
                            isVisible: _statusVisibility[key] ?? true,
                            onTap: () {
                              debugPrint('_buildPieChart: Legend tapped for $key');
                              setState(() {
                                _statusVisibility[key] = !(_statusVisibility[key] ?? true);
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
    debugPrint('_buildBarChart: Building with isSmallScreen $isSmallScreen');
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
              'Likes per Post',
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
                  barGroups: _likesPerPost.entries.where((entry) => _postVisibility[entry.key] ?? true).toList().asMap().entries.map((entry) {
                    final index = entry.key;
                    final post = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: post.value.toDouble(),
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
                          final postId = _likesPerPost.keys.elementAt(value.toInt());
                          if (_postVisibility[postId] ?? true) {
                            final post = _posts.firstWhere((p) => p.id == postId, orElse: () => Post(id: '', description: '', images: [], user: User(id: '', matricule: '', firstName: '', lastName: '', email: '', roles: [], isEnabled: 'Inactive', experience: 0), date: DateTime.now()));
                            return SideTitleWidget(
                              child: Text(
                                post.description.length > 10 ? '${post.description.substring(0, 10)}...' : post.description,
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
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => const Color(0xFF0632A1).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final postId = _likesPerPost.keys.elementAt(group.x.toInt());
                        if (_postVisibility[postId] ?? true) {
                          final post = _posts.firstWhere((p) => p.id == postId, orElse: () => Post(id: '', description: '', images: [], user: User(id: '', matricule: '', firstName: '', lastName: '', email: '', roles: [], isEnabled: 'Inactive', experience: 0), date: DateTime.now()));
                          return BarTooltipItem(
                            '${post.description.length > 10 ? '${post.description.substring(0, 10)}...' : post.description}\n${rod.toY.toInt()} Likes',
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
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(
              items: _likesPerPost.keys.map((key) {
                final post = _posts.firstWhere((p) => p.id == key, orElse: () => Post(id: '', description: '', images: [], user: User(id: '', matricule: '', firstName: '', lastName: '', email: '', roles: [], isEnabled: 'Inactive', experience: 0), date: DateTime.now()));
                return LegendItem(
                  label: post.description.length > 10 ? '${post.description.substring(0, 10)}...' : post.description,
                  isVisible: _postVisibility[key] ?? true,
                  onTap: () {
                    debugPrint('_buildBarChart: Legend tapped for $key');
                    setState(() {
                      _postVisibility[key] = !(_postVisibility[key] ?? true);
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
    debugPrint('_buildLineChart: Building with isSmallScreen $isSmallScreen');
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
              'Comments Over Time',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: isSmallScreen ? 180 : 200,
              child: _commentsOverTime.isEmpty
                  ? Center(
                      child: Text(
                        'No comments data available',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: _isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF1F2937),
                        ),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: _commentsOverTime.entries.where((entry) => _timeVisibility[entry.key] ?? true).map((entry) {
                              final index = _commentsOverTime.keys.toList().indexOf(entry.key);
                              return FlSpot(index.toDouble(), entry.value.toDouble());
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
                                if (_commentsOverTime.isNotEmpty) {
                                  final date = _commentsOverTime.keys.elementAt(value.toInt());
                                  if (_timeVisibility[date] ?? true) {
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
                                  }
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
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (spot) => const Color(0xFF0632A1).withOpacity(0.9),
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 8,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                if (_commentsOverTime.isNotEmpty) {
                                  final date = _commentsOverTime.keys.elementAt(spot.x.toInt());
                                  if (_timeVisibility[date] ?? true) {
                                    return LineTooltipItem(
                                      '${DateFormat('MMM yyyy').format(date)}\n${spot.y.toInt()} Comments',
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
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            _commentsOverTime.isEmpty
                ? const SizedBox.shrink()
                : _buildLegend(
                    items: _commentsOverTime.keys.map((key) {
                      return LegendItem(
                        label: DateFormat('MMM yyyy').format(key),
                        isVisible: _timeVisibility[key] ?? true,
                        onTap: () {
                          debugPrint('_buildLineChart: Legend tapped for $key');
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
    debugPrint('_buildStackedBarChart: Building with isSmallScreen $isSmallScreen');
    final users = _interactionsByUser.keys.toList();
    final dates = _interactionsByUser.values
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
              'Interactions by User',
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
                    final visibleUsers = users.where((user) => _userVisibility[user] ?? true).toList();
                    final totalHeight = visibleUsers.fold(0.0, (sum, user) => sum + (_interactionsByUser[user]![date] ?? 0).toDouble());
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: totalHeight,
                          rodStackItems: visibleUsers.asMap().entries.map((userEntry) {
                            final userIndex = userEntry.key;
                            final user = userEntry.value;
                            return BarChartRodStackItem(
                              0,
                              (_interactionsByUser[user]![date] ?? 0).toDouble(),
                              _getChartColor(userIndex),
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
                      getTooltipColor: (group) => const Color(0xFF0632A1).withOpacity(0.9),
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final date = dates[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('MMM yyyy').format(date)}\n${rod.toY.toInt()} Interactions',
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
            _buildLegend(
              items: _interactionsByUser.keys.map((key) {
                return LegendItem(
                  label: 'User $key',
                  isVisible: _userVisibility[key] ?? true,
                  onTap: () {
                    debugPrint('_buildStackedBarChart: Legend tapped for $key');
                    setState(() {
                      _userVisibility[key] = !(_userVisibility[key] ?? true);
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
    debugPrint('_buildLegend: Building with ${items.length} items');
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
    debugPrint('_getChartColor: Getting color for index $index');
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