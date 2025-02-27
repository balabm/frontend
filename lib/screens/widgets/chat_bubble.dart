import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'audio_player_widget.dart';
import 'package:flutter/services.dart'; // Required for clipboard functionality

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final bool isThinking;
  final bool isAudioMessage;
  final String? audioPath;
  final String? asrResponse;
  final DateTime timestamp;
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

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final timeString = _formatTimestamp(timestamp); // Format the timestamp
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                Container(
                  padding: EdgeInsets.only(right: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CircleAvatar(
                      backgroundImage: AssetImage('assets/5.png'),
                      radius: 16,
                    ),
                  ),
                )
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Color.fromRGBO(0, 150, 136, 1.0)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                          bottomLeft:
                              isUser ? Radius.circular(20) : Radius.zero,
                          bottomRight:
                              isUser ? Radius.zero : Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAudioMessage && audioPath != null) ...[
                            // Group AudioPlayer and ASR output together
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: onPlayAudio,
                                  child: AudioPlayerWidget(
                                      audioPath: audioPath!),
                                ),
                                if (asrResponse != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    constraints:
                                        BoxConstraints(maxWidth: 150),
                                    child: Text(
                                      asrResponse!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ] else ...[
                            // Use SelectableText for message text to allow copying
                            GestureDetector(
                              onLongPress: () {
                                Clipboard.setData(
                                    ClipboardData(text: message));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Text copied to clipboard"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: SelectableText(
                                message,
                                cursorColor: Colors.teal,
                                style: TextStyle(
                                  color: isUser
                                      ? Colors.white
                                      : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeString,
                      style: TextStyle(
                        color: Color.fromRGBO(117, 117, 117, 1),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'audio_player_widget.dart';

// class ChatBubble extends StatelessWidget {
//   final String message;
//   final bool isUser;
//   final bool isThinking;
//   final bool isAudioMessage;
//   final String? audioPath;
//   final String? asrResponse;
//   final DateTime timestamp;
//   final VoidCallback? onPlayAudio;

//   ChatBubble({
//     Key? key,
//     required this.message,
//     required this.isUser,
//     this.isThinking = false,
//     this.isAudioMessage = false,
//     this.audioPath,
//     this.asrResponse,
//    required this.timestamp, 
//     this.onPlayAudio,
//   }) : super(key: key);

//   String _formatTimestamp(DateTime timestamp) {
//     return DateFormat('hh:mm a').format(timestamp);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final timeString = _formatTimestamp(timestamp); // Format the timestamp
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Column(
//         crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               if (!isUser) ...[
//                 Container(
//                   padding: EdgeInsets.only(right: 10),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: CircleAvatar(
//                       backgroundImage: AssetImage('assets/5.png'),
//                       radius: 16,
//                     ),
//                   ),
//                 )
//               ],
//               Flexible(
//                 child: Column(
//                   crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isUser ? Color.fromRGBO(0, 150, 136, 1.0) : Colors.grey[200],
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(20),
//                           topRight: Radius.circular(20),
//                           bottomLeft: isUser ? Radius.circular(20) : Radius.zero,
//                           bottomRight: isUser ? Radius.zero : Radius.circular(20),
//                         ),
//                       ),
//                       child: Column(
//   crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     if (isAudioMessage && audioPath != null) ...[
//       // Group AudioPlayer and ASR output together
//       Column(
//         crossAxisAlignment: CrossAxisAlignment.start, // Align start point
//         children: [
//           GestureDetector(
//             onTap: onPlayAudio,
//             child: AudioPlayerWidget(audioPath: audioPath!),
//           ),
//           if (asrResponse != null) ...[
//             const SizedBox(height: 4), // Slight spacing for better UI
//             Container(
//               constraints: BoxConstraints(maxWidth: 150), // Limit width for better readability
//               child: Text(
//                 asrResponse!,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 13,
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     ] else ...[
//       Text(
//         message,
//         style: TextStyle(
//           color: isUser ? Colors.white : Colors.black87,
//           fontSize: 13,
//         ),
//       ),
//     ],
    
//   ],
// ),

//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       timeString, 
                      
//                       style: TextStyle(
//                         color: Color.fromRGBO(117, 117, 117, 1),
//                         fontSize: 10,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
