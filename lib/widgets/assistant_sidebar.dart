import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pte_mobile/models/user_event.dart';
import 'package:pte_mobile/screens/dashboard_screen.dart';
import 'package:pte_mobile/screens/leave/all_leave_requests.dart';
import 'package:pte_mobile/screens/room/all_rooms.dart';
import 'package:pte_mobile/screens/room/room_reservation_calendar_screen.dart';
import 'package:pte_mobile/screens/room/rooms_dashboard.dart';
import 'package:pte_mobile/screens/users/user_reservation_screen.dart';
import 'package:pte_mobile/screens/vehicules/vehicles_dashboard.dart';
import 'package:pte_mobile/widgets/theme_toggle_button.dart';
import 'package:pte_mobile/screens/profile_screen.dart';
import 'package:pte_mobile/screens/edit_profile_screen.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/users/all_users.dart';
import 'package:pte_mobile/screens/users/user_dashboard.dart';
import 'package:pte_mobile/screens/leave/leave_request_screen.dart';
import 'package:pte_mobile/screens/leave/my_leave_requests_screen.dart';
import 'package:pte_mobile/screens/leave/leave_dashboard.dart';
import 'package:pte_mobile/screens/resume_ranking_screen.dart';
import 'package:pte_mobile/screens/vehicules/all_vehicles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/env.dart';
import '../theme/theme.dart';

class AssistantSidebar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const AssistantSidebar({
    Key? key,
    required this.currentIndex,
    required this.onTabChange,
  }) : super(key: key);

  @override
  _AssistantSidebarState createState() => _AssistantSidebarState();
}

class _AssistantSidebarState extends State<AssistantSidebar> with SingleTickerProviderStateMixin {
  bool _isUsersExpanded = false;
  bool _isRoomsExpanded = false;
  bool _isLeaveExpanded = false;
  bool _isCVsExpanded = false;
  bool _isVehiclesExpanded = false;
  late AnimationController _animationController;
  bool? _isTeamLeader;
  List<UserEvent> _events = [];
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _updateExpandedStates(widget.currentIndex);
    _loadUserData();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    try {
      final fetchedEvents = await _userService.getAllUserEvents();
      setState(() {
        _events = fetchedEvents;
      });
    } catch (e) {
      print('Error fetching events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    }
  }

  @override
  void didUpdateWidget(AssistantSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _updateExpandedStates(widget.currentIndex);
    }
  }

  void _updateExpandedStates(int index) {
    setState(() {
      _isUsersExpanded = index >= 0 && index <= 2;
      _isRoomsExpanded = index >= 3 && index <= 5;
      _isVehiclesExpanded = index >= 6 && index <= 8;
      _isLeaveExpanded = index >= 9 && index <= (12 + (_isTeamLeader == true ? 1 : 0));
      _isCVsExpanded = index >= 13 && index <= (14 + (_isTeamLeader == true ? 1 : 0));
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId != null) {
      try {
        final userData = await _userService.getUserById(userId);
        final user = User.fromJson(userData);
        setState(() {
          _isTeamLeader = user.teamLeader;
          _updateExpandedStates(widget.currentIndex);
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
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
    widget.onTabChange(index);
  }

  Future<void> _navigateToEditProfile(BuildContext context, int index) async {
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
      await _navigateToPage(context, EditProfileScreen(user: user), index);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Drawer(
      width: 320,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
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
                      icon: LineIcons.home,
                      title: 'Dashboard',
                      isExpanded: false,
                      onTap: () => _navigateToPage(context, const DashboardScreen(), -1),
                      children: [],
                    ),
                    _buildNavItem(
                      context,
                      icon: LineIcons.users,
                      title: 'Users',
                      isExpanded: _isUsersExpanded,
                      onTap: () => setState(() {
                        _isUsersExpanded = !_isUsersExpanded;
                        if (_isUsersExpanded) {
                          _isRoomsExpanded = false;
                          _isVehiclesExpanded = false;
                          _isLeaveExpanded = false;
                          _isCVsExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.user,
                          title: 'Show Users',
                          isSelected: widget.currentIndex == 0,
                          onTap: () => _navigateToPage(context, const AllUsersScreen(), 0),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.calendarCheck,
                          title: 'Booking Schedule',
                          isSelected: widget.currentIndex == 1,
                          onTap: () => _navigateToPage(context, const UserReservationScreen(), 1),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Users Dashboard',
                          isSelected: widget.currentIndex == 2,
                          onTap: () => _navigateToPage(context, const UserDashboardScreen(), 2),
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
                          _isVehiclesExpanded = false;
                          _isLeaveExpanded = false;
                          _isCVsExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.calendar,
                          title: 'Show Calendar',
                          isSelected: widget.currentIndex == 3,
                          onTap: () async {
                            widget.onTabChange(3);
                            await _navigateToPage(
                              context,
                              RoomReservationCalendarScreen(currentIndex: 3),
                              3,
                            );
                          },
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.cog,
                          title: 'Manage Rooms',
                          isSelected: widget.currentIndex == 4,
                          onTap: () => _navigateToPage(context, AllRoomsScreen(currentIndex: 4), 4),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Rooms Dashboard',
                          isSelected: widget.currentIndex == 5,
                          onTap: () => _navigateToPage(context, RoomsDashboardScreen(currentIndex: 5), 5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: LineIcons.car,
                      title: 'Vehicles',
                      isExpanded: _isVehiclesExpanded,
                      onTap: () => setState(() {
                        _isVehiclesExpanded = !_isVehiclesExpanded;
                        if (_isVehiclesExpanded) {
                          _isUsersExpanded = false;
                          _isRoomsExpanded = false;
                          _isLeaveExpanded = false;
                          _isCVsExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.calendar,
                          title: 'Show Calendar',
                          isSelected: widget.currentIndex == 6,
                          onTap: () => _navigateToPage(context, const UserReservationScreen(), 6),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.cog,
                          title: 'Manage Vehicles',
                          isSelected: widget.currentIndex == 7,
                          onTap: () => _navigateToPage(context, AllVehiclesScreen(), 7),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Vehicles Dashboard',
                          isSelected: widget.currentIndex == 8,
                          onTap: () => _navigateToPage(context, const VehiclesDashboardScreen(currentIndex: 8), 8),
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
                          _isVehiclesExpanded = false;
                          _isCVsExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.plusCircle,
                          title: 'Leave Request',
                          isSelected: widget.currentIndex == 9,
                          onTap: () => _navigateToPage(context, const LeaveRequestScreen(), 9),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.list,
                          title: 'My Leave Requests',
                          isSelected: widget.currentIndex == 10,
                          onTap: () => _navigateToPage(context, const MyLeaveRequestsScreen(), 10),
                        ),
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.barChart,
                          title: 'Leave Dashboard',
                          isSelected: widget.currentIndex == 11,
                          onTap: () => _navigateToPage(context, const LeaveDashboardScreen(), 11),
                        ),
                        if (_isTeamLeader == true)
                          _buildSubNavItem(
                            context,
                            icon: LineIcons.userCheck,
                            title: 'Team Leave Requests',
                            isSelected: widget.currentIndex == 12,
                            onTap: () => _navigateToPage(context, const AllLeaveRequestsScreen(), 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: LineIcons.fileAlt,
                      title: 'CVs',
                      isExpanded: _isCVsExpanded,
                      onTap: () => setState(() {
                        _isCVsExpanded = !_isCVsExpanded;
                        if (_isCVsExpanded) {
                          _isUsersExpanded = false;
                          _isRoomsExpanded = false;
                          _isVehiclesExpanded = false;
                          _isLeaveExpanded = false;
                        }
                      }),
                      children: [
                        _buildSubNavItem(
                          context,
                          icon: LineIcons.fileUpload,
                          title: 'Rank CVs',
                          isSelected: widget.currentIndex == 13 + (_isTeamLeader == true ? 1 : 0),
                          onTap: () => _navigateToPage(context, ResumeRankingScreen(), 13 + (_isTeamLeader == true ? 1 : 0)),
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.primary,
      ),
      child: FutureBuilder<Map<String, String?>>(
        future: _getUserInfo(),
        builder: (context, snapshot) {
          final userName = snapshot.data?['userName'] ?? 'User';
          final userImage = snapshot.data?['userImage'];
          return Column(
            children: [
              GestureDetector(
                onTap: () => _navigateToPage(context, ProfileScreen(), 0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.onPrimary, width: 3),
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
                    backgroundColor: colorScheme.primary,
                    backgroundImage: userImage != null
                        ? NetworkImage('${Env.userImageBaseUrl}$userImage')
                        : null,
                    child: userImage == null 
                        ? Icon(Icons.person, size: 40, color: colorScheme.onPrimary)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorScheme.onPrimary.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  'Assistant Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          );
        },
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isExpanded 
            ? colorScheme.surface
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
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
                    Icon(icon, 
                      size: 26, 
                      color: isExpanded 
                          ? colorScheme.primary 
                          : colorScheme.onSurface.withOpacity(0.87)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpanded 
                              ? colorScheme.primary 
                              : colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.chevron_right, 
                        size: 24, 
                        color: isExpanded 
                            ? colorScheme.primary 
                            : colorScheme.onSurface.withOpacity(0.54)),
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
    List<Widget>? children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.surface
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.03),
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
                Icon(icon, 
                  size: 22, 
                  color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.onSurface.withOpacity(0.54)),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected 
                          ? colorScheme.primary 
                          : colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                  ),
                if (children != null && children.isNotEmpty)
                  AnimatedRotation(
                    turns: isSelected ? 0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.chevron_right, 
                      size: 24, 
                      color: isSelected 
                          ? colorScheme.primary 
                          : colorScheme.onSurface.withOpacity(0.54)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
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
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: colorScheme.error.withOpacity(0.4),
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
    final colorScheme = Theme.of(context).colorScheme;
    
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
                Icon(
                  LineIcons.sun, 
                  size: 26, 
                  color: colorScheme.onSurface.withOpacity(0.87)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface.withOpacity(0.87),
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