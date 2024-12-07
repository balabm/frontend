import 'package:flutter/material.dart';

class MicrophoneButton extends StatelessWidget {
  final bool isLongPressing;
  final Function(LongPressStartDetails)? onLongPressStart;
  final Function(LongPressMoveUpdateDetails)? onLongPressMoveUpdate;
  final Function(LongPressEndDetails)? onLongPressEnd;
  final bool enabled;

  const MicrophoneButton({
    super.key,
    required this.isLongPressing,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: enabled ? onLongPressStart : null,
      onLongPressMoveUpdate: enabled ? onLongPressMoveUpdate : null,
      onLongPressEnd: enabled ? onLongPressEnd : null,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: !enabled 
            ? Colors.grey.withOpacity(0.5) 
            : (isLongPressing ? Colors.teal.withOpacity(0.7) : Colors.teal),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.mic,
            color: enabled ? Colors.white : Colors.white54,
          ),
          onPressed: null, // Disable tap, we're using long press
        ),
      ),
    );
  }
}