import 'package:flutter/material.dart';
import 'package:formbot/screens/widgets/common.dart';

const Color _kPrimaryColor = Color(0xFF009688);

class ChatInput extends StatefulWidget {
  final TextEditingController messageController;
  final bool inputEnabled;
  final bool isRecording;
  final DraggableScrollableController dragController;
  final Widget recordingIndicator;
  final Widget? microphoneButton;
  final Function() onSendPressed;
  final double slidingOffset;
  final FocusNode focusNode;

  const ChatInput({
    super.key,
    required this.messageController,
    required this.inputEnabled,
    required this.isRecording,
    required this.dragController,
    required this.recordingIndicator,
    this.microphoneButton,
    required this.onSendPressed,
    required this.slidingOffset,
    required this.focusNode,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera button
            IconButton(
              icon: Icon(Icons.camera_alt, color: _kPrimaryColor, size: 26),
              onPressed: () => Navigator.pushNamed(context, '/camera'),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),

            // Input field
            Expanded(
              child: widget.isRecording
                  ? widget.recordingIndicator
                  : Container(
                      constraints: const BoxConstraints(
                        minHeight: 44,
                        maxHeight: 120,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: widget.messageController,
                        focusNode: widget.focusNode,
                        minLines: 1,
                        maxLines: 5,
                        cursorColor: _kPrimaryColor,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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

            // Send / Mic button
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.messageController,
              builder: (context, value, child) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(widget.slidingOffset, 0, 0),
                  child: value.text.isEmpty
                      ? widget.microphoneButton ?? const SizedBox.shrink()
                      : Container(
                          decoration: const BoxDecoration(
                            color: _kPrimaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: widget.onSendPressed,
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
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
