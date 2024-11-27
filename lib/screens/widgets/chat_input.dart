import 'package:flutter/material.dart';
import 'package:formbot/screens/widgets/common.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController messageController;
  final bool inputEnabled;
  final bool isRecording;
  final DraggableScrollableController dragController;
  final Widget recordingIndicator;
  final Widget microphoneButton;
  final Function() onSendPressed;
  final double slidingOffset;

  const ChatInput({
    Key? key,
    required this.messageController,
    required this.inputEnabled,
    required this.isRecording,
    required this.dragController,
    required this.recordingIndicator,
    required this.microphoneButton,
    required this.onSendPressed,
    required this.slidingOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          isRecording
              ? recordingIndicator
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white54,
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      enabled: true,
                      onTap: () {
                        dragController.animateTo(1,
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeIn);
                        if (!inputEnabled) {
                          Common.showErrorMessage(context,
                              "Please wait for the previous message to finish processing.");
                        }
                      },
                      onChanged: (text) {
                        if (!inputEnabled) {
                          Common.showErrorMessage(context,
                              "Please wait for the previous message to finish processing.");
                          messageController.clear();
                        }
                      },
                    ),
                  ),
                ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(slidingOffset, 0, 0),
            child: messageController.text.isEmpty
                ? microphoneButton
                : IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF0b3c66)),
                    onPressed: onSendPressed,
                  ),
          ),
        ],
      ),
    );
  }
}
