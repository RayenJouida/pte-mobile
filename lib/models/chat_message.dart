import 'package:hive/hive.dart';

part 'chat_message.g.dart'; // DO NOT rename this line

@HiveType(typeId: 1)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final bool isUser;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final DateTime date;

  ChatMessage({required this.isUser, required this.message, required this.date});
}
