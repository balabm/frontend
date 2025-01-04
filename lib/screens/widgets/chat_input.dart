import 'package:flutter/material.dart';
import 'package:formbot/screens/widgets/common.dart';

const Color kPrimaryColor = Color(0xFF009688); // Teal
const Color kPrimaryLightColor = Color(0xFFE0F2F1); // Teal 50
const Color kPrimaryDarkColor = Color(0xFF00796B); // Teal 700
const Color kBackgroundColor = Color(0xFFF5F5F5); // Grey 100
const Color kShadowColor = Color(0x1A000000); // Black with 10% opacity

class ChatInput extends StatefulWidget {
  final TextEditingController messageController;
  final bool inputEnabled;
  final bool isRecording;
  final DraggableScrollableController dragController;
  final Widget recordingIndicator;
  final Widget? microphoneButton;
  final Function() onSendPressed;
  final double slidingOffset;

  const ChatInput({
    Key? key,
    required this.messageController,
    required this.inputEnabled,
    required this.isRecording,
    required this.dragController,
    required this.recordingIndicator,
    this.microphoneButton,
    required this.onSendPressed,
    required this.slidingOffset,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: kShadowColor,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          widget.isRecording
              ? widget.recordingIndicator
              : Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: widget.messageController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      enabled: true,
                      onTap: () {
                        if (!widget.dragController.isAttached) return;

                        // Prevent multiple calls
                        if (widget.dragController.size < 1) {
                          widget.dragController.animateTo(
                            1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }

                        if (!widget.inputEnabled) {
                          Common.showErrorMessage(context,
                              "Please wait for the previous message to finish processing.");
                        }
                      },
                    ),
                  ),
                ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.messageController,
            builder: (context, value, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform:
                    Matrix4.translationValues(widget.slidingOffset, 0, 0),
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color:
                        value.text.isEmpty ? kPrimaryColor : kPrimaryDarkColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kShadowColor,
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: value.text.isEmpty
                      ? widget.microphoneButton
                      : IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: widget.onSendPressed,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
