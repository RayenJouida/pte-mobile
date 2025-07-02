import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/feed/post_details.dart';
import 'package:pte_mobile/screens/messaging/home_messages_screen.dart';
import 'package:pte_mobile/screens/profile_screen.dart';
import 'package:pte_mobile/screens/users/user_profile.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/auth_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/widgets/assistant_sidebar.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import 'package:pte_mobile/widgets/engineer_sidebar.dart';
import 'package:pte_mobile/widgets/labmanager_sidebar.dart';
import '../../theme/theme.dart';
import 'package:pte_mobile/screens/feed/user_posts_screen.dart';
import '../../widgets/assistant_navbar.dart';
import '../../widgets/lab_manager_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import 'package:pte_mobile/config/env.dart';
import '../../models/activity.dart';
import 'package:flutter/widgets.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<Post> _posts = [];
  List<Post> _savedPosts = [];
  List<String> _likedPostIds = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _userRole;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late ScrollController _scrollController;
  bool _showFloatingButton = true;
  final Set<String> _hiddenPostIds = {};
  ScaffoldMessengerState? _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showFloatingButton) {
        setState(() {
          _showFloatingButton = false;
        });
      }
    } else {
      if (!_showFloatingButton) {
        setState(() {
          _showFloatingButton = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetchSavedPosts();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    setState(() {
      _userRole = prefs.getString('userRole');
    });
    if (userId != null) {
      await Provider.of<NotificationProvider>(context, listen: false).fetchActivityCount(userId);
    }
    await Future.wait([_fetchPosts(), _fetchSavedPosts(), _fetchLikedPosts()]);
  }

  void _onTabChange(int index) {
    if (index != _currentIndex) setState(() => _currentIndex = index);
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await _postService.getAllApprovedPosts();
      if (mounted) setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchSavedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final savedPosts = await _postService.getUserSavedPosts(userId);
        if (mounted) setState(() => _savedPosts = savedPosts);
      }
    } catch (e) {
      debugPrint('Error fetching saved posts: $e');
    }
  }

  Future<void> _fetchLikedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final posts = await _postService.getAllApprovedPosts();
        final likedPosts = posts.where((post) {
          final likes = post.likes;
          return likes.any((like) => like.user.id == userId);
        }).toList();
        if (mounted) setState(() => _likedPostIds = likedPosts.map((post) => post.id).toList());
      }
    } catch (e) {
      debugPrint('Error fetching liked posts: $e');
    }
  }

  void _showSavedMessage() {
    if (mounted && _scaffoldMessengerState != null) {
      _scaffoldMessengerState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text("You saved this post"),
            ],
          ),
          backgroundColor: lightColorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
  }

  void _showUnsavedMessage() {
    if (mounted && _scaffoldMessengerState != null) {
      _scaffoldMessengerState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark_border, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text("You unsaved this post"),
            ],
          ),
          backgroundColor: Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
  }

  void _showLikedMessage(bool isLiked) {
    if (mounted && _scaffoldMessengerState != null) {
      _scaffoldMessengerState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(isLiked ? "You liked this post" : "You unliked this post"),
            ],
          ),
          backgroundColor: isLiked ? Colors.red.shade400 : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    }
  }

Future<void> _toggleSavePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) return;

      final isCurrentlySaved = _savedPosts.any((post) => post.id == postId);
      await _postService.savePost(postId, userId);
      if (mounted) {
        setState(() {
          if (isCurrentlySaved) {
            _savedPosts.removeWhere((post) => post.id == postId);
          } else {
            _savedPosts.add(_posts.firstWhere((post) => post.id == postId));
          }
        });
        if (_scaffoldMessengerState != null) {
          if (isCurrentlySaved) {
            _showUnsavedMessage();
          } else {
            _showSavedMessage();
          }
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text("Failed to save/unsave"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _toggleLikePost(String postId) async {
    try {
      final updatedPost = await _postService.likePost(postId);
      final wasLiked = _likedPostIds.contains(postId);
      if (mounted) {
        setState(() {
          if (wasLiked) {
            _likedPostIds.remove(postId);
          } else {
            _likedPostIds.add(postId);
          }
          final postIndex = _posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            _posts[postIndex] = updatedPost;
          }
        });
        _showLikedMessage(!wasLiked);
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text("Failed to like/unlike"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _openCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostSheet(
        onPostCreated: () {
          Navigator.pop(context);
          _fetchPosts();
        },
      ),
    );
  }

  void _showActivitySheet() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text("User not authenticated"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    await Provider.of<NotificationProvider>(context, listen: false).fetchActivityCount(userId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivitySheet(userId: userId),
    ).then((_) {
      Provider.of<NotificationProvider>(context, listen: false).resetActivityCount();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightColorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.feed_outlined,
              size: 50,
              color: lightColorScheme.primary,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: lightColorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openCreatePostSheet,
            icon: Icon(Icons.add, size: 18),
            label: Text('Create Post', style: TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: lightColorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
          'assets/images/prologic_feed.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.search, size: 22, color: lightColorScheme.primary),
            onPressed: () => showSearch(
              context: context,
              delegate: UserSearchDelegate(userService: _userService, authService: _authService, theme: Theme.of(context)),
            ),
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, size: 22, color: lightColorScheme.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeMessagesScreen())),
            tooltip: 'Messages',
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, size: 22, color: lightColorScheme.primary),
                    onPressed: _showActivitySheet,
                    tooltip: 'Notifications',
                  ),
                  if (notificationProvider.unreadActivityCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadActivityCount > 9
                              ? '9+'
                              : notificationProvider.unreadActivityCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          SizedBox(width: 8),
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
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: lightColorScheme.primary,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading posts...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadInitialData,
              color: lightColorScheme.primary,
              child: _posts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(top: 12, bottom: 80),
                      itemCount: _posts.length,
                      itemBuilder: (_, index) {
                        final post = _posts.reversed.toList()[index];
                        if (_hiddenPostIds.contains(post.id)) {
                          return SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: 12,
                            left: 12,
                            right: 12,
                          ),
                          child: FadeTransition(
                            opacity: Tween<double>(begin: 0, end: 1).animate(
                              CurvedAnimation(
                                parent: AnimationController(
                                  duration: Duration(milliseconds: 300),
                                  vsync: this,
                                  value: 1,
                                )..forward(),
                                curve: Curves.easeIn,
                              ),
                            ),
                            child: PostCard(
                              post: post,
                              onSaveToggled: _toggleSavePost,
                              onLikeToggled: _toggleLikePost,
                              isSaved: _savedPosts.any((p) => p.id == post.id),
                              isLiked: _likedPostIds.contains(post.id),
                              onHidePost: () {
                                setState(() {
                                  _hiddenPostIds.add(post.id);
                                });
                                if (mounted && _scaffoldMessengerState != null) {
                                  _scaffoldMessengerState!.showSnackBar(
                                    SnackBar(
                                      content: Text("Post hidden"),
                                      backgroundColor: Colors.grey.shade700,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              },
                              onPostUpdated: _fetchPosts,
                              onPostDeleted: () {
                                setState(() {
                                  _posts.removeWhere((p) => p.id == post.id);
                                  _savedPosts.removeWhere((p) => p.id == post.id);
                                  _likedPostIds.remove(post.id);
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: _showFloatingButton ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _showFloatingButton ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: _openCreatePostSheet,
            backgroundColor: lightColorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.add_rounded, size: 28),
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

class ActivitySheet extends StatefulWidget {
  final String userId;

  const ActivitySheet({Key? key, required this.userId}) : super(key: key);

  @override
  _ActivitySheetState createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<ActivitySheet> {
  final PostService _postService = PostService();
  List<Activity> _activities = [];
  bool _isLoading = true;
  ScaffoldMessengerState? _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await _postService.fetchUserActivities(widget.userId);
      if (mounted) {
        setState(() {
          _activities = activities.where((activity) => activity.type == 'like' || activity.type == 'comment').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now().toUtc();
    final utcTimestamp = timestamp.toUtc();
    final difference = now.difference(utcTimestamp);
    if (difference.inSeconds < 60) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  void _navigateToPost(String? postId) {
    if (postId == null) return;
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black ,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: lightColorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          _isLoading
              ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(color: lightColorScheme.primary),
                )
              : _activities.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightColorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 32,
                              color: lightColorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'When someone interacts with your posts, you\'ll see it here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        itemCount: _activities.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.grey.shade100,
                          indent: 70,
                        ),
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return InkWell(
                            onTap: () => _navigateToPost(activity.post?['_id']),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: NetworkImage(
                                      activity.actor['image'] != null && (activity.actor['image'] as String).isNotEmpty
                                          ? '${Env.userImageBaseUrl}${activity.actor['image']}'
                                          : 'https://ui-avatars.com/api/?name=${activity.actor['firstName'] ?? 'Unknown'}+${activity.actor['lastName'] ?? 'User'}&background=0632A1&color=fff',
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            style: TextStyle(fontSize: 14, color: Colors.black87),
                                            children: [
                                              TextSpan(
                                                text: '${activity.actor['firstName']} ${activity.actor['lastName']} ',
                                                style: TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                              TextSpan(
                                                text: activity.type == 'like' ? 'liked your post' : 'commented on your post',
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              activity.type == 'like' ? Icons.favorite : Icons.comment,
                                              size: 12,
                                              color: activity.type == 'like' ? Colors.pink.shade400 : lightColorScheme.primary,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              _formatTimestamp(activity.timestamp),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

enum PostMenuOption {
  update,
  delete,
  hide,
}

class PostCard extends StatefulWidget {
  final Post post;
  final Function(String) onSaveToggled;
  final Function(String) onLikeToggled;
  final bool isSaved;
  final bool isLiked;
  final VoidCallback onHidePost;
  final VoidCallback onPostUpdated;
  final VoidCallback onPostDeleted;

  const PostCard({
    Key? key,
    required this.post,
    required this.onSaveToggled,
    required this.onLikeToggled,
    required this.isSaved,
    required this.isLiked,
    required this.onHidePost,
    required this.onPostUpdated,
    required this.onPostDeleted,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isImageExpanded = false;
  String? _currentUserId;
  ScaffoldMessengerState? _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _loadCurrentUserId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _triggerAnimation() async {
    await _controller.forward();
    await _controller.reverse();
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(postId: widget.post.id),
    );
  }

  void _showUpdatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdatePostSheet(
        post: widget.post,
        onPostUpdated: () {
          Navigator.pop(context);
          widget.onPostUpdated();
        },
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      await PostService().deletePost(widget.post.id);
      if (mounted) {
        widget.onPostDeleted();
        if (_scaffoldMessengerState != null) {
          _scaffoldMessengerState!.showSnackBar(
            SnackBar(
              content: Text("Post deleted"),
              backgroundColor: Colors.grey.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text("Failed to delete post"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _toggleImageExpansion() {
    setState(() {
      _isImageExpanded = !_isImageExpanded;
    });
  }

  void _navigateToPostDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: widget.post.id)),
    );
  }

  @override
Widget build(BuildContext context) {
    final likes = widget.post.likes;
    final isOwnPost = _currentUserId != null && widget.post.user.id == _currentUserId;

    return GestureDetector(
      onTap: _navigateToPostDetails,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final currentUserId = prefs.getString('userId');
                      if (currentUserId != null && currentUserId == widget.post.user.id) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.post.user.id)));
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        widget.post.user.image != null
                            ? '${Env.userImageBaseUrl}${widget.post.user.image}'
                            : 'https://ui-avatars.com/api/?name=${widget.post.user.firstName}+${widget.post.user.lastName}&background=0632A1&color=fff',
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${widget.post.user.firstName} ${widget.post.user.lastName}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            if (widget.post.user.roles.contains('ADMIN')) ...[
                              SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                color: Colors.blue.shade600,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatDateTime(widget.post.date),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<PostMenuOption>(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade700, size: 20),
                    onSelected: (PostMenuOption option) {
                      switch (option) {
                        case PostMenuOption.update:
                          _showUpdatePostSheet();
                          break;
                        case PostMenuOption.delete:
                          _deletePost();
                          break;
                        case PostMenuOption.hide:
                          widget.onHidePost();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => isOwnPost
                        ? [
                            PopupMenuItem<PostMenuOption>(
                              value: PostMenuOption.update,
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 18, color: Colors.grey.shade700),
                                  SizedBox(width: 8),
                                  Text('Update Post', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                            PopupMenuItem<PostMenuOption>(
                              value: PostMenuOption.delete,
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red.shade700),
                                  SizedBox(width: 8),
                                  Text('Delete Post', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ]
                        : [
                            PopupMenuItem<PostMenuOption>(
                              value: PostMenuOption.hide,
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_off, size: 18, color: Colors.grey.shade700),
                                  SizedBox(width: 8),
                                  Text('Hide Post', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ],
              ),
            ),
            if (widget.post.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  widget.post.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            if (widget.post.images.isNotEmpty) ...[
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final currentUserId = prefs.getString('userId');
                  if (currentUserId != null && currentUserId == widget.post.user.id) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: widget.post.user.id)));
                  }
                },
                onDoubleTap: () {
                  _triggerAnimation();
                  if (!widget.isLiked) {
                    widget.onLikeToggled(widget.post.id);
                  }
                },
                child: Container(
                  height: _isImageExpanded ? 400 : 250,
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PageView.builder(
                          itemCount: widget.post.images.length,
                          itemBuilder: (_, index) => Image.network(
                            '${Env.imageBaseUrl}${widget.post.images[index]}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                      if (widget.post.images.length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.post.images.length} photos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _toggleImageExpansion,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isImageExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: widget.isLiked ? Colors.red.shade400 : Colors.grey.shade700,
                    count: likes.length,
                    countColor: widget.isLiked ? Colors.red.shade400 : Colors.grey.shade700,
                    onPressed: () async {
                      await _triggerAnimation();
                      widget.onLikeToggled(widget.post.id);
                    },
                    animation: _scaleAnimation,
                    controller: _controller,
                  ),
                  SizedBox(width: 16),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: lightColorScheme.primary,
                    onPressed: _showCommentsSheet,
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(
                      widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: widget.isSaved ? lightColorScheme.primary : Colors.grey.shade700,
                      size: 22,
                    ),
                    onPressed: () async {
                      await _triggerAnimation();
                      widget.onSaveToggled(widget.post.id);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    int? count,
    Color? countColor,
    required VoidCallback onPressed,
    Animation<double>? animation,
    AnimationController? controller,
  }) {
    final Widget iconWidget = Icon(icon, color: color, size: 20);

    return Row(
      children: [
        IconButton(
          icon: animation != null && controller != null
              ? ScaleTransition(scale: animation, child: iconWidget)
              : iconWidget,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        if (count != null && countColor != null) ...[
          SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              color: countColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
class CommentSheet extends StatefulWidget {
  final String postId;

  const CommentSheet({Key? key, required this.postId}) : super(key: key);

  @override
  _CommentSheetState createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final PostService _postService = PostService();
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  ScaffoldMessengerState? _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _postService.getPostComments(widget.postId);
      if (mounted) setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newComment = await _postService.addComment(widget.postId, _commentController.text);
      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _commentController.clear();
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text('Failed to add comment'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: lightColorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          Flexible(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: lightColorScheme.primary),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: lightColorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 32,
                                  color: lightColorScheme.primary,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to comment on this post',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        itemCount: _comments.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 24,
                          thickness: 1,
                          color: Colors.grey.shade100,
                        ),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: NetworkImage(
                                  comment.user.image != null
                                      ? '${Env.userImageBaseUrl}${comment.user.image}'
                                      : 'https://ui-avatars.com/api/?name=${comment.user.firstName}+${comment.user.lastName}&background=0632A1&color=fff',
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${comment.user.firstName} ${comment.user.lastName}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            comment.text,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: TextStyle(fontSize: 14),
                      maxLines: 3,
                      minLines: 1,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: lightColorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSubmitting ? null : _addComment,
                    constraints: BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserSearchDelegate extends SearchDelegate {
  final UserService userService;
  final AuthService authService;
  String? currentUserId;
  final ThemeData theme;

  UserSearchDelegate({required this.userService, required this.authService, required this.theme}) {
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('userId');
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: lightColorScheme.primary,
        iconTheme: IconThemeData(color: lightColorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear, size: 20),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 60,
              color: lightColorScheme.primary.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'Enter at least 2 characters',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List>(
      future: userService.fetchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: lightColorScheme.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red.shade300,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];
        final results = users.where((user) {
          final userData = User.fromJson(user);
          final matchesName = userData.firstName.toLowerCase().contains(query.toLowerCase()) ||
              userData.lastName.toLowerCase().contains(query.toLowerCase());
          final isNotCurrentUser = currentUserId == null || userData.id != currentUserId;
          return matchesName && isNotCurrentUser;
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 60,
                  color: lightColorScheme.primary.withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: results.length,
          separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            final user = User.fromJson(results[index]);
            return ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(
                  user.image != null
                      ? '${Env.userImageBaseUrl}${user.image}'
                      : 'https://ui-avatars.com/api/?name=${user.firstName}+${user.lastName}&background=0632A1&color=fff',
                ),
              ),
              title: Text(
                '${user.firstName} ${user.lastName}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserPostsScreen(user: user)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        );
      },
    );
  }
}

class CreatePostSheet extends StatefulWidget {
  final VoidCallback onPostCreated;
  const CreatePostSheet({Key? key, required this.onPostCreated}) : super(key: key);

  @override
  _PostSheetState createState() => _PostSheetState();
}

class UpdatePostSheet extends StatefulWidget {
  final Post post;
  final VoidCallback onPostUpdated;

  const UpdatePostSheet({
    Key? key,
    required this.post,
    required this.onPostUpdated,
  }) : super(key: key);

  @override
  _PostSheetState createState() => _PostSheetState();
}

class _PostSheetState extends State<StatefulWidget> {
  final PostService _postService = PostService();
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _images = [];
  bool _isSubmitting = false;
  ScaffoldMessengerState? _scaffoldMessengerState;

  @override
  void initState() {
    super.initState();
    if (widget is UpdatePostSheet) {
      final post = (widget as UpdatePostSheet).post;
      _descriptionController.text = post.description;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) setState(() => _images = pickedFiles.map((x) => File(x.path)).toList());
  }

  Future<void> _submitPost() async {
    if (_descriptionController.text.trim().isEmpty && _images.isEmpty) {
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text('Please add some content to your post'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget is CreatePostSheet) {
        await _postService.createPost(_descriptionController.text, _images);
        if (mounted) {
          _showPostCreationDialog();
          (widget as CreatePostSheet).onPostCreated();
        }
      } else if (widget is UpdatePostSheet) {
        final post = (widget as UpdatePostSheet).post;
        await _postService.updatePost(post.id, _descriptionController.text, _images);
        if (mounted) {
          _showPostUpdateDialog();
          (widget as UpdatePostSheet).onPostUpdated();
        }
      }
      if (mounted) {
        _descriptionController.clear();
        setState(() => _images.clear());
      }
    } catch (e) {
      debugPrint('Error processing post: $e');
      if (mounted && _scaffoldMessengerState != null) {
        _scaffoldMessengerState!.showSnackBar(
          SnackBar(
            content: Text(widget is CreatePostSheet ? 'Failed to create post' : 'Failed to update post'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPostCreationDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightColorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 50,
                  color: lightColorScheme.primary,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Post Submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your post is under review and will be visible once approved.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightColorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightColorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 50,
                  color: lightColorScheme.primary,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Post Updated',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Your post has been updated and is under review.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightColorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget is UpdatePostSheet;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isUpdate ? 'Update Post' : 'Create Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: lightColorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.all(4),
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
          if (_images.isNotEmpty)
            Container(
              height: 100,
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (_, __) => SizedBox(width: 8),
                itemBuilder: (_, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _images[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _images.removeAt(index)),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: lightColorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.photo_library_outlined,
                      color: lightColorScheme.primary,
                      size: 22,
                    ),
                    onPressed: _pickImages,
                    tooltip: 'Add Photos',
                  ),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightColorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              isUpdate ? 'Updating...' : 'Posting...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isUpdate ? 'Update' : 'Post',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}