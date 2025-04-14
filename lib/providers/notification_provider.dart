import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart'; // Add this import
import '../config/env.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadMessageCount = 0;
  int _unreadActivityCount = 0;
  WebSocketChannel? _channel;
  final AuthService _authService = AuthService();
  final PostService _postService = PostService(); // Add PostService instance

  int get unreadMessageCount => _unreadMessageCount;
  int get unreadActivityCount => _unreadActivityCount;

  NotificationProvider() {
    _connectToWebSocket();
    fetchUnreadCounts();
  }

  void _connectToWebSocket() {
    _channel = WebSocketChannel.connect(Uri.parse(Env.wsUrl));
    _channel!.stream.listen(
      (message) {
        print('WebSocket message received: $message');
        try {
          final data = jsonDecode(message);
          if (data['type'] == 'new_message') {
            _unreadMessageCount++;
            print('Incremented unreadMessageCount to: $_unreadMessageCount');
            notifyListeners();
          } else if (data['type'] == 'new_activity') {
            _unreadActivityCount++;
            print('Incremented unreadActivityCount to: $_unreadActivityCount');
            notifyListeners();
          } else if (data['type'] == 'unread_activity_count') {
            _unreadActivityCount = data['data']['unreadCount'] ?? 0;
            print('Updated unreadActivityCount to: $_unreadActivityCount');
            notifyListeners();
          } else if (data['type'] == 'unread_message_count') {
            _unreadMessageCount = data['data']['unreadCount'] ?? 0;
            print('Updated unreadMessageCount to: $_unreadMessageCount');
            notifyListeners();
          }
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        Future.delayed(Duration(seconds: 5), () {
          print('Attempting to reconnect to WebSocket...');
          _connectToWebSocket();
        });
      },
      onDone: () {
        print('WebSocket connection closed');
        Future.delayed(Duration(seconds: 5), () {
          print('Attempting to reconnect to WebSocket...');
          _connectToWebSocket();
        });
      },
    );
  }

  Future<void> fetchUnreadCounts() async {
    try {
      final counts = await _authService.fetchUnreadCounts();
      _unreadMessageCount = counts['unreadMessages'] ?? 0;
      _unreadActivityCount = counts['unreadActivities'] ?? 0;
      print('Updated counts in NotificationProvider: messages=$_unreadMessageCount, activities=$_unreadActivityCount');
      notifyListeners();
    } catch (e) {
      print('Error fetching unread counts in NotificationProvider: $e');
      _unreadMessageCount = 0;
      _unreadActivityCount = 0;
      notifyListeners();
    }
  }

  // New method to fetch unread activity count via PostService
  Future<void> fetchActivityCount(String userId) async {
    try {
      final activities = await _postService.fetchUserActivities(userId);
      _unreadActivityCount = activities.where((activity) => !activity.read).length;
      print('Fetched unread activity count: $_unreadActivityCount');
      notifyListeners();
    } catch (e) {
      print('Error fetching activity count: $e');
    }
  }

  void setMessageCount(int count) {
    _unreadMessageCount = count;
    print('Set unreadMessageCount to: $_unreadMessageCount');
    notifyListeners();
  }

  void setActivityCount(int count) {
    _unreadActivityCount = count;
    print('Set unreadActivityCount to: $_unreadActivityCount');
    notifyListeners();
  }

  void resetMessageCount() {
    _unreadMessageCount = 0;
    print('Reset unreadMessageCount to: $_unreadMessageCount');
    notifyListeners();
  }

  void resetActivityCount() {
    _unreadActivityCount = 0;
    print('Reset unreadActivityCount to: $_unreadActivityCount');
    notifyListeners();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}