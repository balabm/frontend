import 'package:flutter/material.dart';
import 'audio_player_widget.dart';
import 'fade_in_widget.dart';
import 'message_animation_widget.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isThinking;
  final bool isAudioMessage;
  final String? audioPath;
  final VoidCallback? onPlayAudio;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isThinking = false,
    this.isAudioMessage = false,
    this.audioPath,
    this.onPlayAudio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAudioMessage && onPlayAudio != null) ...[
              InkWell(
                onTap: onPlayAudio,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, 
                      color: Colors.teal[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(message,
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.teal[900] : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
