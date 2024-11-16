import 'package:flutter/material.dart';
import 'fade_in_widget.dart';
import 'audio_player_widget.dart';
import 'message_animation_widget.dart'; // Add this import

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
      child: MessageAnimationWidget(  // Wrap the Row with MessageAnimationWidget
        isUser: isUser,
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                decoration: BoxDecoration(
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
                  backgroundImage: AssetImage(avatar),
                  radius: 20,
                ),
              ),
              SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser 
                      ? [Color.fromARGB(255, 157, 192, 222), Color.fromARGB(255, 156, 193, 229)]
                      : [Color(0xFFE8EAF6), Color.fromARGB(255, 225, 227, 236)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isUser ? Radius.circular(20) : Radius.circular(0),
                    bottomRight: isUser ? Radius.circular(0) : Radius.circular(20),
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
      ),
    );
  }
}