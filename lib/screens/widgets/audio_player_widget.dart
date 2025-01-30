// lib/screens/widgets/audio_player_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final String? asrResponse;
  final Function(String)? onPlayAudio;

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    this.asrResponse,
    this.onPlayAudio,
  });

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  late AnimationController _progressController;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  FlutterSoundPlayer? _audioPlayer;
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _progressController.addListener(() {
      setState(() {
        _playbackProgress = _progressController.value;
      });
    });
  }

  Future<void> _initializePlayer() async {
    _audioPlayer = FlutterSoundPlayer();
    await _audioPlayer!.openPlayer();
    await _loadAudioDuration();
  }

  Future<void> _loadAudioDuration() async {
    try {
      await _audioPlayer!.startPlayer(
        fromURI: widget.audioPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
          _audioPlayer!.stopPlayer();
        },
      );

      await Future.delayed(const Duration(milliseconds: 100));
      Duration? duration =
          await _audioPlayer!.getProgress().then((value) => value['duration']);

      await _audioPlayer!.stopPlayer();

      setState(() {
        _audioDuration = duration ?? Duration.zero;
        _progressController.duration = _audioDuration;
      });
    } catch (e) {
      print('Error loading audio duration: $e');
      setState(() {
        _audioDuration = const Duration(seconds: 30);
        _progressController.duration = _audioDuration;
      });
    }
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    widget.onPlayAudio?.call(widget.audioPath);

    if (_isPlaying) {
      _audioPlayer!.startPlayer(
        fromURI: widget.audioPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _playbackProgress = 0;
          });
          _audioPlayer!.stopPlayer();
        },
      );

      _progressController.forward(from: _playbackProgress);
    } else {
      _audioPlayer!.pausePlayer();
      _progressController.stop();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _togglePlayback,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.teal,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      value: _isDragging ? _dragValue : _playbackProgress,
                      onChanged: (value) {
                        setState(() {
                          _isDragging = true;
                          _dragValue = value;
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() {
                          _isDragging = false;
                          _playbackProgress = value;
                          final duration = (_audioDuration.inMilliseconds * value).round();
                          _audioPlayer?.seekToPlayer(Duration(milliseconds: duration));
                        });
                      },
                      activeColor: Colors.teal,
                      inactiveColor: Colors.teal.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(_audioDuration),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.asrResponse != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.asrResponse!,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _audioPlayer?.closePlayer();
    super.dispose();
  }
}