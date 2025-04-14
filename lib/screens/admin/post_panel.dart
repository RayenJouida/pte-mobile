import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/user.dart';
import 'package:pte_mobile/screens/admin/admin_sidebar.dart';
import 'package:pte_mobile/services/post_service.dart';
import 'package:pte_mobile/services/user_service.dart';
import '../../config/env.dart'; // Added this import

class PostPanel extends StatefulWidget {
  const PostPanel({super.key});

  @override
  State<PostPanel> createState() => _PostPanelState();
}

class _PostPanelState extends State<PostPanel> with SingleTickerProviderStateMixin {
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  List<Post> _approvedPosts = [];
  List<Post> _pendingPosts = [];
  List<User> _users = [];
  User? _selectedUser;
  Map<String, int> _commentCounts = {};
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final approved = await _postService.getAllApprovedPosts();
      final allPosts = await _postService.getAllPosts();
      final pending = allPosts.where((p) => p.status == 'Pending' && !p.isAccepted).toList();
      final usersData = await _userService.fetchUsers();
      final users = usersData.map((data) => User.fromJson(data)).toList();

      final commentCounts = <String, int>{};
      for (final post in [...approved, ...pending]) {
        final comments = await _postService.getPostComments(post.id);
        commentCounts[post.id] = comments.length;
      }

      setState(() {
        _approvedPosts = approved;
        _pendingPosts = pending;
        _users = users;
        _commentCounts = commentCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptPost(String postId) async {
    try {
      await _postService.managerAcceptPost(postId);
      setState(() {
        _pendingPosts.removeWhere((p) => p.id == postId);
        _fetchData();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post Approved'),
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Future<void> _declinePost(String postId) async {
    try {
      await _postService.managerDeclinePost(postId);
      setState(() => _pendingPosts.removeWhere((p) => p.id == postId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post Declined'),
          backgroundColor: Theme.of(context).colorScheme.error.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Decline Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _showPostDetails(BuildContext context, Post post) {
    final theme = Theme.of(context);
    final userName = post.user != null ? '${post.user!.firstName} ${post.user!.lastName}' : 'Unknown User';
    final userImage = post.user?.image != null
        ? '${Env.userImageBaseUrl}${post.user!.image}'
        : 'https://ui-avatars.com/api/?name=${post.user?.firstName ?? "U"}+${post.user?.lastName ?? ""}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(radius: 20, backgroundImage: NetworkImage(userImage)),
                        const SizedBox(width: 12),
                        Text(userName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.colorScheme.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${Env.imageBaseUrl}${post.images.first}',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image, color: Colors.grey),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.description, style: theme.textTheme.bodyMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(FontAwesomeIcons.heart, size: 16, color: Colors.red),
                                const SizedBox(width: 4),
                                Text('${post.likes.length} Likes', style: theme.textTheme.bodySmall),
                                const SizedBox(width: 16),
                                const Icon(FontAwesomeIcons.comment, size: 16, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text('${_commentCounts[post.id] ?? 0} Comments', style: theme.textTheme.bodySmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            FutureBuilder<List<Comment>>(
                              future: _postService.getPostComments(post.id),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}', style: TextStyle(color: theme.colorScheme.error));
                                }
                                final comments = snapshot.data ?? [];
                                if (comments.isEmpty) {
                                  return const Text('No comments yet', style: TextStyle(color: Colors.grey));
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    final commentUserName = '${comment.user.firstName} ${comment.user.lastName}';
                                    final commentUserImage = comment.user.image != null
                                        ? '${Env.userImageBaseUrl}${comment.user.image}'
                                        : 'https://ui-avatars.com/api/?name=${comment.user.firstName}+${comment.user.lastName}';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(radius: 18, backgroundImage: NetworkImage(commentUserImage)),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(commentUserName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                Text(comment.text, style: theme.textTheme.bodySmall),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 18))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(FontAwesomeIcons.pen, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Posts Panel', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: theme.colorScheme.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<User>(
                value: _selectedUser,
                hint: Text('Select User', style: TextStyle(color: theme.colorScheme.primary)),
                items: _users.map((user) => DropdownMenuItem<User>(
                  value: user,
                  child: Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontSize: 14)),
                )).toList(),
                onChanged: (user) => setState(() => _selectedUser = user),
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2))),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              tabs: [
                Tab(icon: Icon(FontAwesomeIcons.checkCircle, size: 18), text: 'Approved'),
                Tab(icon: Icon(FontAwesomeIcons.clock, size: 18), text: 'Pending'),
              ],
            ),
          ),
        ),
      ),
      drawer: const AdminSidebar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostList(_approvedPosts, isPending: false),
          _buildPostList(_pendingPosts, isPending: true),
        ],
      ),
    );
  }

  Widget _buildPostList(List<Post> posts, {required bool isPending}) {
    final theme = Theme.of(context);
    final filteredPosts = _selectedUser != null
        ? posts.where((post) => post.user?.id == _selectedUser!.id).toList()
        : posts;

    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: theme.colorScheme.primary.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              _selectedUser != null ? 'No posts yet' : 'No posts available',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedUser != null ? 'This user hasn’t posted yet' : 'Check back later',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: filteredPosts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final post = filteredPosts[index];
        final userImage = post.user?.image != null
            ? '${Env.userImageBaseUrl}${post.user!.image}'
            : 'https://ui-avatars.com/api/?name=${post.user?.firstName ?? "U"}+${post.user?.lastName ?? ""}';
        final commentCount = _commentCounts[post.id] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(radius: 22, backgroundImage: NetworkImage(userImage)),
                title: Text(
                  post.user != null ? '${post.user!.firstName} ${post.user!.lastName}' : 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  'Post ID: ${post.id.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () => _showPostDetails(context, post),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(post.description, style: const TextStyle(fontSize: 14)),
              ),
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    '${Env.imageBaseUrl}${post.images.first}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
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
                        const Icon(FontAwesomeIcons.heart, size: 22, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('${post.likes.length}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.comment, size: 22, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('$commentCount', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                    if (isPending)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.check, color: theme.colorScheme.primary, size: 22),
                            onPressed: () => _acceptPost(post.id),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: theme.colorScheme.error, size: 22),
                            onPressed: () => _declinePost(post.id),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}