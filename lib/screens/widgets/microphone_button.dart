import 'package:flutter/material.dart';

class MicrophoneButton extends StatelessWidget {
  final bool isLongPressing;
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final Function(LongPressEndDetails) onLongPressEnd;

  const MicrophoneButton({
    super.key,
    required this.isLongPressing,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isLongPressing ? Colors.teal.withOpacity(0.7) : Colors.teal,
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
        child: const IconButton(
          icon: Icon(
            Icons.mic,
            color: Colors.white,
          ),
          onPressed: null, // Disable tap, we're using long press
        ),
      ),
    );
  }
}
