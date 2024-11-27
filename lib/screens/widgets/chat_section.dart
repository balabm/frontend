import 'package:flutter/material.dart';
import 'chat_bubble.dart';

class ChatSection extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> chatMessages;
  final bool isThinking;
  final String userName;
  final Function(String) onPlayAudio;

  const ChatSection({
    Key? key,
    required this.scrollController,
    required this.chatMessages,
    required this.isThinking,
    required this.userName,
    required this.onPlayAudio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: chatMessages.length + (isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (isThinking && index == chatMessages.length) {
          return ChatBubble(
            sender: 'assistant',
            message: 'Thinking...',
            avatar: 'assets/bot_avatar.png',
            userName: userName,
          );
        }
        final message = chatMessages[index];
        return ChatBubble(
          sender: message['sender'],
          message: message['message'],
          audioPath: message['audioPath'],
          onPlayAudio: onPlayAudio,
          avatar: message['sender'] == 'user'
              ? 'assets/user_avatar.png'
              : 'assets/bot_avatar.png',
          isAudioMessage: message['isAudioMessage'] ?? false,
          userName: userName.toUpperCase(),
        );
      },
    );
  }
}
