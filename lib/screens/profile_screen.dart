import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/edit_profile_screen.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme.dart';
import '../config/env.dart'; // Added this import

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  bool isLoading = true;
  String? errorMessage;
  final UserService _userService = UserService();
  final PostService _postService = PostService();
  List<Post> userPosts = [];
  List<Post> likedPosts = [];
  List<Post> savedPosts = [];
  int postCount = 0;
  int savedCount = 0;
  int likesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserDetailsAndPosts();
  }

  Future<void> _fetchUserDetailsAndPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception('No user ID found');
      debugPrint('Fetching for userId: $userId');

      final userData = await _userService.getUserById(userId);
      final posts = await _postService.getUserPosts(userId);
      debugPrint('User Posts fetched: ${posts.length}');
      final saved = await _postService.getUserSavedPosts(userId);
      debugPrint('Saved Posts fetched: ${saved.length}');

      // Calculate likes from userPosts first
      int totalLikes = 0;
      for (var post in posts) {
        totalLikes += post.likes.length;
        debugPrint('User Post ${post.id} has ${post.likes.length} likes: ${post.likes.map((like) => like.user).toList()}');
      }
      debugPrint('Total Likes from userPosts: $totalLikes');

      // Try fetching all approved posts
      final allPosts = await _postService.getAllApprovedPosts();
      debugPrint('All Approved Posts fetched: ${allPosts.length}');
      for (var post in allPosts) {
        debugPrint('Approved Post ${post.id} has ${post.likes.length} likes: ${post.likes.map((like) => like.user).toList()}');
      }
      final likedFromAll = allPosts.where((post) => post.likes.any((like) => like.user == userId)).toList();
      debugPrint('Liked Posts from allPosts: ${likedFromAll.length}');
      if (likedFromAll.isNotEmpty) {
        debugPrint('Liked Posts IDs: ${likedFromAll.map((p) => p.id).toList()}');
      }

      // Fallback if allPosts fails
      List<Post> liked = likedFromAll;
      if (liked.isEmpty && totalLikes > 0) {
        debugPrint('Mismatch detected! Likes exist but no liked posts found in allPosts.');
        // Try a direct liked posts fetch (assuming endpoint exists)
        try {
          liked = await _postService.getUserLikedPosts(userId); // Hypothetical method
          debugPrint('Liked Posts from direct fetch: ${liked.length}');
          if (liked.isNotEmpty) {
            debugPrint('Direct fetch succeeded! Liked Post IDs: ${liked.map((p) => p.id).toList()}');
          }
        } catch (e) {
          debugPrint('Direct fetch failed: $e. Falling back to userPosts filter.');
          // Fallback to filtering userPosts (though this only shows user's own liked posts)
          liked = posts.where((post) => post.likes.any((like) => like.user == userId)).toList();
          debugPrint('Liked Posts from userPosts fallback: ${liked.length}');
        }
      }

      setState(() {
        user = User.fromJson(userData);
        userPosts = posts;
        savedPosts = saved;
        likedPosts = liked;
        postCount = posts.length;
        savedCount = saved.length;
        likesCount = totalLikes;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching profile data: $e');
      setState(() {
        errorMessage = 'Failed to load profile: $e';
        isLoading = false;
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  String _getFlagEmoji(String? nationality) {
    if (nationality == null) return '🌍';
    switch (nationality.toLowerCase()) {
      case 'tunisia': return '🇹🇳';
      case 'usa': return '🇺🇸';
      case 'france': return '🇫🇷';
      case 'argentina': return '🇦🇷';
      default: return '🌍';
    }
  }

  IconData _getGenderIcon(String? gender) {
    if (gender == null) return FontAwesomeIcons.genderless;
    switch (gender.toLowerCase()) {
      case 'male': return FontAwesomeIcons.mars;
      case 'female': return FontAwesomeIcons.venus;
      default: return FontAwesomeIcons.genderless;
    }
  }

  void _showAboutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(FontAwesomeIcons.idCard, 'Matricule', user?.matricule ?? 'N/A', colorScheme),
            _buildInfoRow(FontAwesomeIcons.phone, 'Phone', user?.phone ?? 'N/A', colorScheme),
            _buildInfoRow(FontAwesomeIcons.building, 'Department', user?.department ?? 'N/A', colorScheme),
            _buildInfoRow(FontAwesomeIcons.briefcase, 'Experience', user?.experience.toString() ?? 'N/A', colorScheme),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(child: Text(errorMessage!, style: TextStyle(color: colorScheme.error, fontSize: 18))),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: colorScheme.surface,
              elevation: 0,
              toolbarHeight: 70,
              leadingWidth: 160, // Adjusted for logo only
              leading: Center(
                child: Image.asset(
                  'assets/images/prologic.png',
                  width: 150,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout, size: 26, color: colorScheme.primary),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: colorScheme.primary.withOpacity(0.2)),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colorScheme.secondary, width: 2),
                          ),
                          child: ClipOval(
                            child: user?.image != null && user!.image!.isNotEmpty
                                ? Image.network(
                                    '${Env.userImageBaseUrl}${user!.image!}', // Updated to use Env
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 50,
                                      color: colorScheme.onSurface,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/default_avatar.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn('Posts', postCount.toString(), colorScheme),
                              _buildStatColumn('Saved', savedCount.toString(), colorScheme),
                              _buildStatColumn('Likes', likesCount.toString(), colorScheme),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user?.firstName ?? 'Unknown'} ${user?.lastName ?? ''}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                        if (user?.bio != null && user!.bio!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              user!.bio!,
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
                            ),
                          ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(_getGenderIcon(user?.gender), color: colorScheme.secondary, size: 16),
                            SizedBox(width: 4),
                            Text(
                              user?.gender ?? 'N/A',
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
                            ),
                            SizedBox(width: 12),
                            Text(
                              _getFlagEmoji(user?.nationality),
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(width: 4),
                            Text(
                              user?.nationality ?? 'N/A',
                              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
                            ),
                          ],
                        ),
                        if (user?.isEnabled == "Active")
                          Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(fontSize: 14, color: colorScheme.primary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if ((user?.cv != null) || (user?.github != null) || (user?.linkedin != null))
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (user?.cv != null) _buildSocialLink(FontAwesomeIcons.solidFileAlt, 'CV', Colors.blueAccent, colorScheme),
                          if (user?.github != null) _buildSocialLink(FontAwesomeIcons.github, 'GitHub', Colors.grey[800]!, colorScheme),
                          if (user?.linkedin != null) _buildSocialLink(FontAwesomeIcons.linkedin, 'LinkedIn', Colors.blue[700]!, colorScheme),
                        ],
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showAboutDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('About', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen(user: user!))),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: colorScheme.primary, width: 2),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              'Edit Profile',
                              style: TextStyle(fontSize: 16, color: colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: colorScheme.primary,
                  tabs: [
                    Tab(icon: Icon(FontAwesomeIcons.pen, size: 18), text: 'Posts'),
                    Tab(icon: Icon(FontAwesomeIcons.heart, size: 18), text: 'Liked'),
                    Tab(icon: Icon(FontAwesomeIcons.bookmark, size: 18), text: 'Saved'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildPostGrid(userPosts, colorScheme),
              _buildPostGrid(likedPosts, colorScheme),
              _buildPostGrid(savedPosts, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildSocialLink(IconData icon, String label, Color color, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {},
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.secondary, size: 18),
          SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(List<Post> posts, ColorScheme colorScheme) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'No posts yet',
          style: TextStyle(fontSize: 16, color: colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
    }
    return GridView.builder(
      padding: EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final imageUrl = post.images.isNotEmpty ? '${Env.imageBaseUrl}${post.images.first}' : 'https://via.placeholder.com/150'; // Updated to use Env
        debugPrint('Loading image: $imageUrl');
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Image load failed: $imageUrl, Error: $error');
            return Container(
              color: colorScheme.surface,
              child: Icon(Icons.broken_image, color: colorScheme.onSurface.withOpacity(0.6)),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}