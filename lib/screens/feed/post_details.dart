import 'package:flutter/material.dart';
import 'package:pte_mobile/models/post.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:pte_mobile/services/post_service.dart';
import '../../theme/theme.dart';
import '../../config/env.dart'; 

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

  @override
  void initState() {
    super.initState();
    _postFuture = _postService.getPostById(widget.postId);
    _commentsFuture = _postService.getPostComments(widget.postId);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightColorScheme.surface,
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 120,
        leading: Center(
          child: Image.asset('assets/images/prologic.png', width: 180, height: 50, fit: BoxFit.contain),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: lightColorScheme.primary, size: 26),
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
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: lightColorScheme.primary));
          }
          if (postSnapshot.hasError || !postSnapshot.hasData) {
            return Center(
              child: Text(
                'Error loading post: ${postSnapshot.error}',
                style: TextStyle(color: lightColorScheme.error),
              ),
            );
          }

          final post = postSnapshot.data!;

          return Column(
            children: [
              // Image Section
              SizedBox(
                height: 400, // Larger image height
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 3,
                  child: post.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: post.images.length,
                          itemBuilder: (_, index) => Image.network(
                            '${Env.imageBaseUrl}${post.images[index]}',
                            fit: BoxFit.cover,
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
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                        ),
                ),
              ),
              // Content Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: lightColorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 22,
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
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.description.isNotEmpty ? post.description : 'No description',
                                    style: TextStyle(fontSize: 14, color: lightColorScheme.onSurface.withOpacity(0.8)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(post.date),
                                    style: TextStyle(fontSize: 12, color: lightColorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      // Comments Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Comments',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: lightColorScheme.primary),
                        ),
                      ),
                      // Comments List
                      Expanded(
                        child: RefreshIndicator(
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
                                    style: TextStyle(color: lightColorScheme.error),
                                  ),
                                );
                              }
                              final comments = commentsSnapshot.data!;
                              if (comments.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline,
                                          size: 40, color: lightColorScheme.primary.withOpacity(0.6)),
                                      const SizedBox(height: 8),
                                      const Text('No comments yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                      Text('Be the first!', style: TextStyle(color: lightColorScheme.onSurface.withOpacity(0.6))),
                                    ],
                                  ),
                                );
                              }
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: comments.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  return Row(
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
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${comment.user.firstName} ${comment.user.lastName}',
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                            ),
                                            Text(
                                              comment.text,
                                              style: TextStyle(fontSize: 13, color: lightColorScheme.onSurface.withOpacity(0.9)),
                                            ),
                                            Text(
                                              _formatDateTime(comment.createdAt),
                                              style: TextStyle(fontSize: 11, color: lightColorScheme.onSurface.withOpacity(0.6)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      // Comment Input
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: lightColorScheme.surface,
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
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: _isSendingComment
                                  ? CircularProgressIndicator(color: lightColorScheme.primary)
                                  : Icon(Icons.send, color: lightColorScheme.primary),
                              onPressed: _addComment,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}