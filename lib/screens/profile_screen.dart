import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/edit_profile_screen.dart';
import 'package:pte_mobile/screens/feed/post_details.dart';
import 'package:pte_mobile/screens/settings_screen.dart';
import 'package:pte_mobile/screens/cv/cv_management_screen.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/widgets/assistant_navbar.dart';
import 'package:pte_mobile/widgets/engineer_navbar.dart';
import 'package:pte_mobile/widgets/lab_manager_navbar.dart';
import 'package:pte_mobile/widgets/admin_navbar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/theme.dart';
import '../config/env.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  User? user;
  bool isLoading = true;
  String? errorMessage;
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  List<Post> userPosts = [];
  List<Post> likedPosts = [];
  List<Post> savedPosts = [];
  int postCount = 0;
  int savedCount = 0;
  int likesCount = 0;
  String? _userRole;
  int _currentIndex = 2;
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserDetailsAndPosts();
    _loadUserRole();
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 180 && !_showAppBarTitle) {
        setState(() {
          _showAppBarTitle = true;
        });
      } else if (_scrollController.offset <= 180 && _showAppBarTitle) {
        setState(() {
          _showAppBarTitle = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole');
    });
  }

  Future<void> _fetchUserDetailsAndPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('No user ID found');

      final userData = await _userService.getUserById(userId);
      final posts = await _postService.getUserPosts(userId);
      final saved = await _postService.getUserSavedPosts(userId);

      // Filter userPosts to show only Approved posts
      final approvedPosts = posts.where((post) => post.status == 'Approved').toList();

      int totalLikes = 0;
      for (var post in posts) {
        totalLikes += post.likes.length;
      }

      final allPosts = await _postService.getAllApprovedPosts();
      final likedFromAll = allPosts.where((post) => 
        post.likes.any((like) => like.user == userId)).toList();

      List<Post> liked = likedFromAll;
      if (liked.isEmpty && totalLikes > 0) {
        try {
          liked = await _postService.getUserLikedPosts(userId);
        } catch (e) {
          liked = posts.where((post) => 
            post.likes.any((like) => like.user == userId)).toList();
        }
      }

      if (mounted) {
        setState(() {
          user = User.fromJson(userData);
          userPosts = approvedPosts;
          savedPosts = saved;
          likedPosts = liked;
          postCount = approvedPosts.length;
          savedCount = saved.length;
          likesCount = totalLikes;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to load profile: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await _fetchUserDetailsAndPosts();
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0632A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen()),
    );
  }

  String _getFlagEmoji(String? nationality) {
    if (nationality == null) return '🌍';
    switch (nationality.toLowerCase()) {
      case 'tunisia': return '🇹🇳';
      case 'usa': return '🇺🇸';
      case 'france': return '🇫🇷';
      case 'argentina': return '🇦🇷';
      default: return '🌍';
    }
  }

  IconData _getGenderIcon(String? gender) {
    if (gender == null) return FontAwesomeIcons.genderless;
    switch (gender.toLowerCase()) {
      case 'male': return FontAwesomeIcons.mars;
      case 'female': return FontAwesomeIcons.venus;
      default: return FontAwesomeIcons.genderless;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Color(0xFF0632A1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Center(
                  child: Text(
                    'About ${user?.firstName ?? 'User'}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow(FontAwesomeIcons.idCard, 'Matricule', user?.matricule ?? 'N/A'),
                    _buildInfoRow(FontAwesomeIcons.phone, 'Phone', user?.phone ?? 'N/A'),
                    _buildInfoRow(FontAwesomeIcons.building, 'departement', user?.departement ?? 'N/A'),
                    _buildInfoRow(FontAwesomeIcons.briefcase, 'Experience', '${user?.experience ?? 'N/A'} years'),
                    _buildInfoRow(FontAwesomeIcons.envelope, 'Email', user?.email ?? 'N/A'),
                    if (user?.address != null && user!.address!.isNotEmpty)
                      _buildInfoRow(FontAwesomeIcons.locationDot, 'Address', user?.address ?? 'N/A'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF0632A1),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _onTabChange(int index) {
    if (index != _currentIndex) setState(() => _currentIndex = index);
  }

  void _viewPostDetails(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
    );
  }

  Future<void> _navigateToCvManagement() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final token = prefs.getString('authToken');
    if (userId != null && token != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CVManagementScreen(userId: userId, token: token),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication details not found')),
      );
    }
  }

  Future<void> _launchURL(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No URL provided')),
      );
      return;
    }

    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }

    try {
      final uri = Uri.parse(formattedUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else if (await canLaunch(formattedUrl)) {
        await launch(
          formattedUrl,
          forceSafariVC: false,
          forceWebView: false,
        );
      } else {
        throw 'No browser available';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF0632A1),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshProfile,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0632A1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: AnimatedOpacity(
          opacity: _showAppBarTitle ? 1.0 : 0.0,
          duration: Duration(milliseconds: 200),
          child: Text(
            '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
            style: TextStyle(
              color: Color(0xFF0632A1),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Color(0xFF0632A1), size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Color(0xFF0632A1), size: 22),
            onPressed: _goToSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFF0632A1), size: 22),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      drawer: _userRole == 'ADMIN'
        ? AdminSidebar(
            currentIndex: _currentIndex,
            onTabChange: _onTabChange,
          )
        : _userRole == 'LAB-MANAGER'
          ? LabManagerSidebar(
              currentIndex: _currentIndex,
              onTabChange: _onTabChange,
            )
          : _userRole == 'ENGINEER'
            ? EngineerSidebar(
                currentIndex: _currentIndex,
                onTabChange: _onTabChange,
              )
            : AssistantSidebar(
                currentIndex: _currentIndex,
                onTabChange: _onTabChange,
              ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: Color(0xFF0632A1),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF0632A1), Color(0xFF3D6DFF)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF0632A1).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(3),
                                child: ClipOval(
                                  child: user?.image != null && user!.image!.isNotEmpty
                                      ? Image.network(
                                          '${Env.userImageBaseUrl}${user!.image!}',
                                          width: 94,
                                          height: 94,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: Colors.grey.shade200,
                                            child: Icon(
                                              Icons.person,
                                              size: 40,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        )
                                      : Image.asset(
                                          'assets/images/default_avatar.png',
                                          width: 94,
                                          height: 94,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              if (user?.isEnabled == "Active")
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn('Posts', postCount.toString()),
                                  _buildVerticalDivider(),
                                  _buildStatColumn('Saved', savedCount.toString()),
                                  _buildVerticalDivider(),
                                  _buildStatColumn('Likes', likesCount.toString()),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user?.firstName ?? 'Unknown'} ${user?.lastName ?? ''}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800
                            ),
                          ).animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
                          if (user?.bio != null && user!.bio!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                user!.bio!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ).animate().fade(duration: 500.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(_getGenderIcon(user?.gender),
                                      color: Color(0xFF0632A1), size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      user?.gender ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text(
                                      _getFlagEmoji(user?.nationality),
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      user?.nationality ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                               ),
                                if (user?.email != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.email_outlined,
                                          color: Color(0xFF0632A1), size: 16),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            user!.email!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().fade(duration: 600.ms, delay: 200.ms),
                        ],
                      ),
                    ),
                    if ((user?.cv != null) || (user?.github != null) || (user?.linkedin != null))
                      Container(
                        margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (user?.cv != null)
                              _buildSocialLink(FontAwesomeIcons.fileLines, 'CV', Colors.blue.shade700, onTap: _navigateToCvManagement),
                            if (user?.github != null)
                              _buildSocialLink(FontAwesomeIcons.github, 'GitHub', Colors.black87, onTap: () => _launchURL(user?.github)),
                            if (user?.linkedin != null)
                              _buildSocialLink(FontAwesomeIcons.linkedin, 'LinkedIn', Colors.blue.shade800, onTap: () => _launchURL(user?.linkedin)),
                          ],
                        ),
                      ).animate().fade(duration: 700.ms, delay: 300.ms),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showAboutDialog(context),
                              icon: Icon(Icons.info_outline, size: 18),
                              label: Text('About', style: TextStyle(fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF0632A1),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 2,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => EditProfileScreen(user: user!))
                              ).then((_) => _refreshProfile()),
                              icon: Icon(Icons.edit_outlined, size: 18),
                              label: Text('Edit Profile', style: TextStyle(fontSize: 15)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Color(0xFF0632A1),
                                side: BorderSide(color: Color(0xFF0632A1), width: 1.5),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 800.ms, delay: 400.ms),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF0632A1),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: Color(0xFF0632A1),
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  tabs: [
                    Tab(
                      icon: Icon(FontAwesomeIcons.images, size: 16),
                      text: 'Posts',
                    ),
                    Tab(
                      icon: Icon(FontAwesomeIcons.heart, size: 16),
                      text: 'Liked',
                    ),
                    Tab(
                      icon: Icon(FontAwesomeIcons.bookmark, size: 16),
                      text: 'Saved',
                    ),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostGrid(userPosts),
                  _buildPostGrid(likedPosts),
                  _buildPostGrid(savedPosts),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _userRole == 'ADMIN'
          ? AdminNavbar(
              currentIndex: _currentIndex,
              onTabChange: _onTabChange,
              unreadMessageCount: 0,
              unreadNotificationCount: 0,
            )
          : _userRole == 'LAB-MANAGER'
              ? LabManagerNavbar(
                  currentIndex: _currentIndex,
                  onTabChange: _onTabChange,
                  unreadMessageCount: 0,
                  unreadNotificationCount: 0,
                )
              : _userRole == 'ENGINEER'
                  ? EngineerNavbar(
                      currentIndex: _currentIndex,
                      onTabChange: _onTabChange,
                      unreadMessageCount: 0,
                      unreadNotificationCount: 0,
                    )
                  : AssistantNavbar(
                      currentIndex: _currentIndex,
                      onTabChange: _onTabChange,
                      unreadMessageCount: 0,
                      unreadNotificationCount: 0,
                    ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0632A1)
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLink(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF0632A1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF0632A1), size: 16),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(List<Post> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF0632A1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                posts == userPosts
                    ? FontAwesomeIcons.images
                    : posts == likedPosts
                        ? FontAwesomeIcons.heart
                        : FontAwesomeIcons.bookmark,
                size: 30,
                color: Color(0xFF0632A1),
              ),
            ),
            SizedBox(height: 16),
            Text(
              posts == userPosts
                  ? 'No posts yet'
                  : posts == likedPosts
                      ? 'No liked posts'
                      : 'No saved posts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              posts == userPosts
                  ? 'Share your first post!'
                  : posts == likedPosts
                      ? 'Like posts to Show them here'
                      : 'Save posts for later viewing',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => _viewPostDetails(post),
          child: Hero(
            tag: 'post_${post.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    post.images.isNotEmpty
                        ? Image.network(
                            '${Env.imageBaseUrl}${post.images.first}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey.shade400,
                                  size: 30,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.description,
                              color: Colors.grey.shade400,
                              size: 30,
                            ),
                          ),
                    if (post.likes.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 2),
                              Text(
                                '${post.likes.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}