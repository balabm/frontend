import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  _AudioRecordingScreenState createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String? _imagePath;
  bool _hasPermission = false;
  Timer? _timer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _imagePath = ModalRoute.of(context)!.settings.arguments as String?;
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _hasPermission = false;
      });
      return;
    }

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    setState(() {
      _hasPermission = true;
    });
  }

  Future<void> _initPlayer() async {
    _player = FlutterSoundPlayer();
    await _player!.openPlayer();
  }

  Future<void> _startRecording() async {
    if (_recorder!.isRecording) {
      await _stopRecording();
    }

    final dir = await getApplicationDocumentsDirectory();
    _recordingPath =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder!.startRecorder(toFile: _recordingPath);

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  Future<void> _stopRecording() async {
    await _recorder!.stopRecorder();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null && !_isPlaying) {
      await _player!.startPlayer(
        fromURI: _recordingPath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );
      setState(() {
        _isPlaying = true;
      });
    } else if (_isPlaying) {
      await _player!.stopPlayer();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _reRecord() async {
    await _stopRecording();
    setState(() {
      _recordingPath = null;
      _recordingDuration = 0;
    });
    await _startRecording();
  }

  @override
  void dispose() {
    _recorder!.closeRecorder();
    _player!.closePlayer();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_hasPermission)
                const Text(
                  'Microphone permission not granted',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              if (_hasPermission) ...[
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label:
                      Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                ),
                if (!_isRecording && _recordingPath != null) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label:
                        Text(_isPlaying ? 'Stop Playback' : 'Play Recording'),
                    onPressed: _playRecording,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Re-record'),
                    onPressed: _reRecord,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('Next'),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/review_submit',
                        arguments: {
                          'imagePath': _imagePath,
                          'audioPath': _recordingPath,
                        },
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
