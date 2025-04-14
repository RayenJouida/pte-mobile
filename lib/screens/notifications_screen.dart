import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/notification_provider.dart';
import 'package:quickalert/quickalert.dart';
import '../theme/theme.dart';
import '../models/activity.dart'; // Add this import
import '../config/env.dart'; // Add this import for Env.userImageBaseUrl

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  List<Activity> _activities = []; // Change to List<Activity>
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _activities = await _authService.fetchActivities();
      await _authService.markActivitiesAsRead();
      Provider.of<NotificationProvider>(context, listen: false).resetActivityCount();
      await Provider.of<NotificationProvider>(context, listen: false).fetchUnreadCounts();
    } catch (e) {
      print('Error in _fetchActivities: $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to load activities: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) { // Change parameter to DateTime
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        foregroundColor: lightColorScheme.primary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: lightColorScheme.primary.withOpacity(0.2),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: lightColorScheme.primary))
          : _activities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 60,
                        color: lightColorScheme.primary.withOpacity(0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _activities.length,
                  itemBuilder: (context, index) {
                    final activity = _activities[index];
                    String message = '';
                    switch (activity.type) {
                      case 'like':
                        message = '${activity.actor['firstName']} ${activity.actor['lastName']} liked your post.';
                        break;
                      case 'comment':
                        message = '${activity.actor['firstName']} ${activity.actor['lastName']} commented on your post.';
                        break;
                      default:
                        message = 'New activity on your post.';
                    }
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          activity.actor['image'] != null
                              ? '${Env.userImageBaseUrl}${activity.actor['image']}'
                              : 'https://ui-avatars.com/api/?name=${activity.actor['firstName']}+${activity.actor['lastName']}',
                        ),
                      ),
                      title: Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: lightColorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _formatTimestamp(activity.timestamp), // Use DateTime directly
                        style: TextStyle(
                          fontSize: 12,
                          color: lightColorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      trailing: !activity.read
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () {
                        // Optionally navigate to the related post
                      },
                    );
                  },
                ),
    );
  }
}