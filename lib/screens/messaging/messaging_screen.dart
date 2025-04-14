import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/services/messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/services/websocket_service.dart';
import 'package:pte_mobile/models/message.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class MessagingScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  MessagingScreen({required this.recipientId, required this.recipientName});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> with WidgetsBindingObserver {
  late WebSocketService _webSocketService;
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final MessageService _messageService = MessageService();
  bool _isLoading = true;
  String? _currentUserId;
  int _initialMessageCount = 0;
  User? _recipientUser;
  int? _tappedMessageIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebSocket();
    _fetchRecipientUser();
    // Mark messages as read when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webSocketService.disconnect();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchMessages(widget.recipientId);
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null || widget.recipientId.isEmpty) return;

    try {
      final unreadCount = await _messageService.markMessagesAsRead(widget.recipientId, _currentUserId!);
      // Update the unreadMessageCount in NotificationProvider
      Provider.of<NotificationProvider>(context, listen: false).setMessageCount(unreadCount);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _fetchRecipientUser() async {
    try {
      final users = await _messageService.fetchUsers();
      final userList = users.map((user) => User.fromJson(user)).toList();
      final recipient = userList.firstWhere(
        (user) => user.id == widget.recipientId,
        orElse: () => User(
          id: widget.recipientId,
          firstName: widget.recipientName.split(' ').first,
          lastName: widget.recipientName.split(' ').length > 1 ? widget.recipientName.split(' ').last : '',
          matricule: '',
          email: '',
          roles: [],
          isEnabled: "true",
          experience: 0,
          image: null,
        ),
      );
      setState(() {
        _recipientUser = recipient;
      });
    } catch (e) {
      print('Failed to fetch recipient user: $e');
      setState(() {
        _recipientUser = User(
          id: widget.recipientId,
          firstName: widget.recipientName.split(' ').first,
          lastName: widget.recipientName.split(' ').length > 1 ? widget.recipientName.split(' ').last : '',
          matricule: '',
          email: '',
          roles: [],
          isEnabled: "true",
          experience: 0,
          image: null,
        );
      });
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final day = timestamp.day;
    final month = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][timestamp.month - 1];
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');

    String dayWithSuffix;
    if (day % 10 == 1 && day != 11) {
      dayWithSuffix = '${day}st';
    } else if (day % 10 == 2 && day != 12) {
      dayWithSuffix = '${day}nd';
    } else if (day % 10 == 3 && day != 13) {
      dayWithSuffix = '${day}rd';
    } else {
      dayWithSuffix = '${day}th';
    }

    return '$dayWithSuffix $month, $hour:$minute';
  }

  Future<void> _initializeWebSocket() async {
    print('Initializing WebSocket...');
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');

    if (_currentUserId != null) {
      print('Current user ID: $_currentUserId');
      _webSocketService = WebSocketService(
        _currentUserId!,
        onMessageReceived: _handleIncomingMessage,
      );
      _webSocketService.connect();

      await _fetchMessages(widget.recipientId);
    } else {
      print('User ID not found in SharedPreferences');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    print('Received new message via WebSocket: $message');
    final newMessage = Message.fromJson(message);
    setState(() {
      _messages.add(newMessage);
    });
  }

  Future<void> _fetchMessages(String recipientId) async {
    try {
      final fetchedMessages = await _messageService.fetchMessages(_currentUserId!, recipientId);

      fetchedMessages.sort((a, b) {
        final aTimestamp = a.timestamp ?? DateTime(0);
        final bTimestamp = b.timestamp ?? DateTime(0);
        return aTimestamp.compareTo(bTimestamp);
      });

      setState(() {
        _messages.clear();
        _messages.addAll(fetchedMessages);
        _isLoading = false;
        if (_initialMessageCount == 0) {
          _initialMessageCount = _messages.length;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text;
    if (message.isNotEmpty) {
      print('Sending message: $message to ${widget.recipientId}');
      FocusScope.of(context).unfocus();

      _webSocketService.sendMessage(widget.recipientId, message);
      _messageService.sendMessage(widget.recipientId, message);

      setState(() {
        _messages.add(
          Message(
            id: DateTime.now().toString(),
            senderId: _currentUserId!,
            receiverId: widget.recipientId,
            content: message,
            timestamp: DateTime.now(),
            isSent: true,
          ),
        );
      });
      _messageController.clear();
    }
  }

  bool _shouldShowAvatar(int index) {
    if (index == _messages.length - 1) return true; // Last message always shows avatar
    final currentMessage = _messages[index];
    final nextMessage = _messages[index + 1];
    return currentMessage.senderId != nextMessage.senderId;
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isMe = message.senderId == _currentUserId;
    final text = message.content ?? 'No content';
    final timestamp = message.timestamp ?? DateTime.now();
    final showTimestamp = _tappedMessageIndex == index;
    final showAvatar = !isMe && _shouldShowAvatar(index);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAvatar && _recipientUser != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: (_recipientUser!.image != null && _recipientUser!.image!.isNotEmpty)
                  ? NetworkImage('${Env.userImageBaseUrl}${_recipientUser!.image!}')
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              child: (_recipientUser!.image == null || _recipientUser!.image!.isEmpty)
                  ? Text(
                      _recipientUser!.firstName[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40), // Space for avatar alignment
          ],
          Flexible(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tappedMessageIndex = (_tappedMessageIndex == index) ? null : index;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isMe
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? 12.0 : 0),
                    topRight: Radius.circular(isMe ? 0 : 12.0),
                    bottomLeft: const Radius.circular(12.0),
                    bottomRight: const Radius.circular(12.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16.0,
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                    if (showTimestamp) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isMe
                              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5)
                              : Theme.of(context).colorScheme.onSecondary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: Theme.of(context).colorScheme.background,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            onPressed: () {
              // Placeholder for future media support
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_messages.length > _initialMessageCount) {
      Navigator.pop(context, true);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary, size: 30),
            onPressed: () => Navigator.pop(context, _messages.length > _initialMessageCount),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: (_recipientUser?.image != null && _recipientUser!.image!.isNotEmpty)
                    ? NetworkImage('${Env.userImageBaseUrl}${_recipientUser!.image!}')
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                child: (_recipientUser?.image == null || _recipientUser!.image!.isEmpty)
                    ? Text(
                        _recipientUser?.firstName[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.recipientName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'You haven\'t talked to ${widget.recipientName} yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message, index);
                          },
                        ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}