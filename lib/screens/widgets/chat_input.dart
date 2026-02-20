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
    //final FocusNode? focusNode; // Add this line
  final FocusNode focusNode; // Declare focusNode here


  

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
    required this.focusNode, // And require it here
    
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Text Input Field
            widget.isRecording
                ? Expanded(child: widget.recordingIndicator)
                : Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white, // White background
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: widget.messageController,
                        focusNode: widget.focusNode,
                        minLines: 1,
                        maxLines: 5,
                        cursorColor: kPrimaryColor,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.multiline,
                        scrollPhysics: const BouncingScrollPhysics(),
                        onTap: () {
                          if (!widget.dragController.isAttached) return;

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
            
            const SizedBox(width: 8),
            
            // Camera Icon
            IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: kPrimaryColor,
                size: 26,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            
            // Send Button / Microphone
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.messageController,
              builder: (context, value, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(widget.slidingOffset, 0, 0),
                  child: value.text.isEmpty
                      ? widget.microphoneButton ?? const SizedBox.shrink()
                      : Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: widget.onSendPressed,
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
