import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:pte_mobile/models/comment.dart';
import 'package:pte_mobile/models/like.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/config/env.dart';
import '../models/post.dart';
import '../models/activity.dart'; // Add this import for the new Activity model
import 'package:path/path.dart';

class PostService {
  final String baseUrl = Env.apiUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    debugPrint('Retrieved token: $token');
    return token;
  }

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
      throw Exception('User ID not found. Please log in first.');
    }
    return userId;
  }

  // Create a new post
  Future<void> createPost(String description, List<File> images) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final userId = await _getUserId();
      final uri = Uri.parse('$baseUrl/post/createPost');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['description'] = description;
      request.fields['user'] = userId;

      debugPrint('Request Fields: ${request.fields}');

      for (var image in images) {
        if (!await image.exists()) {
          debugPrint('Image file does not exist: ${image.path}');
          continue;
        }

        final fileStream = http.ByteStream(image.openRead());
        final length = await image.length();
        final mimeType = lookupMimeType(image.path) ?? 'application/octet-stream';
        final multipartFile = http.MultipartFile(
          'images',
          fileStream,
          length,
          filename: basename(image.path),
          contentType: MediaType.parse(mimeType),
        );

        request.files.add(multipartFile);
        debugPrint('Added image: ${image.path} (${length / 1024} KB)');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode != 201) {
        throw Exception('Failed to create post: $responseBody');
      }

      debugPrint('Post created successfully!');
    } catch (e) {
      debugPrint('Error in createPost: $e');
      rethrow;
    }
  }

  Future<List<Post>> getAllApprovedPosts() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getAllApprovedPosts');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is List) {
          decoded.forEach((element) {
            debugPrint("Element type: ${element.runtimeType}");
          });

          return decoded.map<Post>((dynamic post) {
            if (post is Map<String, dynamic>) {
              return Post.fromJson(post);
            } else {
              throw Exception('Invalid post data: expected a Map but got ${post.runtimeType}');
            }
          }).toList();
        } else {
          throw Exception("Expected a List but got ${decoded.runtimeType}");
        }
      } else {
        throw Exception('Failed to fetch approved posts');
      }
    } catch (e) {
      debugPrint('Error in getAllApprovedPosts: $e');
      rethrow;
    }
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getAllPosts');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch all posts');
      }
    } catch (e) {
      debugPrint('Error in getAllPosts: $e');
      rethrow;
    }
  }

  Future<List<Post>> getApprovedPosts(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getApprovedPosts/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch approved posts for user');
      }
    } catch (e) {
      debugPrint('Error in getApprovedPosts: $e');
      rethrow;
    }
  }

  Future<List<Post>> getDeclinedPosts(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getDeclinedPosts/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch declined posts for user');
      }
    } catch (e) {
      debugPrint('Error in getDeclinedPosts: $e');
      rethrow;
    }
  }

  Future<List<Post>> getPendingPosts(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getPendingPosts/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch pending posts for user');
      }
    } catch (e) {
      debugPrint('Error in getPendingPosts: $e');
      rethrow;
    }
  }

  Future<Post> getPostById(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getPostById/$postId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return Post.fromJson(data);
      } else {
        throw Exception('Failed to fetch post by ID');
      }
    } catch (e) {
      debugPrint('Error in getPostById: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/deletePost/$postId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete post');
      }
    } catch (e) {
      debugPrint('Error in deletePost: $e');
      rethrow;
    }
  }

  Future<List<Post>> getUserLikedPosts(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found. Please log in first.');

      final uri = Uri.parse('$baseUrl/post/likedByUser/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('GetUserLikedPosts Response Status: ${response.statusCode}');
      debugPrint('GetUserLikedPosts Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch liked posts: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getUserLikedPosts: $e');
      try {
        final allPosts = await getAllApprovedPosts();
        final likedPosts = allPosts.where((post) => post.likes.any((like) => like.user == userId)).toList();
        debugPrint('Fallback - Liked Posts from allPosts: ${likedPosts.length}');
        return likedPosts;
      } catch (fallbackError) {
        debugPrint('Fallback failed: $fallbackError');
        rethrow;
      }
    }
  }

  Future<void> updatePost(String postId, String description, List<File> images) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/updatePost/$postId');
      final request = http.MultipartRequest('PUT', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['description'] = description;

      for (var image in images) {
        if (!await image.exists()) {
          debugPrint('Image file does not exist: ${image.path}');
          continue;
        }

        final fileStream = http.ByteStream(image.openRead());
        final length = await image.length();
        final mimeType = lookupMimeType(image.path) ?? 'application/octet-stream';
        final multipartFile = http.MultipartFile(
          'images',
          fileStream,
          length,
          filename: basename(image.path),
          contentType: MediaType.parse(mimeType),
        );

        request.files.add(multipartFile);
        debugPrint('Added image: ${image.path} (${length / 1024} KB)');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: $responseBody');

      if (response.statusCode != 200) {
        throw Exception('Failed to update post: $responseBody');
      }

      debugPrint('Post updated successfully!');
    } catch (e) {
      debugPrint('Error in updatePost: $e');
      rethrow;
    }
  }

  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getUserPosts/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch posts for user');
      }
    } catch (e) {
      debugPrint('Error in getUserPosts: $e');
      rethrow;
    }
  }

  Future<void> managerAcceptPost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/managerAccept/$postId');
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to accept post');
      }
    } catch (e) {
      debugPrint('Error in managerAcceptPost: $e');
      rethrow;
    }
  }

  Future<void> managerDeclinePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/managerDecline/$postId');
      final response = await http.put(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to decline post');
      }
    } catch (e) {
      debugPrint('Error in managerDeclinePost: $e');
      rethrow;
    }
  }

  Future<void> savePost(String postId, String userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final uri = Uri.parse('$baseUrl/post/savePost/$postId');
      debugPrint('Making request to: ${uri.toString()}');

      final response = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user': userId}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SavePost error: $e');
      rethrow;
    }
  }

  Future<List<Post>> getUserSavedPosts(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found');

      final uri = Uri.parse('$baseUrl/post/getUserSaved/$userId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      }
      throw Exception('Failed with status ${response.statusCode}');
    } catch (e) {
      debugPrint('Get saved posts error: $e');
      rethrow;
    }
  }

  Future<List<Post>> getAllPendingPosts() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getAllPendingPosts');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch pending posts');
      }
    } catch (e) {
      debugPrint('Error in getAllPendingPosts: $e');
      rethrow;
    }
  }

  Future<Map<String, int>> getPostInteractionCount(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getPostInteractionCount/$postId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'likesCount': data['likesCount'],
          'commentsCount': data['commentsCount'],
        };
      } else {
        throw Exception('Failed to fetch post interaction count');
      }
    } catch (e) {
      debugPrint('Error in getPostInteractionCount: $e');
      rethrow;
    }
  }

  Future<List<Post>> getAllPostsWithStats() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/post/getAllPostsWithStats');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((post) => Post.fromJson(post)).toList();
      } else {
        throw Exception('Failed to fetch posts with stats');
      }
    } catch (e) {
      debugPrint('Error in getAllPostsWithStats: $e');
      rethrow;
    }
  }

  Future<List<Comment>> getPostComments(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/comment/$postId/getPostComments');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("Comments response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((comment) => Comment.fromJson(comment)).toList();
      } else {
        throw Exception('Failed to fetch comments: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getPostComments: $e');
      rethrow;
    }
  }

  Future<Comment> addComment(String postId, String text) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final userId = await _getUserId();
      final uri = Uri.parse('$baseUrl/comment/$postId/addComment');

      debugPrint("Adding comment to post: $postId");
      debugPrint("Comment text: $text");

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'user': userId,
          'post': postId,
        }),
      );

      debugPrint("Add comment response: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 201) {
        return Comment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in addComment: $e');
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/comment/$postId/$commentId');
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in deleteComment: $e');
      rethrow;
    }
  }

  Future<Comment> updateComment(String commentId, String newText) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/comment/$commentId');
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'text': newText}),
      );

      if (response.statusCode == 200) {
        return Comment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update comment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in updateComment: $e');
      rethrow;
    }
  }

  Future<Post> likePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found. Please log in first.');

      final userId = await _getUserId();
      final uri = Uri.parse('$baseUrl/like/$postId');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user': userId}),
      );

      debugPrint('LikePost Response Status: ${response.statusCode}');
      debugPrint('LikePost Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Post.fromJson(data);
      } else {
        throw Exception('Failed to like/unlike post: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in likePost: $e');
      rethrow;
    }
  }

  Future<Like> getLike(String likeId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found. Please log in first.');

      final uri = Uri.parse('$baseUrl/like/$likeId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('GetLike Response Status: ${response.statusCode}');
      debugPrint('GetLike Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Like.fromJson(data);
      } else {
        throw Exception('Failed to fetch like: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getLike: $e');
      rethrow;
    }
  }

  Future<Like> getLikers(String likeId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No token found. Please log in first.');

      final uri = Uri.parse('$baseUrl/like/likers/$likeId');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint('GetLikers Response Status: ${response.statusCode}');
      debugPrint('GetLikers Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Like.fromJson(data);
      } else {
        throw Exception('Failed to fetch likers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in getLikers: $e');
      rethrow;
    }
  }

  // Fetch user activities (posts, likes, comments)
  Future<List<Activity>> fetchUserActivities(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No token found. Please log in first.');
      }

      final uri = Uri.parse('$baseUrl/activities/$userId');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('FetchUserActivities Response Status: ${response.statusCode}');
      debugPrint('FetchUserActivities Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final activities = data.map((activity) => Activity.fromJson(activity)).toList();
        debugPrint('Fetched activities count: ${activities.length}');
        return activities;
      } else {
        throw Exception('Failed to fetch user activities: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in fetchUserActivities: $e');
      rethrow;
    }
  }
}