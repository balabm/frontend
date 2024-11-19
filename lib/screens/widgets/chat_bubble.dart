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
                child: const CircleAvatar(
                  backgroundColor: Colors.blueGrey ,
                  child: Text('AI',style: TextStyle(color: Colors.white,letterSpacing: 5,fontWeight: FontWeight.bold),),
                  radius: 24,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isUser 
                      ? [const Color.fromARGB(255, 157, 192, 222), const Color.fromARGB(255, 156, 193, 229)]
                      : [const Color(0xFFE8EAF6), const Color.fromARGB(255, 225, 227, 236)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                    bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
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
                    ] else if (message.isNotEmpty)
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
               const CircleAvatar(
                  backgroundColor: Color(0xFF0b3c66) ,
                  child: Icon(Icons.person,color: Colors.white,),
                  radius: 24,
                ),
            ],
          ],
        ),
      ),
    );
  }
}