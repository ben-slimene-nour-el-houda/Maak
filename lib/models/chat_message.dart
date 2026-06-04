import 'chat_action.dart';
import 'procedure.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<ChatAction> actions;
  final Procedure? procedure;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.actions = const [],
    this.procedure,
  });
}
