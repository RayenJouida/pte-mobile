// services/like_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pte_mobile/config/env.dart';
import '../models/like.dart';

class LikeService {
  final String token;

  LikeService(this.token);

  Future<Like> getLikeById(String likeId) async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/like/$likeId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Like.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load like');
    }
  }

  Future<List<Like>> getLikers(String postId) async {
    final response = await http.get(
      Uri.parse('${Env.apiUrl}/like/getLikers/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Like.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load likers');
    }
  }
}