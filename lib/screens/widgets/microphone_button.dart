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
//             : (isLongPressing ? Color.fromRGBO(0, 150, 136, 1.0)

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
// import 'package:flutter/material.dart';

// class MicrophoneButton extends StatefulWidget {
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
//   State<MicrophoneButton> createState() => _MicrophoneButtonState();
// }

// class _MicrophoneButtonState extends State<MicrophoneButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   late Animation<double> _pulseAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );

//     _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeInOut,
//       ),
//     );

//     _handleAnimation();
//   }

//   void _handleAnimation() {
//     if (widget.isLongPressing) {
//       _animationController.repeat(reverse: true);
//     } else {
//       _animationController.stop();
//       _animationController.reset();
//     }
//   }

//   @override
//   void didUpdateWidget(MicrophoneButton oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.isLongPressing != oldWidget.isLongPressing) {
//       _handleAnimation();
//     }
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onLongPressStart: widget.enabled ? widget.onLongPressStart : null,
//       onLongPressMoveUpdate: widget.enabled ? widget.onLongPressMoveUpdate : null,
//       onLongPressEnd: widget.enabled ? widget.onLongPressEnd : null,
//       child: AnimatedBuilder(
//         animation: _animationController,
//         builder: (context, child) {
//           return Stack(
//             alignment: Alignment.center,
//             children: [
//               AnimatedOpacity(
//                 opacity: widget.isLongPressing ? 1.0 : 0.0,
//                 duration: const Duration(milliseconds: 300),
//                 child: Transform.scale(
//                   scale: _pulseAnimation.value,
//                   child: Container(
//                     width: 56,
//                     height: 56,
//                     decoration: BoxDecoration(
//                       color: Color.fromRGBO(0, 150, 136, 1.0)
// .withOpacity(0.2),
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ),
//               Container(
//                 margin: const EdgeInsets.only(left: 8),
//                 decoration: BoxDecoration(
//                   color: !widget.enabled
//                       ? Colors.grey.withOpacity(0.5)
//                       : (widget.isLongPressing
//                           ? Color.fromRGBO(0, 150, 136, 1.0)
// .withOpacity(0.7)
//                           : Color.fromRGBO(0, 150, 136, 1.0)
// ),
//                   shape: BoxShape.circle,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.grey.withOpacity(0.3),
//                       spreadRadius: 1,
//                       blurRadius: 3,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Transform.scale(
//                   scale: widget.isLongPressing ? _scaleAnimation.value : 1.0,
//                   child: IconButton(
//                     icon: Icon(
//                       Icons.mic,
//                       color: widget.enabled ? Colors.white : Colors.white54,
//                     ),
//                     onPressed: null, // Disable tap, we're using long press
//                   ),
//                 ),
//               ),
//             ],
//           );
//         },
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
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _bounceAnimation;
  bool _showTapMessage = false;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controllers and Animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOut,
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _bounceController.reverse();
        }
      });

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
    _bounceController.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _showTapMessage = true;
    });
    _bounceController.forward(); // Guaranteed to be initialized

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _showTapMessage = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,
      onLongPressStart: widget.enabled ? widget.onLongPressStart : null,
      onLongPressMoveUpdate: widget.enabled ? widget.onLongPressMoveUpdate : null,
      onLongPressEnd: widget.enabled ? widget.onLongPressEnd : null,
      child: SizedBox(
        width: 50,
        height: 50,
        
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Tap Message
Positioned(
  bottom: 60, // Position above the microphone button
  child: Transform.translate(
    offset: const Offset(-65, 0), // Move slightly to the left
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6, // Max 60% of screen width
      ),
      child: AnimatedOpacity(
        opacity: _showTapMessage ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Arrow Pointer
            Positioned(
              bottom: -6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(221, 225, 6, 6),
                  borderRadius: BorderRadius.circular(2),
                ),
                transform: Matrix4.rotationZ(45 * 3.14 / 180),
              ),
            ),
            // Message Box
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.grey, Color.fromARGB(255, 147, 155, 148)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.3),
                //     blurRadius: 4,
                //     offset: const Offset(2, 2),
                //   ),
                // ],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Hold to record,Release to send",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),


            // Button Animation
            AnimatedBuilder(
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
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.only(right: 20),

                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 150, 136, 1.0)
                                .withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      padding: const EdgeInsets.only(right: 20),

                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: !widget.enabled
                            ? Colors.grey.withOpacity(0.5)
                            : (widget.isLongPressing
                                ? const Color.fromRGBO(0, 150, 136, 1.0)
                                    .withOpacity(0.7)
                                : const Color.fromRGBO(0, 150, 136, 1.0)),
                        shape: BoxShape.circle,
                      ),
                      child: AnimatedBuilder(
                        animation: _bounceController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: Transform.scale(
                              scale: widget.isLongPressing
                                  ? _scaleAnimation.value
                                  : 1.0,
                              child: IconButton(
                                icon: Icon(
                                  Icons.mic,
                                  color: widget.enabled
                                      ? Colors.white
                                      : Colors.white54,
                                ),
                                onPressed:
                                    null, // Disable tap, we're using long press
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
