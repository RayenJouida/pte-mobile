import 'package:flutter/material.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:pte_mobile/services/post_service.dart';
import '../../theme/theme.dart';
import '../../config/env.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  _PostDetailScreenState createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  late Future<Post> _postFuture;
  late Future<List<Comment>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _postFuture = _postService.getPostById(widget.postId);
    _commentsFuture = _postService.getPostComments(widget.postId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _postFuture = _postService.getPostById(widget.postId);
      _commentsFuture = _postService.getPostComments(widget.postId);
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSendingComment = true);
    try {
      await _postService.addComment(widget.postId, _commentController.text.trim());
      _commentController.clear();
      await _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Comment added'),
          backgroundColor: lightColorScheme.primary.withOpacity(0.85),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add comment: $e'),
          backgroundColor: lightColorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      color: lightColorScheme.primary,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  Icons.fullscreen_exit,
                  color: lightColorScheme.onPrimary,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Reduce',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final imageHeight = constraints.maxHeight * (isSmallScreen ? 0.35 : 0.45);
        final fontScale = isSmallScreen ? 0.9 : 1.0;
        final inputHeight = 70.0 * fontScale;

        return Scaffold(
          backgroundColor: lightColorScheme.background,
          appBar: AppBar(
            backgroundColor: lightColorScheme.surface,
            elevation: 0,
            toolbarHeight: 70 * fontScale,
            leadingWidth: 120 * fontScale,
            leading: Center(
              child: Image.asset(
                'assets/images/prologic.png',
                width: 180 * fontScale,
                height: 50 * fontScale,
                fit: BoxFit.contain,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: lightColorScheme.primary, size: 24 * fontScale),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: lightColorScheme.primary.withOpacity(0.2)),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Image Section
                SizedBox(
                  height: imageHeight,
                  width: constraints.maxWidth,
                  child: FutureBuilder<Post>(
                    future: _postFuture,
                    builder: (context, postSnapshot) {
                      if (postSnapshot.connectionState == ConnectionState.waiting ||
                          !postSnapshot.hasData) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(color: lightColorScheme.primary),
                          ),
                        );
                      }
                      final post = postSnapshot.data!;
                      return Stack(
                        children: [
                          post.images.isNotEmpty
                              ? PageView(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                  },
                                  children: post.images.map((image) {
                                    return Stack(
                                      children: [
                                        InteractiveViewer(
                                          panEnabled: true,
                                          minScale: 1,
                                          maxScale: 3,
                                          child: Image.network(
                                            '${Env.imageBaseUrl}$image',
                                            fit: BoxFit.cover,
                                            width: constraints.maxWidth,
                                            height: imageHeight,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  color: lightColorScheme.primary,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8 * fontScale,
                                          right: 8 * fontScale,
                                          child: IconButton(
                                            icon: Icon(
                                              Icons.fullscreen,
                                              color: lightColorScheme.onPrimary,
                                              size: 24 * fontScale,
                                            ),
                                            onPressed: () => _showFullScreenImage('${Env.imageBaseUrl}$image'),
                                            tooltip: 'Expand',
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ).animate().fadeIn(duration: const Duration(milliseconds: 300))
                              : Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(Icons.image_not_supported, size: 50 * fontScale, color: Colors.grey),
                                  ),
                                ),
                          if (post.images.length > 1)
                            Positioned(
                              bottom: 10 * fontScale,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: post.images.asMap().entries.map((entry) {
                                  return Container(
                                    width: 8 * fontScale,
                                    height: 8 * fontScale,
                                    margin: EdgeInsets.symmetric(horizontal: 4 * fontScale),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentImageIndex == entry.key
                                          ? lightColorScheme.primary
                                          : lightColorScheme.onSurface.withOpacity(0.4),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                // Content Section
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 12 * fontScale, vertical: 8 * fontScale),
                    decoration: BoxDecoration(
                      color: lightColorScheme.surface,
                      borderRadius: BorderRadius.circular(16 * fontScale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10 * fontScale,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Post Info
                          Padding(
                            padding: EdgeInsets.all(16 * fontScale),
                            child: FutureBuilder<Post>(
                              future: _postFuture,
                              builder: (context, postSnapshot) {
                                if (postSnapshot.connectionState == ConnectionState.waiting ||
                                    !postSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                final post = postSnapshot.data!;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20 * fontScale,
                                      backgroundImage: NetworkImage(
                                        post.user.image != null
                                            ? '${Env.userImageBaseUrl}${post.user.image}'
                                            : 'https://ui-avatars.com/api/?name=${post.user.firstName}+${post.user.lastName}',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${post.user.firstName} ${post.user.lastName}',
                                            style: TextStyle(
                                              fontSize: 16 * fontScale,
                                              fontWeight: FontWeight.w600,
                                              color: lightColorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            post.description.isNotEmpty ? post.description : 'No description',
                                            style: TextStyle(
                                              fontSize: 14 * fontScale,
                                              color: lightColorScheme.onSurface.withOpacity(0.8),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _formatDateTime(post.date),
                                            style: TextStyle(
                                              fontSize: 12 * fontScale,
                                              color: lightColorScheme.onSurface.withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(duration: const Duration(milliseconds: 300));
                              },
                            ),
                          ),
                          Divider(height: 1, color: lightColorScheme.onSurface.withOpacity(0.2)),
                          // Comments Header
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16 * fontScale, vertical: 12 * fontScale),
                            child: Text(
                              'Comments',
                              style: TextStyle(
                                fontSize: 18 * fontScale,
                                fontWeight: FontWeight.w600,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                          // Comments List
                          RefreshIndicator(
                            onRefresh: _refreshData,
                            color: lightColorScheme.primary,
                            child: FutureBuilder<List<Comment>>(
                              future: _commentsFuture,
                              builder: (context, commentsSnapshot) {
                                if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator(color: lightColorScheme.primary));
                                }
                                if (commentsSnapshot.hasError || !commentsSnapshot.hasData) {
                                  return Center(
                                    child: Text(
                                      'Error loading comments: ${commentsSnapshot.error}',
                                      style: TextStyle(
                                        color: lightColorScheme.error,
                                        fontSize: 16 * fontScale,
                                      ),
                                    ),
                                  );
                                }
                                final comments = commentsSnapshot.data!;
                                if (comments.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 40 * fontScale,
                                          color: lightColorScheme.primary.withOpacity(0.6),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No comments yet',
                                          style: TextStyle(
                                            fontSize: 16 * fontScale,
                                            fontWeight: FontWeight.w500,
                                            color: lightColorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Be the first to comment!',
                                          style: TextStyle(
                                            fontSize: 14 * fontScale,
                                            color: lightColorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(duration: const Duration(milliseconds: 300));
                                }
                                return ListView.separated(
                                  padding: EdgeInsets.symmetric(horizontal: 16 * fontScale, vertical: 8 * fontScale),
                                  itemCount: comments.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    return Container(
                                      padding: EdgeInsets.all(12 * fontScale),
                                      decoration: BoxDecoration(
                                        color: lightColorScheme.surface,
                                        borderRadius: BorderRadius.circular(12 * fontScale),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 6 * fontScale,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18 * fontScale,
                                            backgroundImage: NetworkImage(
                                              comment.user.image != null
                                                  ? '${Env.userImageBaseUrl}${comment.user.image}'
                                                  : 'https://ui-avatars.com/api/?name=${comment.user.firstName}+${comment.user.lastName}',
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${comment.user.firstName} ${comment.user.lastName}',
                                                  style: TextStyle(
                                                    fontSize: 14 * fontScale,
                                                    fontWeight: FontWeight.w600,
                                                    color: lightColorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  comment.text,
                                                  style: TextStyle(
                                                    fontSize: 13 * fontScale,
                                                    color: lightColorScheme.onSurface.withOpacity(0.9),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatDateTime(comment.createdAt),
                                                  style: TextStyle(
                                                    fontSize: 11 * fontScale,
                                                    color: lightColorScheme.onSurface.withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn(
                                          duration: const Duration(milliseconds: 300),
                                          delay: Duration(milliseconds: index * 100),
                                        );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Comment Input (Fixed at Bottom)
                Container(
                  height: inputHeight,
                  padding: EdgeInsets.all(12 * fontScale),
                  decoration: BoxDecoration(
                    color: lightColorScheme.surface,
                    border: Border(
                      top: BorderSide(color: lightColorScheme.onSurface.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            filled: true,
                            fillColor: lightColorScheme.background.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16 * fontScale),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16 * fontScale, vertical: 12 * fontScale),
                            hintStyle: TextStyle(
                              color: lightColorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14 * fontScale,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            color: lightColorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16 * fontScale),
                          onTap: _isSendingComment ? null : _addComment,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16 * fontScale, vertical: 12 * fontScale),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  lightColorScheme.primary,
                                  lightColorScheme.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16 * fontScale),
                            ),
                            child: _isSendingComment
                                ? SizedBox(
                                    width: 20 * fontScale,
                                    height: 20 * fontScale,
                                    child: CircularProgressIndicator(
                                      color: lightColorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: lightColorScheme.onPrimary,
                                    size: 24 * fontScale,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}