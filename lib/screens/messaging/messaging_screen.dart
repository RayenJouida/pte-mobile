import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pte_mobile/services/messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/message.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/theme/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class MessagingScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const MessagingScreen({required this.recipientId, required this.recipientName});

  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final MessageService _messageService = MessageService();
  bool _isLoading = true;
  String? _currentUserId;
  int _initialMessageCount = 0;
  User? _recipientUser;
  int? _tappedMessageIndex;
  bool _hasMarkedAsRead = false;
  Function(String)? _conversationListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    if (_conversationListener != null) {
      Provider.of<NotificationProvider>(context, listen: false)
          .removeConversationListener(_conversationListener!);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_hasMarkedAsRead) {
      _fetchMessages(widget.recipientId);
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_currentUserId == null || widget.recipientId.isEmpty || _hasMarkedAsRead) return;

    try {
      final unreadCount = await _messageService.markMessagesAsRead(widget.recipientId, _currentUserId!);
      Provider.of<NotificationProvider>(context, listen: false).setMessageCount(unreadCount);
      if (mounted) {
        setState(() {
          _hasMarkedAsRead = true;
        });
      }
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
      if (mounted) {
        setState(() {
          _recipientUser = recipient;
        });
      }
    } catch (e) {
      print('Failed to fetch recipient user: $e');
      if (mounted) {
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
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final day = timestamp.day;
    final month = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][timestamp.month - 1];
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    String dayWithSuffix = '${day}${day % 10 == 1 && day != 11 ? 'st' : day % 10 == 2 && day != 12 ? 'nd' : day % 10 == 3 && day != 13 ? 'rd' : 'th'}';
    return '$dayWithSuffix $month, $hour:$minute';
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    if (_currentUserId == null) {
      print('User ID not found in SharedPreferences');
    } else {
      print('Current user ID: $_currentUserId');
      await _fetchMessages(widget.recipientId);
      await _fetchRecipientUser();
      _conversationListener = (recipientId) {
        if (recipientId == widget.recipientId) {
          _fetchMessages(recipientId);
        }
      };
      Provider.of<NotificationProvider>(context, listen: false).addConversationListener(_conversationListener!);
    }
  }

  Future<void> _fetchMessages(String recipientId) async {
    try {
      final fetchedMessages = await _messageService.fetchMessages(_currentUserId!, recipientId);
      fetchedMessages.sort((a, b) => (a.timestamp ?? DateTime(0)).compareTo(b.timestamp ?? DateTime(0)));
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(fetchedMessages);
          _isLoading = false;
          if (_initialMessageCount == 0) _initialMessageCount = _messages.length;
          if (_messages.isNotEmpty && !_hasMarkedAsRead) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _markMessagesAsRead();
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load messages: $e')));
      }
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _currentUserId != null) {
      print('Sending message: $message to ${widget.recipientId}');
      FocusScope.of(context).unfocus();

      _messageService.sendMessage(widget.recipientId, message).then((success) {
        if (success) {
          if (mounted) {
            setState(() {
              _messages.add(Message(
                id: DateTime.now().toString(),
                senderId: _currentUserId!,
                receiverId: widget.recipientId,
                content: message,
                timestamp: DateTime.now(),
                isSent: true,
              ));
            });
          }
          _messageController.clear();
        }
      }).catchError((e) {
        print('Error sending message: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
        }
      });
    }
  }

  bool _shouldShowAvatar(int index) {
    if (index == _messages.length - 1) return true;
    return _messages[index].senderId != _messages[index + 1].senderId;
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isMe = message.senderId == _currentUserId;
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
              backgroundImage: _recipientUser!.image != null && _recipientUser!.image!.isNotEmpty
                  ? NetworkImage('${Env.userImageBaseUrl}${_recipientUser!.image!}')
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
              child: _recipientUser!.image == null || _recipientUser!.image!.isEmpty
                  ? Text(_recipientUser!.firstName[0].toUpperCase(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 8),
          ] else if (!isMe) ...[
            const SizedBox(width: 40),
          ],
          Flexible(
            child: GestureDetector(
              onTap: () => setState(() => _tappedMessageIndex = _tappedMessageIndex == index ? null : index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
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
                    Text(message.content ?? 'No content', style: TextStyle(fontSize: 16.0, color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSecondary)),
                    if (showTimestamp) ...[
                      const SizedBox(height: 4.0),
                      Text(_formatTimestamp(message.timestamp), style: TextStyle(fontSize: 12.0, color: isMe ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.5) : Theme.of(context).colorScheme.onSecondary.withOpacity(0.5))),
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
          IconButton(icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), onPressed: () {}),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              child: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return _messages.length <= _initialMessageCount || (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard Changes'),
        content: Text('You have unsent messages. Are you sure you want to discard them?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes')),
        ],
      ),
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          leading: IconButton(icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary, size: 30), onPressed: () => Navigator.pop(context, _messages.length > _initialMessageCount)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: _recipientUser?.image != null && _recipientUser!.image!.isNotEmpty
                    ? NetworkImage('${Env.userImageBaseUrl}${_recipientUser!.image!}')
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                child: _recipientUser?.image == null || _recipientUser!.image!.isEmpty
                    ? Text(_recipientUser?.firstName[0].toUpperCase() ?? '?', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 20))
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.recipientName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2))),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                  : _messages.isEmpty
                      ? Center(child: Text('You haven\'t talked to ${widget.recipientName} yet.', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _buildMessageBubble(_messages[index], index),
                        ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }
}