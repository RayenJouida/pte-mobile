import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/feed/post_details.dart';
import 'package:pte_mobile/screens/messaging/home_messages_screen.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/auth_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import '../../theme/theme.dart';
import 'package:pte_mobile/screens/feed/user_posts_screen.dart';
import '../../widgets/assistant_navbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import 'package:pte_mobile/config/env.dart';
import '../../models/activity.dart';

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
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Post saved"),
          backgroundColor: lightColorScheme.primary.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showLikedMessage(bool isLiked) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isLiked ? "Post liked" : "Post unliked"),
          backgroundColor: Colors.red.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      await _fetchSavedPosts();
      if (!isCurrentlySaved) _showSavedMessage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save/unsave")),
        );
      }
    }
  }

  Future<void> _toggleLikePost(String postId) async {
    try {
      final updatedPost = await _postService.likePost(postId);
      if (mounted) {
        setState(() {
          final wasLiked = _likedPostIds.contains(postId);
          if (wasLiked) {
            _likedPostIds.remove(postId);
          } else {
            _likedPostIds.add(postId);
          }
          final postIndex = _posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            _posts[postIndex] = updatedPost;
          }
          _showLikedMessage(!wasLiked);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to like/unlike")),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
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
          Icon(Icons.inbox_outlined, size: 60, color: lightColorScheme.primary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text('No posts yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Start the conversation!', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _openCreatePostSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: lightColorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        centerTitle: true,
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 120,
        leading: Center(
          child: Image.asset('assets/images/prologic.png', width: 180, height: 50, fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, size: 26, color: lightColorScheme.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HomeMessagesScreen())),
            tooltip: 'Messages',
          ),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, size: 26, color: lightColorScheme.primary),
                    onPressed: _showActivitySheet,
                    tooltip: 'Notifications',
                  ),
                  if (notificationProvider.unreadActivityCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notificationProvider.unreadActivityCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, size: 26, color: lightColorScheme.primary),
            onPressed: () => showSearch(
              context: context,
              delegate: UserSearchDelegate(userService: _userService, authService: _authService, theme: Theme.of(context)),
            ),
            tooltip: 'Search',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: lightColorScheme.primary.withOpacity(0.2)),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: lightColorScheme.primary))
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _loadInitialData,
              color: lightColorScheme.primary,
              child: _posts.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => FadeTransition(
                        opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                            parent: AnimationController(
                              duration: const Duration(milliseconds: 300),
                              vsync: this,
                              value: 1,
                            )..forward(),
                            curve: Curves.easeIn,
                          ),
                        ),
                        child: PostCard(
                          post: _posts.reversed.toList()[index],
                          onSaveToggled: _toggleSavePost,
                          onLikeToggled: _toggleLikePost,
                          isSaved: _savedPosts.any((p) => p.id == _posts.reversed.toList()[index].id),
                          isLiked: _likedPostIds.contains(_posts.reversed.toList()[index].id),
                        ),
                      ),
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePostSheet,
        backgroundColor: lightColorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
      ),
      bottomNavigationBar: AssistantNavbar(currentIndex: _currentIndex, onTabChange: _onTabChange),
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

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    try {
      final activities = await _postService.fetchUserActivities(widget.userId);
      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching activities: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
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
        color: lightColorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightColorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.close, color: lightColorScheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: lightColorScheme.primary))
                : _activities.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none, size: 40, color: lightColorScheme.primary.withOpacity(0.6)),
                            const SizedBox(height: 8),
                            const Text('No notifications yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const Text('You\'ll see updates here!', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _activities.length,
                        itemBuilder: (context, index) {
                          final activity = _activities[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                activity.actor['image'] != null && (activity.actor['image'] as String).isNotEmpty
                                    ? '${Env.userImageBaseUrl}${activity.actor['image']}'
                                    : 'https://ui-avatars.com/api/?name=${activity.actor['firstName'] ?? 'Unknown'}+${activity.actor['lastName'] ?? 'User'}',
                              ),
                            ),
                            title: Text(
                              '${activity.actor['firstName']} ${activity.actor['lastName']} ${activity.type == 'like' ? 'liked' : 'commented on'} your post',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              _formatTimestamp(activity.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            onTap: () => _navigateToPost(activity.post?['_id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;
  final Function(String) onSaveToggled;
  final Function(String) onLikeToggled;
  final bool isSaved;
  final bool isLiked;

  const PostCard({
    Key? key,
    required this.post,
    required this.onSaveToggled,
    required this.onLikeToggled,
    required this.isSaved,
    required this.isLiked,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    return '${difference.inDays}d';
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(postId: widget.post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final likes = widget.post.likes ?? [];

    return Container(
      decoration: BoxDecoration(
        color: lightColorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: lightColorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(
                widget.post.user.image != null
                    ? '${Env.userImageBaseUrl}${widget.post.user.image}'
                    : 'https://ui-avatars.com/api/?name=${widget.post.user.firstName}+${widget.post.user.lastName}',
              ),
            ),
            title: Text(
              '${widget.post.user.firstName} ${widget.post.user.lastName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            subtitle: Text(_formatDateTime(widget.post.date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserPostsScreen(user: widget.post.user))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(widget.post.description, style: const TextStyle(fontSize: 14)),
          ),
          if (widget.post.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: widget.post.images.length,
                  itemBuilder: (_, index) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: widget.post.id)),
                    ),
                    child: Image.network(
                      '${Env.imageBaseUrl}${widget.post.images[index]}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          widget.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: widget.isLiked ? Colors.red : lightColorScheme.primary,
                          size: 22,
                        ),
                      ),
                      onPressed: () async {
                        await _triggerAnimation();
                        widget.onLikeToggled(widget.post.id);
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${likes.length}',
                      style: TextStyle(
                        color: widget.isLiked ? Colors.red : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.comment_outlined, color: lightColorScheme.primary, size: 22),
                  onPressed: _showCommentsSheet,
                ),
                IconButton(
                  icon: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Icon(widget.isSaved ? Icons.bookmark : Icons.bookmark_border, size: 22),
                  ),
                  color: widget.isSaved ? lightColorScheme.primary : Colors.grey,
                  onPressed: () async {
                    await _triggerAnimation();
                    widget.onSaveToggled(widget.post.id);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    _fetchComments();
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
    try {
      final newComment = await _postService.addComment(widget.postId, _commentController.text);
      if (mounted) {
        setState(() {
          _comments.add(newComment);
          _commentController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your comment has been added'),
            backgroundColor: lightColorScheme.primary.withOpacity(0.85),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: lightColorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightColorScheme.surface,
              border: Border(bottom: const BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.close, color: lightColorScheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: lightColorScheme.primary))
                : _comments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 40, color: lightColorScheme.primary.withOpacity(0.6)),
                            const SizedBox(height: 8),
                            const Text('No comments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const Text('Be the first!', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(
                                    comment.user.image != null
                                        ? '${Env.userImageBaseUrl}${comment.user.image}'
                                        : 'https://ui-avatars.com/api/?name=${comment.user.firstName}+${comment.user.lastName}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${comment.user.firstName} ${comment.user.lastName}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      Text(comment.text, style: const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: lightColorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: lightColorScheme.primary.withOpacity(0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: lightColorScheme.primary),
                  onPressed: _addComment,
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
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        foregroundColor: lightColorScheme.primary,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Image.asset('assets/images/prologic.png', width: 36, height: 36),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.length < 2) return const Center(child: Text('Enter at least 2 characters'));

    return FutureBuilder<List>(
      future: userService.fetchUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: lightColorScheme.primary));
        }
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

        final users = snapshot.data ?? [];
        final results = users.where((user) {
          final userData = User.fromJson(user);
          final matchesName = userData.firstName.toLowerCase().contains(query.toLowerCase()) ||
              userData.lastName.toLowerCase().contains(query.toLowerCase());
          final isNotCurrentUser = currentUserId == null || userData.id != currentUserId;
          return matchesName && isNotCurrentUser;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = User.fromJson(results[index]);
            return ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  user.image != null
                      ? '${Env.userImageBaseUrl}${user.image}'
                      : 'https://ui-avatars.com/api/?name=${user.firstName}+${user.lastName}',
                ),
              ),
              title: Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserPostsScreen(user: user))),
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
  _CreatePostSheetState createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final PostService _postService = PostService();
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _images = [];
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage();
    if (pickedFiles != null) setState(() => _images = pickedFiles.map((x) => File(x.path)).toList());
  }

  Future<void> _submitPost() async {
    if (_descriptionController.text.trim().isEmpty && _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please add some content!'), backgroundColor: lightColorScheme.error),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _postService.createPost(_descriptionController.text, _images);
      _descriptionController.clear();
      _images.clear();
      widget.onPostCreated();
      _showPostPendingDialog();
    } catch (e) {
      debugPrint('Error creating post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to post'), backgroundColor: lightColorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPostPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        backgroundColor: lightColorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 50, color: lightColorScheme.primary.withOpacity(0.9)),
              const SizedBox(height: 12),
              const Text('Post Submitted', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Your post is under review.', style: TextStyle(color: lightColorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightColorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: lightColorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Create a Post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: Icon(Icons.close, color: lightColorScheme.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'What’s on your mind?',
                filled: true,
                fillColor: lightColorScheme.background.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          if (_images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_images[index], width: 100, height: 100, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.removeAt(index)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.photo_outlined, color: lightColorScheme.primary, size: 28),
                  onPressed: _pickImages,
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightColorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: lightColorScheme.onPrimary)
                      : const Text('Post', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}