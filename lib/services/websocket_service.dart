import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert'; // For JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pte_mobile/config/env.dart'; // Import the environment file

class WebSocketService {
  late WebSocketChannel _channel;
  final String _currentUserId;
  final Function(Map<String, dynamic>) onMessageReceived; // Callback for new messages

  WebSocketService(this._currentUserId, {required this.onMessageReceived});

  // Connect to the WebSocket server and register the user
  void connect() {
    _channel = IOWebSocketChannel.connect('${Env.wsUrl}/ws'); // Use WebSocket URL from Env

    // Register the user with the server
    _channel.sink.add(json.encode({
      'type': 'register',
      'userId': _currentUserId,
    }));

    // Listen for incoming messages
    _channel.stream.listen(
      (message) {
        final data = json.decode(message);
        _handleIncomingMessage(data);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  // Handle incoming messages
  void _handleIncomingMessage(Map<String, dynamic> data) {
    if (data['type'] == 'message') {
      // Handle a received message
      final String text = data['text'];
      final String senderId = data['senderId'];
      final String timestamp = data['timestamp'];

      print('Received message from $senderId: $text');

      // Notify the UI with the new message
      onMessageReceived({
        'text': text,
        'senderId': senderId,
        'timestamp': timestamp,
        'isMe': false, // Messages from others
      });
    } else if (data['type'] == 'error') {
      // Handle errors from the server
      print('WebSocket error: ${data['message']}');
    }
  }

  // Send a message
  void sendMessage(String recipientId, String text) {
    final message = json.encode({
      'type': 'message',
      'senderId': _currentUserId,
      'recipientId': recipientId,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _channel.sink.add(message);
  }

  // Close the connection
  void disconnect() {
    _channel.sink.close();
  }
}