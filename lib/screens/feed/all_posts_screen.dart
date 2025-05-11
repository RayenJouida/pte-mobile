import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pte_mobile/config/env.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:pte_mobile/screens/feed/post_details.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/services/auth_service.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import '../../theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/models/comment.dart';

class AllPostsScreen extends StatefulWidget {
  const AllPostsScreen({Key? key}) : super(key: key);

  @override
  _AllPostsScreenState createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> with TickerProviderStateMixin {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  List<String> _likedPostIds = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // Default filter
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _fetchPosts();
    await _fetchLikedPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await _postService.getAllPosts();
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _applyFilter(_selectedFilter);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLikedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId != null) {
        final posts = await _postService.getAllPosts();
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

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredPosts = _allPosts;
      } else {
        _filteredPosts = _allPosts.where((post) {
          return post.status.toLowerCase() == filter.toLowerCase();
        }).toList();
      }
    });
  }

  void _showLikedMessage(bool isLiked) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(isLiked ? "Post liked" : "Post unliked"),
            ],
          ),
          backgroundColor: isLiked ? Colors.pink.shade400 : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
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
          final postIndex = _allPosts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            _allPosts[postIndex] = updatedPost;
          }
          _applyFilter(_selectedFilter); // Reapply filter to update _filteredPosts
          _showLikedMessage(!wasLiked);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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

  Widget _buildFilterChips() {
    final filters = ['All', 'Accepted', 'Pending', 'Denied'];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : lightColorScheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) _applyFilter(filter);
                },
                selectedColor: lightColorScheme.primary,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: lightColorScheme.primary.withOpacity(0.2)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: isSelected ? 2 : 0,
              ),
            );
          }).toList(),
        ),
      ),
    );
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
            'No posts found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: lightColorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'There are no posts available.'
                : 'No $_selectedFilter posts available.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
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
              delegate: UserSearchDelegate(
                userService: _userService,
                authService: _authService,
                theme: Theme.of(context),
              ),
            ),
            tooltip: 'Search',
          ),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      drawer: AdminSidebar(
        currentIndex: 7, // Set to "See all Posts" index from AdminSidebar
        onTabChange: (index) {},
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
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: RefreshIndicator(
                    key: _refreshIndicatorKey,
                    onRefresh: _loadInitialData,
                    color: lightColorScheme.primary,
                    child: _filteredPosts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(top: 12, bottom: 80),
                            itemCount: _filteredPosts.length,
                            itemBuilder: (_, index) {
                              final post = _filteredPosts.reversed.toList()[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: 12,
                                  left: 12,
                                  right: 12,
                                ),
                                child: PostCard(
                                  post: post,
                                  onSaveToggled: (_) {}, // Save functionality not needed for admin view
                                  onLikeToggled: _toggleLikePost,
                                  isSaved: false,
                                  isLiked: _likedPostIds.contains(post.id),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Reusing PostCard and related widgets from FeedScreen (assumed to be in a shared location)
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
  bool _isImageExpanded = false;

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

  void _toggleImageExpansion() {
    setState(() {
      _isImageExpanded = !_isImageExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final likes = widget.post.likes;

    return Container(
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
          // User info header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(
                    widget.post.user.image != null
                        ? '${Env.userImageBaseUrl}${widget.post.user.image}'
                        : 'https://ui-avatars.com/api/?name=${widget.post.user.firstName}+${widget.post.user.lastName}&background=0632A1&color=fff',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.post.user.firstName} ${widget.post.user.lastName}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDateTime(widget.post.date),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.post.status.toLowerCase() == 'accepted'
                                  ? Colors.green.shade100
                                  : widget.post.status.toLowerCase() == 'pending'
                                      ? Colors.orange.shade100
                                      : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.post.status,
                              style: TextStyle(
                                color: widget.post.status.toLowerCase() == 'accepted'
                                    ? Colors.green.shade800
                                    : widget.post.status.toLowerCase() == 'pending'
                                        ? Colors.orange.shade800
                                        : Colors.red.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey.shade700, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),

          // Post description
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

          // Post images
          if (widget.post.images.isNotEmpty) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(postId: widget.post.id)),
              ),
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

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Like button
                _buildActionButton(
                  icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: widget.isLiked ? Colors.pink.shade400 : Colors.grey.shade700,
                  count: likes.length,
                  countColor: widget.isLiked ? Colors.pink.shade400 : Colors.grey.shade700,
                  onPressed: () async {
                    await _triggerAnimation();
                    widget.onLikeToggled(widget.post.id);
                  },
                  animation: _scaleAnimation,
                  controller: _controller,
                ),

                SizedBox(width: 16),

                // Comment button
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  color: lightColorScheme.primary,
                  onPressed: _showCommentsSheet,
                ),

                Spacer(),

                // Save button (disabled for admin view)
                IconButton(
                  icon: Icon(
                    widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: null,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
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
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _formatCommentTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return '';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
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
          // Handle bar for dragging
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Comments list
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

          // Comment input
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