import 'package:flutter/material.dart';

class MicrophoneButton extends StatelessWidget {
  final bool isLongPressing;
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final Function(LongPressEndDetails) onLongPressEnd;

  const MicrophoneButton({
    Key? key,
    required this.isLongPressing,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        margin: EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isLongPressing
              ? Color(0xFF0b3c66).withOpacity(0.7)
              : Color(0xFF0b3c66),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
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
