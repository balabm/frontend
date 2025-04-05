import 'package:flutter/material.dart';
import 'chat_bubble.dart';

class ChatSection extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> chatMessages;
  final bool isThinking;
  final String userName;
  final Function(String) onPlayAudio;
  //final Function(int, bool) onFeedback; // Add onFeedback parameter
final Function(int, bool, String?, String?) onFeedback; // index, isHelpful, category, feedbackText

  

  const ChatSection({
    Key? key,
    required this.scrollController,
    required this.chatMessages,
    required this.isThinking,
    required this.userName,
    required this.onPlayAudio,
    required this.onFeedback, // Initialize onFeedback

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
       padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
      itemCount: chatMessages.length + (isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == chatMessages.length) {
          return  ChatBubble(
            message: '...',
            isUser: false,
            isThinking: true,
            timestamp: DateTime.now(),
            
            //timestamp: timestamp,
          );
        }
        
        final message = chatMessages[index];
        final isUser = message['sender'] == 'user';
        final isLLMResponse = message['isLLMResponse'] ?? false;

        final messageContent = message['message'] ?? message['content'] ?? message['asrResponse'] ?? '';
        final isAudioMessage = message['isAudioMessage'] == true || message['contentType'] == 'audio';
        final audioPath = message['audioPath'];
        //final timestamp = message['timestamp'] ?? '';
        final timestampString = message['timestamp'] ?? '';
DateTime? timestamp;
try {
  timestamp = DateTime.parse(timestampString).toLocal();
} catch (e) {
  print('Invalid timestamp format: $timestampString');
  timestamp = DateTime.now(); // Fallback to current time if parsing fails
} // Use a default timestamp if parsing fails
        if (isAudioMessage) {

           return ChatBubble(
            message: message['asrResponse'] ?? 'Voice message',
          asrResponse: message['asrResponse'],
          isUser: isUser,
          isThinking: false,
          isAudioMessage: isAudioMessage,
          audioPath: audioPath,
          //timestamp: timestamp,
 timestamp: timestamp,          
 isLLMResponse: isLLMResponse, // Pass the isLLMResponse property
          
          onPlayAudio: isAudioMessage && audioPath != null 
            ? () => onPlayAudio(audioPath)
            : null,
        );
        }
        print('Rendering message: ${message['message']}');
        print('isLLMResponse: $isLLMResponse');
        return ChatBubble(
          
          message: isAudioMessage 
              ? 'Voice message'
              : messageContent.toString(),
          isUser: isUser,
          isThinking: false,
          isAudioMessage: isAudioMessage,
          audioPath: audioPath,
          timestamp: timestamp,
          //timestamp: DateTime.now(),
          //isLLMResponse: isUser ? false : true,  // All non-user messages are LLM responses
          isLLMResponse: message['isLLMResponse'] ?? (message['feedback'] != null),
          //isLLMResponse: message['isLLMResponse'] ?? false, // Ensure proper restoration
          //isLLMResponse: isLLMResponse, // Pass the isLLMResponse property
          // Add these properties to pass restored feedback
          // Improved feedback data extraction
  existingFeedback: message['feedback'] ?? null, // Will be 'thumbs_up' or 'thumbs_down'
  existingFeedbackCategory: message['feedbackCategory'] ?? null,
  existingFeedbackText: message['feedbackText'] ?? null,
         
                  onPlayAudio: isAudioMessage && audioPath != null 
            ? () => onPlayAudio(audioPath)
            : null,
  //          onFeedback: (bool isHelpful) {
  //   onFeedback(index, isHelpful); // Pass feedback to parent widget
  // },
 // In the ChatBubble instantiation inside ChatSection
 
onFeedback: (bool isHelpful, String? category, String? feedbackText) {
  print('Feedback sent to parent: $isHelpful, $category, $feedbackText');
  onFeedback(index, isHelpful, category, feedbackText);
},
//chat restore 

        );
      },
    );
  }
}
