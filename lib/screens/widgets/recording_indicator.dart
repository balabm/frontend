// import 'package:flutter/material.dart';

// class RecordingIndicator extends StatelessWidget {
//   final Duration recordingDuration;
//   final double slidingOffset;
//   final String Function(Duration) formatDuration;

//   const RecordingIndicator({
//     super.key,
//     required this.recordingDuration,
//     required this.slidingOffset,
//     required this.formatDuration,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.mic,
//               color: Colors.red,
//               size: 20,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               formatDuration(recordingDuration),
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(width: 16),
//             if (slidingOffset < 0)
//               Text(
//                 "< Slide to cancel",
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 14,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// import 'package:flutter/material.dart';

// class RecordingIndicator extends StatefulWidget {
//   final Duration recordingDuration;
//   final double slidingOffset;
//   final String Function(Duration) formatDuration;

//   const RecordingIndicator({
//     super.key,
//     required this.recordingDuration,
//     required this.slidingOffset,
//     required this.formatDuration,
//   });

//   @override
//   State<RecordingIndicator> createState() => _RecordingIndicatorState();
// }

// class _RecordingIndicatorState extends State<RecordingIndicator>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _blinkController;
//   late Animation<double> _opacityAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _blinkController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );

//     _opacityAnimation = Tween<double>(
//       begin: 1.0,
//       end: 0.3,
//     ).animate(CurvedAnimation(
//       parent: _blinkController,
//       curve: Curves.easeInOut,
//     ));

//     _blinkController.repeat(reverse: true);
//   }

//   @override
//   void dispose() {
//     _blinkController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         child: Row(
//           children: [
//             // Animated microphone icon
//             FadeTransition(
//               opacity: _opacityAnimation,
//               child: const Icon(
//                 Icons.mic,
//                 color: Colors.red,
//                 size: 27,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               widget.formatDuration(widget.recordingDuration),
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(width: 16),
//             if (widget.slidingOffset < 0)
//               Text(
//                 "< Slide to cancel",
//                 style: TextStyle(
//                   color: Colors.grey[600],
//                   fontSize: 14,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class RecordingIndicator extends StatefulWidget {
  final Duration recordingDuration;
  final double slidingOffset;
  final String Function(Duration) formatDuration;
  final bool isLongPressing; // Added parameter for long press state

  const RecordingIndicator({
    super.key,
    required this.recordingDuration,
    required this.slidingOffset,
    required this.formatDuration,
    required this.isLongPressing, // Added to constructor
  });

  @override
  State<RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Slightly longer duration for smoother effect
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.4).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut, // Smooth easing curve for the animation
    ));

    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Animated microphone icon with smooth fade in/out
            FadeTransition(
              opacity: _opacityAnimation,
              child: const Icon(
                Icons.mic,
                color: Colors.red,
                size: 27,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.formatDuration(widget.recordingDuration),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 16),
            if (widget.isLongPressing) // Changed condition to use isLongPressing
              AnimatedOpacity(
                opacity: widget.isLongPressing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600), // Smoother transition for the text
                child: Text(
                  "< Slide to cancel",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
