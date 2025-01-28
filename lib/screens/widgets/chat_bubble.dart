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

  const ChatBubble({
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey[700]),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        AudioPlayerWidget(audioPath: audioPath!),
                        if (asrResponse != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            asrResponse!,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.teal[200],
                  child: Icon(Icons.person, color: Colors.teal[700]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _getCurrentTimestamp(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
