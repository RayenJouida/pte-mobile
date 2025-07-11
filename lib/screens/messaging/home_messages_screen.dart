import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/lab_manager_navbar.dart';
import '../../services/messaging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/message.dart' as message_model;
import '../../models/user.dart';
import '../../widgets/assistant_navbar.dart';
import 'messaging_screen.dart';
import '../chat/chat_screen.dart';
import '../../theme/theme.dart';
import '../../providers/notification_provider.dart';
import '../../config/env.dart';
import '../settings_screen.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';

class HomeMessagesScreen extends StatefulWidget {
  const HomeMessagesScreen({Key? key}) : super(key: key);

  @override
  _HomeMessagesScreenState createState() => _HomeMessagesScreenState();
}

class _HomeMessagesScreenState extends State<HomeMessagesScreen>
    with AutomaticKeepAliveClientMixin {
  final MessageService _messageService = MessageService();
  List<Map<String, dynamic>> _conversations = [];
  List<User> _users = [];
  List<User> _filteredUsers = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _userRole;
  String _searchText = '';
  int _currentIndex = 1;
  Function(String)? _conversationListener;
  late ScaffoldMessengerState _scaffoldMessenger;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Removed resetMessageCount to avoid clearing unread counts
    });
    _fetchData();
    _setupRealTimeUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  void _setupRealTimeUpdates() {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    _conversationListener = (String recipientId) async {
      if (_currentUserId != null) {
        try {
          print('Received update_conversation WebSocket message, refreshing conversations...');
          final conversations = await _messageService.fetchConversations(_currentUserId!);
          final users = await _messageService.fetchUsers();
          final userList = users.map((user) => User.fromJson(user)).toList();
          final userMap = {for (var user in userList) user.id: user};

          final enhancedConversations = conversations.map((conv) {
            final convRecipientId = conv['recipientId'];
            final user = userMap[convRecipientId];
            return {
              ...conv,
              'user': user,
              'unreadCount': conv['unreadCount'] ?? 0,
            };
          }).toList();

          enhancedConversations.sort((a, b) {
            final aTimestamp = a['lastMessage'] != null
                ? DateTime.parse(a['lastMessage']['timestamp'])
                : DateTime(0);
            final bTimestamp = b['lastMessage'] != null
                ? DateTime.parse(b['lastMessage']['timestamp'])
                : DateTime(0);
            return bTimestamp.compareTo(aTimestamp);
          });

          if (mounted) {
            setState(() {
              _conversations = enhancedConversations;
              _users = userList;
              _filteredConversations = enhancedConversations;
              _filteredUsers = userList;
              _applyFilters();
              final updatedConvIndex = _conversations.indexWhere((conv) => conv['recipientId'] == recipientId);
              if (updatedConvIndex != -1) {
                final conv = conversations.firstWhere((c) => c['recipientId'] == recipientId, orElse: () => {});
                if (conv.isNotEmpty) {
                  setState(() {
                    _conversations[updatedConvIndex]['unreadCount'] = conv['unreadCount'] ?? 0;
                  });
                }
              }
            });
          }
          print('Conversations updated: ${enhancedConversations.length} conversations loaded');
        } catch (e) {
          print('Failed to update conversations: $e');
          if (mounted) {
            _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to update conversations: $e')));
          }
        }
      }
    };
    notificationProvider.addConversationListener(_conversationListener!);
  }

  @override
  void dispose() {
    if (_conversationListener != null) {
      Provider.of<NotificationProvider>(context, listen: false)
          .removeConversationListener(_conversationListener!);
    }
    super.dispose();
  }

  void _onTabChange(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/feed');
          break;
        case 1:
          if (_userRole == 'LAB-MANAGER') {
            Navigator.pushReplacementNamed(context, '/lab-home');
          }
          break;
        case 2:
          break;
        case 3:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          );
          break;
      }
    }
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    _userRole = prefs.getString('userRole');

    if (_currentUserId != null) {
      try {
        final conversations = await _messageService.fetchConversations(_currentUserId!);
        final users = await _messageService.fetchUsers();

        final userList = users.map((user) => User.fromJson(user)).toList();
        final userMap = {for (var user in userList) user.id: user};

        final enhancedConversations = conversations.map((conv) {
          final recipientId = conv['recipientId'];
          final user = userMap[recipientId];
          return {
            ...conv,
            'user': user,
            'unreadCount': conv['unreadCount'] ?? 0,
          };
        }).toList();

        enhancedConversations.sort((a, b) {
          final aTimestamp = a['lastMessage'] != null
              ? DateTime.parse(a['lastMessage']['timestamp'])
              : DateTime(0);
          final bTimestamp = b['lastMessage'] != null
              ? DateTime.parse(b['lastMessage']['timestamp'])
              : DateTime(0);
          return bTimestamp.compareTo(aTimestamp);
        });

        if (mounted) {
          setState(() {
            _conversations = enhancedConversations;
            _users = userList;
            _filteredUsers = userList;
            _filteredConversations = enhancedConversations;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
        }
      }
    }
  }

  Future<void> _refreshConversations() async {
    if (_currentUserId != null) {
      try {
        final conversations = await _messageService.fetchConversations(_currentUserId!);
        final users = await _messageService.fetchUsers();
        final userList = users.map((user) => User.fromJson(user)).toList();
        final userMap = {for (var user in userList) user.id: user};

        final enhancedConversations = conversations.map((conv) {
          final recipientId = conv['recipientId'];
          final user = userMap[recipientId];
          return {
            ...conv,
            'user': user,
            'unreadCount': conv['unreadCount'] ?? 0,
          };
        }).toList();

        enhancedConversations.sort((a, b) {
          final aTimestamp = a['lastMessage'] != null
              ? DateTime.parse(a['lastMessage']['timestamp'])
              : DateTime(0);
          final bTimestamp = b['lastMessage'] != null
              ? DateTime.parse(b['lastMessage']['timestamp'])
              : DateTime(0);
          return bTimestamp.compareTo(aTimestamp);
        });

        if (mounted) {
          setState(() {
            _conversations = enhancedConversations;
            _users = userList;
            _filteredConversations = enhancedConversations;
            _filteredUsers = userList;
            _applyFilters();
          });
        }
      } catch (e) {
        if (mounted) {
          _scaffoldMessenger.showSnackBar(SnackBar(content: Text('Failed to refresh conversations: $e')));
        }
      }
    }
  }

  void _applyFilters() {
    final query = _searchText.toLowerCase();
    if (mounted) {
      setState(() {
        _filteredUsers = _users.where((user) {
          final fullName = '${user.firstName} ${user.lastName}'.toLowerCase();
          return fullName.contains(query);
        }).toList();

        _filteredConversations = _conversations.where((conv) {
          final user = conv['user'] as User?;
          final fullName = '${user?.firstName} ${user?.lastName}'.toLowerCase();
          final lastMessage = conv['lastMessage'] != null
              ? message_model.Message.fromJson(conv['lastMessage']).content?.toLowerCase()
              : '';
          return fullName.contains(query) || (lastMessage?.contains(query) ?? false);
        }).toList();
      });
    }
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    if (messageDate == today) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == DateTime(now.year, now.month, now.day - 1)) {
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][timestamp.weekday - 1];
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildAnimatedItem({required Widget child, required int index}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 50),
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: 0.8 + 0.2 * value, child: childWidget),
        );
      },
      child: child,
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conversation, int index) {
    final user = conversation['user'] as User?;
    final lastMessage = conversation['lastMessage'] != null
        ? message_model.Message.fromJson(conversation['lastMessage'])
        : null;
    final isSentByMe = lastMessage?.senderId == _currentUserId;
    final unreadCount = conversation['unreadCount'] ?? 0;

    return _buildAnimatedItem(
      index: index,
      child: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return InkWell(
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessagingScreen(
                    recipientId: user?.id ?? '',
                    recipientName: '${user?.firstName} ${user?.lastName}',
                  ),
                ),
              );
              if (shouldRefresh == true) _refreshConversations();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: (user?.image != null && user!.image!.isNotEmpty)
                        ? NetworkImage('${Env.userImageBaseUrl}${user!.image!}')
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    child: user?.image == null || user!.image!.isEmpty
                        ? Text(
                            user?.firstName[0].toUpperCase() ?? '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user?.firstName ?? ''} ${user?.lastName ?? ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessage != null
                              ? (isSentByMe
                                  ? 'You: ${lastMessage.content}'
                                  : lastMessage.content!)
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatTimestamp(lastMessage?.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactItem(User user, int index) {
    return _buildAnimatedItem(
      index: index,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagingScreen(
                      recipientId: user.id,
                      recipientName: '${user.firstName} ${user.lastName}',
                    ),
                  ),
                );
                if (shouldRefresh == true) _refreshConversations();
              },
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: (user.image != null && user.image!.isNotEmpty)
                    ? NetworkImage('${Env.userImageBaseUrl}${user.image!}')
                    : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                child: user.image == null || user.image!.isEmpty
                    ? Text(
                        user.firstName[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.firstName,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leadingWidth: 40,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: lightColorScheme.primary, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
          ),
        ),
        title: Image.asset(
          'assets/images/prologic.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
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
        onRefresh: _refreshConversations,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _applyFilters();
                  });
                },
                style: const TextStyle(color: searchText),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(color: searchPlaceholder),
                  prefixIcon: const Icon(Icons.search, color: searchText),
                  filled: true,
                  fillColor: lightColorScheme.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                  : ListView(
                      children: [
                        if (_filteredUsers.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Contacts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) => _buildContactItem(_filteredUsers[index], index),
                            ),
                          ),
                        ],
                        if (_filteredConversations.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              'Chats',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, index) => _buildConversationItem(
                              _filteredConversations[index],
                              index,
                            ),
                          ),
                        ],
                        if (_filteredUsers.isEmpty && _filteredConversations.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No contacts or conversations found.',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagingScreen(
              recipientId: '',
              recipientName: 'New Message',
            ),
          ),
        ),
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return _userRole == 'LAB-MANAGER'
              ? LabManagerNavbar(
                  currentIndex: _currentIndex,
                  onTabChange: _onTabChange,
                  unreadMessageCount: notificationProvider.unreadMessageCount,
                  unreadNotificationCount: notificationProvider.unreadActivityCount,
                )
              : AssistantNavbar(
                  currentIndex: _currentIndex,
                  onTabChange: _onTabChange,
                  unreadMessageCount: notificationProvider.unreadMessageCount,
                  unreadNotificationCount: notificationProvider.unreadActivityCount,
                );
        },
      ),
    );
  }
}