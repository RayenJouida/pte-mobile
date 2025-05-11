import 'package:flutter/material.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/screens/feed/feed_screen.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:pte_mobile/services/auth_service.dart';
import 'package:pte_mobile/widgets/admin_sidebar.dart';
import '../../theme/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'all_posts_screen.dart' as all_posts; // To reuse PostCard

class ManagePostsScreen extends StatefulWidget {
  const ManagePostsScreen({Key? key}) : super(key: key);

  @override
  _ManagePostsScreenState createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends State<ManagePostsScreen> {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All'; // Default filter
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fetchPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _approvePost(String postId) async {
    try {
      await _postService.managerAcceptPost(postId);
      if (mounted) {
        setState(() {
          final postIndex = _allPosts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            // Manually create a new Post instance with updated status
            final updatedPost = Post(
              id: _allPosts[postIndex].id,
              user: _allPosts[postIndex].user,
              description: _allPosts[postIndex].description,
              images: _allPosts[postIndex].images,
              likes: _allPosts[postIndex].likes,
              status: 'Accepted',
              date: _allPosts[postIndex].date,
            );
            _allPosts[postIndex] = updatedPost;
          }
          _applyFilter(_selectedFilter);
          _showSnackBar('Post approved successfully', Colors.green.shade700);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to approve post', Colors.red.shade700);
      }
    }
  }

  Future<void> _declinePost(String postId) async {
    try {
      await _postService.managerDeclinePost(postId);
      if (mounted) {
        setState(() {
          final postIndex = _allPosts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            // Manually create a new Post instance with updated status
            final updatedPost = Post(
              id: _allPosts[postIndex].id,
              user: _allPosts[postIndex].user,
              description: _allPosts[postIndex].description,
              images: _allPosts[postIndex].images,
              likes: _allPosts[postIndex].likes,
              status: 'Denied',
              date: _allPosts[postIndex].date,
            );
            _allPosts[postIndex] = updatedPost;
          }
          _applyFilter(_selectedFilter);
          _showSnackBar('Post declined successfully', Colors.red.shade700);
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to decline post', Colors.red.shade700);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
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
        currentIndex: 8, // Assuming "Manage Posts" is the 8th item in AdminSidebar
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
                    onRefresh: _fetchPosts,
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
                                child: Column(
                                  children: [
                                    all_posts.PostCard(
                                      post: post,
                                      onSaveToggled: (_) {},
                                      onLikeToggled: (_) {}, // Like functionality disabled for admin
                                      isSaved: false,
                                      isLiked: false,
                                    ),
                                    if (post.status.toLowerCase() == 'pending') ...[
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _approvePost(post.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                            ),
                                            child: Text(
                                              'Approve',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: () => _declinePost(post.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red.shade600,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 10,
                                              ),
                                            ),
                                            child: Text(
                                              'Decline',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
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