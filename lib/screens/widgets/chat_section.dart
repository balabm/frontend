import 'package:flutter/material.dart';
import 'package:formbot/screens/widgets/chat_bubble.dart';

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
    if (chatMessages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: chatMessages.length + (isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatMessages.length) {
          return const ChatBubble(
            message: '...',
            isUser: false,
            isThinking: true,
          );
        }

        final message = chatMessages[index];
        final isUser = message['sender'] == 'user';
        final messageContent = message['message'] ?? message['content'] ?? '';
        final isAudioMessage = message['isAudioMessage'] == true || message['contentType'] == 'audio';
        final audioPath = message['audioPath'];

        return ChatBubble(
          message: isAudioMessage 
              ? 'Voice message'
              : messageContent.toString(),
          isUser: isUser,
          isThinking: false,
          isAudioMessage: isAudioMessage,
          audioPath: audioPath,
          onPlayAudio: isAudioMessage && audioPath != null 
            ? () => onPlayAudio(audioPath)
            : null,
        );
      },
    );
  }
}
