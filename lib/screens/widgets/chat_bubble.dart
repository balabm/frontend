import 'package:flutter/material.dart';
import 'audio_player_widget.dart';
import 'fade_in_widget.dart';
import 'message_animation_widget.dart';

class ChatBubble extends StatelessWidget {
  final String sender;
  final String message;
  final String? audioPath;
  final Function(String)? onPlayAudio;
  final String avatar;
  final bool isAudioMessage;
  final String? userName;

  const ChatBubble({
    super.key,
    required this.sender,
    required this.message,
    this.audioPath,
    this.onPlayAudio,
    required this.avatar,
    this.isAudioMessage = false,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    bool isUser = sender == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: MessageAnimationWidget(
        isUser: isUser,
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.teal.withOpacity(0.9),
                  radius: 24,
                  child: const Text(
                    'Form\nBot',
                    style: TextStyle(
                      color: Colors.white,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser
                        ? [
                            Colors.deepOrange.withOpacity(0.4),
                            Colors.deepOrange.withOpacity(0.4),
                            Colors.deepOrange.withOpacity(0.5),
                          ]
                        : [
                            Colors.teal.withOpacity(0.5),
                            Colors.teal.withOpacity(0.4),
                            Colors.teal.withOpacity(0.4)
                          ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isUser
                        ? const Radius.circular(20)
                        : const Radius.circular(0),
                    bottomRight: isUser
                        ? const Radius.circular(0)
                        : const Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
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
                                const TextSpan(
                                  text: 'Audio message',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: ' • ${message.split('• ').last}',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ] else if (message == "Typing...")
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI is thinking',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0b3c66),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (message.isNotEmpty)
                      FadeInWidget(
                        child: Text(
                          message,
                          style: const TextStyle(
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
              const SizedBox(width: 12),
              Column(
                children: [
                  CircleAvatar(

                    backgroundColor: Colors.deepOrange.withOpacity(0.9),
                    radius: 24,
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
