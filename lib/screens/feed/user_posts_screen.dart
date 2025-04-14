import 'package:flutter/material.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/services/post_service.dart';
import '../../theme/theme.dart'; // Import your theme
import 'package:pte_mobile/config/env.dart';

class UserPostsScreen extends StatefulWidget {
  final User user;
  final bool showSavedPosts; // Add this parameter

  const UserPostsScreen({
    Key? key, 
    required this.user,
    this.showSavedPosts = false, // Default to false
  }) : super(key: key);

  @override
  State<UserPostsScreen> createState() => _UserPostsScreenState();
}

class _UserPostsScreenState extends State<UserPostsScreen> {
  final PostService _postService = PostService();
  late Future<List<Post>> _userPostsFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Post> _filteredPosts = [];
  bool _showSearch = false;
  double _fabBottomPosition = 16;
  double _fabRightPosition = 16;
  double _searchBarBottomPosition = -100;
  double _searchBarOpacity = 0;

  @override
  void initState() {
    super.initState();
    _userPostsFuture = widget.showSavedPosts
        ? _postService.getUserSavedPosts(widget.user.id) // New method for saved posts
        : _postService.getUserPosts(widget.user.id); // Existing method
    
    _userPostsFuture.then((posts) {
      _filteredPosts = posts;
      return posts;
    });
    _searchController.addListener(_filterPosts);
  }

  void _filterPosts() {
    _userPostsFuture.then((allPosts) {
      setState(() {
        _filteredPosts = _searchController.text.isEmpty
            ? allPosts
            : allPosts.where((post) => post.description
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
                .toList();
      });
    });
  }

  void _toggleSearch() async {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        _fabBottomPosition = 80;
        _searchBarBottomPosition = 80;
        _searchBarOpacity = 1;
      } else {
        _fabBottomPosition = 16;
        _searchBarBottomPosition = -100;
        _searchBarOpacity = 0;
        _searchController.clear();
      }
    });

    if (_showSearch) {
      await Future.delayed(const Duration(milliseconds: 50));
      _searchFocusNode.requestFocus();
    } else {
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Profile Header
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                flexibleSpace: _buildProfileHeader(colorScheme),
              ),

              // Posts Grid
              _buildPostsGrid(colorScheme),
            ],
          ),

          // Search Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _fabRightPosition,
            bottom: _searchBarBottomPosition,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _searchBarOpacity,
              child: _buildSearchBar(isDark),
            ),
          ),

          // Search FAB
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _fabRightPosition,
            bottom: _fabBottomPosition,
            child: FloatingActionButton(
              backgroundColor: colorScheme.primary,
              child: Icon(
                _showSearch ? Icons.close : Icons.search,
                color: colorScheme.onPrimary,
              ),
              onPressed: _toggleSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(color: isDark ? searchText : Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? searchBackground : Colors.white,
            hintText: 'Search posts...',
            hintStyle: TextStyle(color: isDark ? searchPlaceholder : Colors.grey),
            prefixIcon: Icon(Icons.search, 
                color: isDark ? searchPlaceholder : Theme.of(context).colorScheme.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, 
                        color: isDark ? searchPlaceholder : Theme.of(context).colorScheme.primary),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.onPrimary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                widget.user.image != null
                    ? '${Env.userImageBaseUrl}${widget.user.image}'
                    : 'https://ui-avatars.com/api/?name=${widget.user.firstName}+${widget.user.lastName}&background=random',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.user.firstName} ${widget.user.lastName}',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.user.roles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.user.roles.join(' • ').toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(ColorScheme colorScheme) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: FutureBuilder<List<Post>>(
        future: _userPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load posts',
                      style: TextStyle(color: colorScheme.onError),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || _filteredPosts.isEmpty) {
            return SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _searchController.text.isEmpty
                          ? Icons.photo_library_outlined
                          : Icons.search_off,
                      color: colorScheme.onSurface.withOpacity(0.5),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No posts yet'
                          : 'No matching posts',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildPostCard(_filteredPosts[index], colorScheme),
              childCount: _filteredPosts.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(Post post, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        // Handle post tap
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Post Image
              if (post.images.isNotEmpty)
                Image.network(
                  '${Env.imageBaseUrl}${post.images.first}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colorScheme.surfaceVariant,
                    child: Icon(Icons.broken_image, color: colorScheme.onSurfaceVariant),
                  ),
                )
              else
                Container(
                  color: colorScheme.surfaceVariant,
                  child: Center(
                    child: Text(
                      post.description.length > 30
                          ? '${post.description.substring(0, 30)}...'
                          : post.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Post Info
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.description.isNotEmpty)
                      Text(
                        post.description.length > 50
                            ? '${post.description.substring(0, 50)}...'
                            : post.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${post.date.day}/${post.date.month}/${post.date.year}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}