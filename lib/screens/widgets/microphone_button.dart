// import 'package:flutter/material.dart';

// class MicrophoneButton extends StatelessWidget {
//   final bool isLongPressing;
//   final Function(LongPressStartDetails)? onLongPressStart;
//   final Function(LongPressMoveUpdateDetails)? onLongPressMoveUpdate;
//   final Function(LongPressEndDetails)? onLongPressEnd;
//   final bool enabled;

//   const MicrophoneButton({
//     super.key,
//     required this.isLongPressing,
//     this.onLongPressStart,
//     this.onLongPressMoveUpdate,
//     this.onLongPressEnd,
//     this.enabled = true,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onLongPressStart: enabled ? onLongPressStart : null,
//       onLongPressMoveUpdate: enabled ? onLongPressMoveUpdate : null,
//       onLongPressEnd: enabled ? onLongPressEnd : null,
//       child: Container(
//         margin: const EdgeInsets.only(left: 8),
//         decoration: BoxDecoration(
//           color: !enabled 
//             ? Colors.grey.withOpacity(0.5) 
//             : (isLongPressing ? Colors.teal.withOpacity(0.7) : Colors.teal),
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               spreadRadius: 1,
//               blurRadius: 3,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: IconButton(
//           icon: Icon(
//             Icons.mic,
//             color: enabled ? Colors.white : Colors.white54,
//           ),
//           onPressed: null, // Disable tap, we're using long press
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class MicrophoneButton extends StatefulWidget {
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
  State<MicrophoneButton> createState() => _MicrophoneButtonState();
}

class _MicrophoneButtonState extends State<MicrophoneButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _handleAnimation();
  }

  void _handleAnimation() {
    if (widget.isLongPressing) {
      _animationController.repeat(reverse: true);
    } else {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void didUpdateWidget(MicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLongPressing != oldWidget.isLongPressing) {
      _handleAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.enabled ? widget.onLongPressStart : null,
      onLongPressMoveUpdate: widget.enabled ? widget.onLongPressMoveUpdate : null,
      onLongPressEnd: widget.enabled ? widget.onLongPressEnd : null,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: widget.isLongPressing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: !widget.enabled
                      ? Colors.grey.withOpacity(0.5)
                      : (widget.isLongPressing
                          ? Colors.teal.withOpacity(0.7)
                          : Colors.teal),
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
                child: Transform.scale(
                  scale: widget.isLongPressing ? _scaleAnimation.value : 1.0,
                  child: IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: widget.enabled ? Colors.white : Colors.white54,
                    ),
                    onPressed: null, // Disable tap, we're using long press
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
