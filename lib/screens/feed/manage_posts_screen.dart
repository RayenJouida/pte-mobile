import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart' as all_posts;
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import '../../theme/theme.dart';
import 'all_posts_screen.dart' as all_posts;

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({Key? key}) : super(key: key);

  @override
  _ManagePostsScreenState createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> {
  final PostService _postService = PostService();
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late ScrollController _scrollController;
  bool _showFloatingButton = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_scrollListener);
    _fetchPosts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_showFloatingButton) setState(() => _showFloatingButton = false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_showFloatingButton) setState(() => _showFloatingButton = true);
    }
  }

  Future<void> _fetchPosts() async {
    try {
      debugPrint("[ManagePosts] === FETCHING POSTS ===");
      // Try getAllPosts first
      List<Post> posts = await _postService.getAllPosts();
      debugPrint("[ManagePosts] Received ${posts.length} posts from getAllPosts");

      // Log all posts
      for (var post in posts) {
        debugPrint("[ManagePosts] Post ID: ${post.id} | Status: ${post.status} | isAccepted: ${post.isAccepted}");
      }

      // If no Approved or Declined posts, try other endpoints
      if (!posts.any((p) => p.status.toLowerCase() == 'approved') || !posts.any((p) => p.status.toLowerCase() == 'declined')) {
        debugPrint("[ManagePosts] No Approved/Declined posts found, trying getAllApprovedPosts");
        try {
          final approvedPosts = await _postService.getAllApprovedPosts();
          debugPrint("[ManagePosts] Received ${approvedPosts.length} approved posts");
          posts.addAll(approvedPosts.where((p) => !posts.any((existing) => existing.id == p.id)));
        } catch (e) {
          debugPrint("[ManagePosts] Error fetching approved posts: $e");
        }

        // Since there's no getAllDeclinedPosts, rely on getAllPosts for now
        // If backend supports getAllDeclinedPosts, add it here
      }

      if (mounted) {
        setState(() {
          _allPosts = posts;
          _applyFilter(_selectedFilter);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[ManagePosts] ERROR: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load posts: $e', Colors.red.shade700);
      }
    }
  }

  void _applyFilter(String filter) {
    debugPrint("[ManagePosts] Applying filter: $filter");
    debugPrint("[ManagePosts] Current posts statuses:");
    for (var post in _allPosts) {
      debugPrint(" - ${post.id}: ${post.status} (isAccepted: ${post.isAccepted})");
    }

    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredPosts = List.from(_allPosts);
      } else {
        // Map filter names to status values
        final statusMap = {
          'Approved': 'approved',
          'Declined': 'declined',
          'Pending': 'pending',
        };

        final expectedStatus = statusMap[filter];
        debugPrint("[ManagePosts] Filtering for status: $expectedStatus");

        _filteredPosts = _allPosts.where((post) {
          bool include;
          if (filter == 'Pending') {
            include = post.status == null || post.status.isEmpty || post.status.toLowerCase() == 'pending';
          } else {
            include = post.status != null && post.status.toLowerCase() == expectedStatus?.toLowerCase();
          }
          debugPrint("Post ${post.id}: Status=${post.status}, Include=$include for filter=$filter");
          return include;
        }).toList();
      }
      
      debugPrint("[ManagePosts] Filtered ${_filteredPosts.length} posts");
      for (var post in _filteredPosts) {
        debugPrint(" - ${post.id}: ${post.status}");
      }
    });
  }

  Future<void> _approvePost(String postId) async {
    try {
      debugPrint("[ManagePosts] Approving post $postId");
      await _postService.managerAcceptPost(postId);
      await _fetchPosts(); // Refresh posts to reflect backend state
      if (mounted) {
        _showSnackBar('Post approved successfully', Colors.green.shade600);
      }
    } catch (e) {
      debugPrint('[ManagePosts] ERROR approving post: $e');
      if (mounted) {
        _showSnackBar('Failed to approve post: $e', Colors.red.shade700);
      }
    }
  }

  Future<void> _declinePost(String postId) async {
    try {
      debugPrint("[ManagePosts] Declining post $postId");
      await _postService.managerDeclinePost(postId);
      await _fetchPosts(); // Refresh posts to reflect backend state
      if (mounted) {
        _showSnackBar('Post declined successfully', Colors.red.shade700);
      }
    } catch (e) {
      debugPrint('[ManagePosts] ERROR declining post: $e');
      if (mounted) {
        _showSnackBar('Failed to decline post: $e', Colors.red.shade700);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Approved', 'Pending', 'Declined'];
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: 10),
              child: FilterChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : lightColorScheme.primary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) => _applyFilter(filter),
                selectedColor: lightColorScheme.primary,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: lightColorScheme.primary.withOpacity(0.2)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                elevation: isSelected ? 2 : 0,
              ).animate().fadeIn(duration: 300.ms).scaleXY(
                begin: 0.9,
                end: 1.0,
                duration: 300.ms,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    Widget? actionButton;
    if (_selectedFilter == 'All') {
      message = 'There are no posts available';
    } else if (_selectedFilter == 'Pending') {
      message = 'No pending posts available';
    } else if (_selectedFilter == 'Approved') {
      message = 'No approved posts found';
      actionButton = ElevatedButton(
        onPressed: () {
          _approvePost(_allPosts.isNotEmpty ? _allPosts.first.id : '');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Approve a Post'),
      );
    } else {
      message = 'No declined posts found';
      actionButton = ElevatedButton(
        onPressed: () {
          _declinePost(_allPosts.isNotEmpty ? _allPosts.first.id : '');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('Decline a Post'),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: lightColorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.feed_outlined, size: 60, color: lightColorScheme.primary),
          ).animate().fadeIn(duration: 500.ms).scale(),
          SizedBox(height: 24),
          Text(
            'No posts found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: lightColorScheme.onSurface,
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(),
          SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ).animate().fadeIn(duration: 500.ms).slideY(delay: 100.ms),
          SizedBox(height: 24),
          if (actionButton != null) actionButton.animate().fadeIn(duration: 500.ms).scale(),
          ElevatedButton(
            onPressed: _fetchPosts,
            style: ElevatedButton.styleFrom(
              backgroundColor: lightColorScheme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Refresh', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).scale(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Manage Posts',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.w600,
            color: lightColorScheme.primary,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: lightColorScheme.primary, size: 24),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: lightColorScheme.primary, size: 22),
            onPressed: _fetchPosts,
            tooltip: 'Refresh',
          ),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      drawer: AdminSidebar(currentIndex: 8, onTabChange: (index) {}),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: lightColorScheme.primary, strokeWidth: 3),
                  SizedBox(height: 16),
                  Text(
                    'Loading posts...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn()
          : RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _fetchPosts,
              color: lightColorScheme.primary,
              child: Column(
                children: [
                  _buildFilterChips(),
                  Expanded(
                    child: _filteredPosts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(top: 12, bottom: 12, left: 12, right: 12),
                            itemCount: _filteredPosts.length,
                            itemBuilder: (_, index) {
                              final post = _filteredPosts[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        all_posts.PostCard(
                                          post: post,
                                          onSaveToggled: (_) {},
                                          onLikeToggled: (_) {},
                                          isSaved: false,
                                          isLiked: false, onHidePost: () {  }, onPostUpdated: () {  }, onPostDeleted: () {  },
                                        ),
                                        if (post.status == null || post.status.isEmpty || post.status.toLowerCase() == 'pending') ...[
                                          SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () => _approvePost(post.id),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade600,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: isSmallScreen ? 12 : 16,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Approve',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ).animate().fadeIn(),
                                              SizedBox(width: 12),
                                              OutlinedButton(
                                                onPressed: () => _declinePost(post.id),
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.red.shade600),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: isSmallScreen ? 12 : 16,
                                                    vertical: 10,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Decline',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.red.shade600,
                                                  ),
                                                ),
                                              ).animate().fadeIn(),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms).scale(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: _showFloatingButton ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _showFloatingButton ? 1.0 : 0.0,
          child: FloatingActionButton(
            onPressed: _fetchPosts,
            backgroundColor: lightColorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.refresh, size: 24),
          ),
        ),
      ),
    );
  }
}