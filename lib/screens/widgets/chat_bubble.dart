import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'audio_player_widget.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isThinking;
  final bool isAudioMessage;
  final String? audioPath;
  final String? asrResponse;
  final String timestamp;
  final VoidCallback? onPlayAudio;

   ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isThinking = false,
    this.isAudioMessage = false,
    this.audioPath,
    this.asrResponse,
    required this.timestamp,
    this.onPlayAudio,
  }) : super(key: key);

  String _getCurrentTimestamp() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
                if (!isUser) ...[
                 Container(
                  padding: EdgeInsets.only(right: 10),
                   child: ClipRRect(
                    child: CircleAvatar(
                     child: Image.asset(
                          'assets/5.png', // Replace with your asset image path
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                   ),
                   ),
                 )
              
              ],

              // if (!isUser) ...[
              //   CircleAvatar(
              //     radius: 16,
              //     backgroundColor: Colors.grey[300],
              //     child: Icon(Icons.person, color: Colors.grey[700]),
              //   ),
              //   const SizedBox(width: 8),
              // ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.teal[100] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAudioMessage && audioPath != null) ...[
                        GestureDetector(
                          onTap: onPlayAudio,
                          child: AudioPlayerWidget(audioPath: audioPath!),
                        ),
                        if (asrResponse != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            asrResponse!,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          message,
                          style: TextStyle(
                            color: isUser ? Colors.teal[900] : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                // CircleAvatar(
                //   radius: 16,
                //   backgroundColor: Colors.teal[200],
                //   child: Icon(Icons.person, color: Colors.teal[700]),
                // ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getCurrentTimestamp(),
            style: TextStyle(
              color: const Color.fromRGBO(117, 117, 117, 1),
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}
