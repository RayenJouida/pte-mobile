import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../services/activity_service.dart';
import '../services/post_service.dart';
import '../config/env.dart';
import '../models/activity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quickalert/quickalert.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadMessageCount = 0;
  int _unreadActivityCount = 0;
  List<Activity> _leaveNotifications = [];
  WebSocketChannel? _channel;
  final AuthService _authService = AuthService();
  final ActivityService _activityService = ActivityService();
  final PostService _postService = PostService();
  final List<Function(String)> _conversationListeners = [];
  String? _currentUserId;
  final Set<String> _processedMessageIds = {};
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  int get unreadMessageCount => _unreadMessageCount;
  int get unreadActivityCount => _unreadActivityCount;
  List<Activity> get leaveNotifications => _leaveNotifications;
  String? get currentUserId => _currentUserId;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserId();
    await _initNotifications();
    if (_currentUserId != null) {
      _connectToWebSocket();
      await fetchUnreadCounts();
      await fetchActivityCount(_currentUserId!);
    } else {
      print('Initialization skipped: No userId available');
    }
  }

  Future<void> _initNotifications() async {
    final status = await Permission.notification.request();
    print('Notification permission: $status');
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    print('Loaded userId: $_currentUserId');
    if (_currentUserId == null) {
      print('Warning: No userId found in SharedPreferences.');
    }
  }

  void _connectToWebSocket() async {
    if (_currentUserId == null) {
      print('Cannot connect to WebSocket: No userId found');
      return;
    }
    print('Connecting to WebSocket: ${Env.wsUrl}');
    try {
      _channel = WebSocketChannel.connect(Uri.parse(Env.wsUrl));
      await _channel!.ready;
      _channel!.sink.add(jsonEncode({
        'type': 'register',
        'userId': _currentUserId,
      }));
      print('Registered userId: $_currentUserId');
      _reconnectAttempts = 0;
      _channel!.stream.listen(
        (message) {
          print('Received WebSocket message: $message');
          try {
            final data = jsonDecode(message);
            if (data['type'] == 'new_message') {
              final messageId = data['data']['_id'];
              if (!_processedMessageIds.contains(messageId)) {
                _processedMessageIds.add(messageId);
                if (data['data']['receiver'] == _currentUserId) {
                  _unreadMessageCount++;
                  print('Unread messages: $_unreadMessageCount');
                  notifyListeners();
                }
              }
            } else if (data['type'] == 'new_activity') {
              final activity = Activity.fromJson(data['data']);
              if (['leave_request', 'leave_accepted', 'leave_declined'].contains(activity.type)) {
                _leaveNotifications.insert(0, activity);
                _unreadActivityCount++;
                print('New leave activity: ${activity.type}, Unread: $_unreadActivityCount');
                _showNotification(activity);
                notifyListeners();
              } else if (data['type'] == 'new_department') {
                _unreadActivityCount++;
                print('New department activity, Unread: $_unreadActivityCount');
                notifyListeners();
              }
            } else if (data['type'] == 'unread_activity_count') {
              _unreadActivityCount = data['data']['unreadCount'] ?? 0;
              print('Updated unreadActivityCount: $_unreadActivityCount');
              notifyListeners();
            } else if (data['type'] == 'unread_message_count') {
              final newCount = data['data']['unreadCount'] ?? 0;
              if (newCount >= _unreadMessageCount) {
                _unreadMessageCount = newCount;
                print('Updated unreadMessageCount: $_unreadMessageCount');
                notifyListeners();
              }
            } else if (data['type'] == 'activity_updated') {
              final activityId = data['data']['activityId'];
              final read = data['data']['read'] ?? true;
              final activityIndex = _leaveNotifications.indexWhere((activity) => activity.id == activityId);
              if (activityIndex != -1) {
                print('Updating activity $activityId read status to $read');
                _leaveNotifications[activityIndex] = _leaveNotifications[activityIndex].copyWith(read: read);
                _unreadActivityCount = _leaveNotifications.where((activity) => !activity.read).length;
                print('Updated unread count: $_unreadActivityCount');
                notifyListeners();
              } else {
                print('Activity $activityId not found in leaveNotifications, refreshing...');
                fetchActivityCount(_currentUserId!);
              }
            } else if (data['type'] == 'update_conversation') {
              final recipientId = data['data']['recipientId'];
              for (var listener in _conversationListeners) {
                listener(recipientId);
              }
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          print('WebSocket closed');
          _reconnect();
        },
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      print('Reconnecting WebSocket, attempt $_reconnectAttempts');
      Future.delayed(const Duration(seconds: 5), () {
        _channel?.sink.close();
        _channel = null;
        _connectToWebSocket();
      });
    } else {
      print('Max reconnect attempts reached.');
    }
  }

  Future<void> _showNotification(Activity activity) async {
    String title = '';
    String body = '';
    switch (activity.type) {
      case 'leave_request':
        title = 'New Leave Request';
        body = 'Leave request from ${activity.actor['firstName']} ${activity.actor['lastName']}.';
        break;
      case 'leave_accepted':
        title = 'Leave Approved';
        body = 'Your leave request was approved.';
        break;
      case 'leave_declined':
        title = 'Leave Declined';
        body = 'Your leave request was declined.';
        break;
    }
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'leave_channel',
      'Leave Notifications',
      channelDescription: 'Notifications for leave requests and updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: jsonEncode(activity.toJson()),
    );
    print('Showed notification: $title - $body');
  }

  void addConversationListener(Function(String) listener) {
    _conversationListeners.add(listener);
  }

  void removeConversationListener(Function(String) listener) {
    _conversationListeners.remove(listener);
  }

  Future<void> fetchUnreadCounts() async {
    try {
      final counts = await _activityService.fetchUnreadCounts();
      _unreadMessageCount = counts['unreadMessages'] ?? 0;
      _unreadActivityCount = counts['unreadActivities'] ?? 0;
      print('Fetched counts: messages=$_unreadMessageCount, activities=$_unreadActivityCount');
      notifyListeners();
    } catch (e) {
      print('Error fetching unread counts: $e');
      _unreadMessageCount = 0;
      _unreadActivityCount = 0;
      notifyListeners();
    }
  }

  Future<void> fetchActivityCount(String userId) async {
    try {
      final activities = await _activityService.fetchActivities(userId);
      print('Fetched activities: ${activities.length}');
      _leaveNotifications = activities
          .where((activity) => ['leave_request', 'leave_accepted', 'leave_declined'].contains(activity.type))
          .toList();
      _unreadActivityCount = _leaveNotifications.where((activity) => !activity.read).length;
      print('Filtered leave notifications: ${_leaveNotifications.length}, Unread: $_unreadActivityCount');
      notifyListeners();
    } catch (e) {
      print('Error fetching activity count: $e');
      _leaveNotifications = [];
      _unreadActivityCount = 0;
      notifyListeners();
    }
  }

  Future<void> markActivityAsRead(String activityId) async {
    print('Calling markActivityAsRead for activity: $activityId');
    try {
      await _activityService.markActivityAsRead(activityId);
      print('ActivityService marked activity $activityId as read');
      final activityIndex = _leaveNotifications.indexWhere((activity) => activity.id == activityId);
      if (activityIndex != -1) {
        print('Found activity $activityId at index $activityIndex, updating read status');
        _leaveNotifications[activityIndex] = _leaveNotifications[activityIndex].copyWith(read: true);
        _unreadActivityCount = _leaveNotifications.where((activity) => !activity.read).length;
        print('Updated activity $activityId read status. Unread count: $_unreadActivityCount');
        notifyListeners();
      } else {
        print('Activity $activityId not found in leaveNotifications, refreshing...');
        await fetchActivityCount(_currentUserId!);
        notifyListeners();
      }
    } catch (e) {
      print('Error marking activity as read: $e');
      QuickAlert.show(
        context: navigatorKey.currentContext!,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Failed to mark activity as read: $e',
      );
    }
  }

  void setMessageCount(int count) {
    _unreadMessageCount = count;
    notifyListeners();
  }

  void setActivityCount(int count) {
    _unreadActivityCount = count;
    notifyListeners();
  }

  void resetMessageCount() {
    _unreadMessageCount = 0;
    notifyListeners();
  }

  void resetActivityCount() {
    _unreadActivityCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _conversationListeners.clear();
    super.dispose();
  }
}
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();