import 'package:flutter/material.dart';

class RecordingIndicator extends StatelessWidget {
  final Duration recordingDuration;
  final double slidingOffset;
  final String Function(Duration) formatDuration;

  const RecordingIndicator({
    Key? key,
    required this.recordingDuration,
    required this.slidingOffset,
    required this.formatDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.mic,
              color: Colors.red,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              formatDuration(recordingDuration),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(width: 16),
            if (slidingOffset < 0)
              Text(
                "< Slide to cancel",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
