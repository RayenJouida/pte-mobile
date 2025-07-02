import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pte_mobile/screens/leave/all_leave_requests.dart';
import 'package:pte_mobile/providers/notification_provider.dart';
import 'package:pte_mobile/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickalert/quickalert.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/widgets/admin_navbar.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/assistant_navbar.dart';
import 'package:pte_mobile/widgets/lab_manager_navbar.dart';
import 'package:pte_mobile/widgets/engineer_navbar.dart';
import '../theme/theme.dart';
import '../models/activity.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _userRole;
  int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userRole = prefs.getString('userRole'));
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      final userId = provider.currentUserId ?? '';
      if (userId.isNotEmpty) {
        print('Fetching activities for user: $userId');
        await provider.fetchActivityCount(userId);
      } else {
        print('No userId found, skipping fetch');
      }
    } catch (e) {
      print('Error fetching activities: $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load activities: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0632A1),
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF0632A1), size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.mark_chat_read_outlined,
                color: Color(0xFF0632A1), size: 22),
            onPressed: () async {
              try {
                await _authService.markActivitiesAsRead();
                Provider.of<NotificationProvider>(context, listen: false)
                    .resetActivityCount();
                await Provider.of<NotificationProvider>(context, listen: false)
                    .fetchUnreadCounts();
              } catch (e) {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: 'Failed to mark as read: $e',
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      drawer: _userRole == 'ADMIN'
          ? AdminSidebar(currentIndex: _currentIndex, onTabChange: (_) {})
          : _userRole == 'LAB-MANAGER'
              ? LabManagerSidebar(currentIndex: _currentIndex, onTabChange: (_) {})
              : _userRole == 'ENGINEER'
                  ? EngineerSidebar(currentIndex: _currentIndex, onTabChange: (_) {})
                  : AssistantSidebar(currentIndex: _currentIndex, onTabChange: (_) {}),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: const Color(0xFF0632A1),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading notifications...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final activities = provider.leaveNotifications;
                print('Rendering NotificationsScreen with ${activities.length} activities');
                if (activities.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 60,
                          color: const Color(0xFF0632A1).withOpacity(0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: activities.length,
                  separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    print('Rendering activity ${activity.id}, read: ${activity.read}');
                    String message;
                    switch (activity.type) {
                      case 'leave_request':
                        message = '${activity.actor['firstName']} ${activity.actor['lastName']} submitted a leave request.';
                        break;
                      case 'leave_accepted':
                        message = 'Your leave request was approved.';
                        break;
                      case 'leave_declined':
                        message = 'Your leave request was declined.';
                        break;
                      case 'like':
                        message = '${activity.actor['firstName']} ${activity.actor['lastName']} liked your post.';
                        break;
                      case 'comment':
                        message = '${activity.actor['firstName']} ${activity.actor['lastName']} commented on your post.';
                        break;
                      default:
                        message = 'New activity on your post.';
                    }
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          print('Tapped notification: ${activity.id}');
                          try {
                            await provider.markActivityAsRead(activity.id);
                            print('Successfully marked activity ${activity.id} as read');
                            if (activity.type == 'leave_request') {
                              print('Navigating to AllLeaveRequestsScreen');
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AllLeaveRequestsScreen()),
                              );
                            }
                          } catch (e) {
                            print('Error marking activity as read: $e');
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.error,
                              title: 'Error',
                              text: 'Failed to mark activity as read: $e',
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF0632A1).withOpacity(0.1),
                                child: ClipOval(
                                  child: Image.network(
                                    activity.actor['image'] != null
                                        ? '${Env.userImageBaseUrl}${activity.actor['image']}'
                                        : 'https://ui-avatars.com/api/?name=${activity.actor['firstName']}+${activity.actor['lastName']}&background=0632A1&color=fff',
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: const Color(0xFF0632A1), size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(activity.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!activity.read)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: _userRole == 'ADMIN'
          ? AdminNavbar(
              currentIndex: _currentIndex,
              onTabChange: (_) {},
              unreadMessageCount: 0,
              unreadNotificationCount: 0,
            )
          : _userRole == 'LAB-MANAGER'
              ? LabManagerNavbar(
                  currentIndex: _currentIndex,
                  onTabChange: (_) {},
                  unreadMessageCount: 0,
                  unreadNotificationCount: 0,
                )
              : _userRole == 'ENGINEER'
                  ? EngineerNavbar(
                      currentIndex: _currentIndex,
                      onTabChange: (_) {},
                      unreadMessageCount: 0,
                      unreadNotificationCount: 0,
                    )
                  : AssistantNavbar(
                      currentIndex: _currentIndex,
                      onTabChange: (_) {},
                      unreadMessageCount: 0,
                      unreadNotificationCount: 0,
                    ),
    );
  }
}