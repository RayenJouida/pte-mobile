import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pte_mobile/screens/feed/all_posts_screen.dart';
import 'package:pte_mobile/screens/labmanager/lab_request.dart';
import 'package:pte_mobile/screens/labmanager/request_lab.dart';
import 'package:pte_mobile/screens/labmanager/requests_by_user_id.dart';
import 'package:pte_mobile/screens/room/all_rooms.dart';
import 'package:pte_mobile/screens/room/room_reservation_screen.dart';
import 'package:pte_mobile/screens/room/room_reservation_calendar_screen.dart';
import 'package:pte_mobile/screens/room/rooms_dashboard.dart';
import 'package:pte_mobile/screens/users/user_reservation_screen.dart';
import 'package:pte_mobile/widgets/theme_toggle_button.dart';
import 'package:pte_mobile/screens/profile_screen.dart';
import 'package:pte_mobile/screens/edit_profile_screen.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/users/all_users.dart';
import 'package:pte_mobile/screens/users/user_dashboard.dart';
import 'package:pte_mobile/screens/leave/leave_request_screen.dart';
import 'package:pte_mobile/screens/leave/my_leave_requests_screen.dart';
import 'package:pte_mobile/screens/leave/all_leave_requests.dart';
import 'package:pte_mobile/screens/leave/leave_dashboard.dart';
import 'package:pte_mobile/screens/feed/manage_posts_screen.dart';
import 'package:pte_mobile/screens/feed/posts_dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env.dart';

class AdminSidebar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const AdminSidebar({
    Key? key,
    required this.currentIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  _AdminSidebarState createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> with SingleTickerProviderStateMixin {
  bool _isUsersExpanded = false;
  bool _isRoomsExpanded = false;
  bool _isPostsExpanded = false;
  bool _isLabsExpanded = false;
  bool _isLeaveExpanded = false;
  late AnimationController _animationController;

  final Color primaryBlue = const Color(0xFF2563EB);
  final Color lightBlue = const Color(0xFFEFF6FF);
  final Color darkBlue = const Color(0xFF1E40AF);
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    if (widget.currentIndex >= 0 && widget.currentIndex <= 2) {
      _isUsersExpanded = true;
    } else if (widget.currentIndex >= 3 && widget.currentIndex <= 6) {
      _isRoomsExpanded = true;
    } else if (widget.currentIndex >= 7 && widget.currentIndex <= 9) {
      _isPostsExpanded = true;
    } else if (widget.currentIndex >= 10 && widget.currentIndex <= 12) {
      _isLabsExpanded = true;
    } else if (widget.currentIndex >= 13 && widget.currentIndex <= 16) {
      _isLeaveExpanded = true;
    }
  }

  @override
  void didUpdateWidget(AdminSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      setState(() {
        _isUsersExpanded = widget.currentIndex >= 0 && widget.currentIndex <= 2;
        _isRoomsExpanded = widget.currentIndex >= 3 && widget.currentIndex <= 6;
        _isPostsExpanded = widget.currentIndex >= 7 && widget.currentIndex <= 9;
        _isLabsExpanded = widget.currentIndex >= 10 && widget.currentIndex <= 12;
        _isLeaveExpanded = widget.currentIndex >= 13 && widget.currentIndex <= 16;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _navigateToPage(BuildContext context, Widget page, int index) async {
    Navigator.pop(context);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    if (result is int) {
      widget.onTabChange(result);
    }
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    Navigator.pop(context);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  Future<void> _navigateToEditProfile(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        return;
      }
      final userData = await _userService.getUserById(userId);
      final user = User.fromJson(userData);
      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditProfileScreen(user: user)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<int> _getReserveRoomIndex(String? role) async {
    final prefs = await SharedPreferences.getInstance();
    role = role ?? prefs.getString('userRole') ?? 'ASSISTANT';
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 4;
      case 'ENGINEER':
        return 3;
      case 'LAB-MANAGER':
        return 2;
      case 'ASSISTANT':
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 320,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  children: [
                    _buildNavItem(
                      context,
                      icon: LineIcons.users,
                      title: 'Users',
                      isExpanded: _isUsersExpanded,
                      onTap: () => setState(() {
                        _isUsersExpanded = !_isUsersExpanded;
                        if (_isUsersExpanded) {
                          _isRoomsExpanded = false;
                          _isPostsExpanded = false;
                          _isLabsExpanded = false;
                          _isLeaveExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.user,
                          title: 'Show Users',
                          isSelected: widget.currentIndex == 0,
                          onTap: () {
                            widget.onTabChange(0);
                            _navigateToPage(context, const AllUsersScreen(), 0);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.calendarCheck,
                          title: 'Book a Technician',
                          isSelected: widget.currentIndex == 1,
                          onTap: () {
                            widget.onTabChange(1);
                            _navigateToPage(context, const UserReservationScreen(), 1);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Users Dashboard',
                          isSelected: widget.currentIndex == 2,
                          onTap: () {
                            widget.onTabChange(2);
                            _navigateToPage(context, UserDashboardScreen(currentIndex: 2), 2);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: LineIcons.building,
                      title: 'Rooms',
                      isExpanded: _isRoomsExpanded,
                      onTap: () => setState(() {
                        _isRoomsExpanded = !_isRoomsExpanded;
                        if (_isRoomsExpanded) {
                          _isUsersExpanded = false;
                          _isPostsExpanded = false;
                          _isLabsExpanded = false;
                          _isLeaveExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.calendar,
                          title: 'Show Calendar',
                          isSelected: widget.currentIndex == 3,
                          onTap: () {
                            widget.onTabChange(3);
                            _navigateToPage(context, RoomReservationCalendarScreen(currentIndex: 3), 3);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.book,
                          title: 'Reserve Room',
                          isSelected: widget.currentIndex == 4,
                          onTap: () {
                            widget.onTabChange(4);
                            _navigateToPage(
                              context,
                              RoomReservationScreen(
                                currentIndex: 4,
                                onEventCreated: (event) {},
                                events: [],
                              ),
                              4,
                            );
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.cog,
                          title: 'Manage Rooms',
                          isSelected: widget.currentIndex == 5,
                          onTap: () {
                            widget.onTabChange(5);
                            _navigateToPage(context, AllRoomsScreen(currentIndex: 5), 5);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Rooms Dashboard',
                          isSelected: widget.currentIndex == 6,
                          onTap: () {
                            widget.onTabChange(6);
                            _navigateToPage(context, RoomsDashboardScreen(currentIndex: 6), 6);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: LineIcons.newspaper,
                      title: 'Posts',
                      isExpanded: _isPostsExpanded,
                      onTap: () => setState(() {
                        _isPostsExpanded = !_isPostsExpanded;
                        if (_isPostsExpanded) {
                          _isUsersExpanded = false;
                          _isRoomsExpanded = false;
                          _isLabsExpanded = false;
                          _isLeaveExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.eye,
                          title: 'Show All Posts',
                          isSelected: widget.currentIndex == 7,
                          onTap: () {
                            widget.onTabChange(7);
                            _navigateToPage(context, const AllPostsScreen(), 7);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.cog,
                          title: 'Manage Posts',
                          isSelected: widget.currentIndex == 8,
                          onTap: () {
                            widget.onTabChange(8);
                            _navigateToPage(context, const ManagePostsScreen(), 8);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Posts Dashboard',
                          isSelected: widget.currentIndex == 9,
                          onTap: () {
                            widget.onTabChange(9);
                            _navigateToPage(context, const PostsDashboardScreen(), 9);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: LineIcons.flask,
                      title: 'Labs',
                      isExpanded: _isLabsExpanded,
                      onTap: () => setState(() {
                        _isLabsExpanded = !_isLabsExpanded;
                        if (_isLabsExpanded) {
                          _isUsersExpanded = false;
                          _isRoomsExpanded = false;
                          _isPostsExpanded = false;
                          _isLeaveExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.plusCircle,
                          title: 'Request Lab',
                          isSelected: widget.currentIndex == 10,
                          onTap: () {
                            widget.onTabChange(10);
                            _navigateToPage(context, const RequestLabScreen(), 10);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.list,
                          title: 'Check My Requests',
                          isSelected: widget.currentIndex == 11,
                          onTap: () {
                            widget.onTabChange(11);
                            _navigateToPage(context, const RequestsByUserId(), 11);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.eye,
                          title: 'All Labs Requests',
                          isSelected: widget.currentIndex == 12,
                          onTap: () {
                            widget.onTabChange(12);
                            _navigateToPage(context, const LabRequestsScreen(), 12);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: LineIcons.calendarCheck,
                      title: 'Leave',
                      isExpanded: _isLeaveExpanded,
                      onTap: () => setState(() {
                        _isLeaveExpanded = !_isLeaveExpanded;
                        if (_isLeaveExpanded) {
                          _isUsersExpanded = false;
                          _isRoomsExpanded = false;
                          _isPostsExpanded = false;
                          _isLabsExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.plusCircle,
                          title: 'Leave Request',
                          isSelected: widget.currentIndex == 13,
                          onTap: () {
                            widget.onTabChange(13);
                            _navigateToPage(context, LeaveRequestScreen(currentIndex: 13), 13);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.list,
                          title: 'My Leave Requests',
                          isSelected: widget.currentIndex == 14,
                          onTap: () {
                            widget.onTabChange(14);
                            _navigateToPage(context, const MyLeaveRequestsScreen(), 14);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.list,
                          title: 'All Leave Requests',
                          isSelected: widget.currentIndex == 15,
                          onTap: () {
                            widget.onTabChange(15);
                            _navigateToPage(context, const AllLeaveRequestsScreen(), 15);
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Leave Dashboard',
                          isSelected: widget.currentIndex == 16,
                          onTap: () {
                            widget.onTabChange(16);
                            _navigateToPage(context, const LeaveDashboardScreen(), 16);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildThemeToggle(context),
                  ],
                ),
              ),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToProfile(context),
      onLongPress: () => _navigateToEditProfile(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryBlue, darkBlue],
          ),
        ),
        child: FutureBuilder<Map<String, String?>>(
          future: _getUserInfo(),
          builder: (context, snapshot) {
            final userName = snapshot.data?['userName'] ?? 'Admin';
            final userImage = snapshot.data?['userImage'];
            return Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.8), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: userImage != null
                        ? NetworkImage('${Env.userImageBaseUrl}$userImage')
                        : null,
                    child: userImage == null ? Icon(Icons.person, size: 40, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isExpanded ? lightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(icon, size: 26, color: isExpanded ? primaryBlue : Colors.black87),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpanded ? primaryBlue : Colors.black87,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(Icons.chevron_right, size: 24, color: isExpanded ? primaryBlue : Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: Column(children: children),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Stack(
                  children: [
                    Icon(icon, size: 22, color: isSelected ? primaryBlue : Colors.black54),
                    if (badgeCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            badgeCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryBlue : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryBlue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(LineIcons.alternateSignOut, size: 24),
        label: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFFEF4444).withOpacity(0.4),
        ),
      ),
    );
  }

  Future<Map<String, String?>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userName': prefs.getString('userName'),
      'userImage': prefs.getString('userImage'),
    };
  }

  Widget _buildThemeToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LineIcons.sun, size: 26, color: Colors.black87),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const ThemeToggleButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}