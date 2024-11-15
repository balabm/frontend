// lib/screens/widgets/chat_bubble.dart

import 'package:flutter/material.dart';
import 'fade_in_widget.dart';
import 'audio_player_widget.dart'; // Make sure you have this widget in a separate file

class ChatBubble extends StatelessWidget {
  final String sender;
  final String message;
  final String? audioPath;
  final Function(String)? onPlayAudio;
  final String avatar;
  final bool isAudioMessage;

  const ChatBubble({
    Key? key,
    required this.sender,
    required this.message,
    this.audioPath,
    this.onPlayAudio,
    required this.avatar,
    this.isAudioMessage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isUser = sender == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: 24,
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isUser ? Color.fromARGB(255, 202, 225, 238) : Color(0xFFE0E0E0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: isUser ? Radius.circular(16) : Radius.circular(0),
                  bottomRight: isUser ? Radius.circular(0) : Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (audioPath != null) ...[
                    AudioPlayerWidget(
                      audioPath: audioPath!,
                      onPlayAudio: onPlayAudio,
                    ),
                    if (isAudioMessage)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Audio message',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              TextSpan(
                                text: ' • ${message.split('• ').last}',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else if (message.isNotEmpty)
                    FadeInWidget(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: 24,
            ),
          ],
        ],
      ),
    );
  }
}
