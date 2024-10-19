import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'AnswerDisplayScreen.dart';

class FieldEditPopup extends StatefulWidget {
  final String fieldName;

  FieldEditPopup({required this.fieldName});

  @override
  _FieldEditPopupState createState() => _FieldEditPopupState();
}

class _FieldEditPopupState extends State<FieldEditPopup> {
  TextEditingController _controller = TextEditingController();
  bool isRecording = false;
  bool isPlaying = false;
  String? _audioPath; // Path to store the recorded audio
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    // Request microphone permission
    await Permission.microphone.request();

    await _audioRecorder!.openRecorder();
    await _audioPlayer!.openPlayer();
  }

  Future<void> _startRecording() async {
    Directory tempDir = Directory.systemTemp;
    String tempPath = '${tempDir.path}/audio_temp.aac';

    setState(() {
      isRecording = true;
    });

    try {
      await _audioRecorder!.startRecorder(
        toFile: tempPath,
        codec: Codec.aacADTS,
      );
      _audioPath = tempPath; // Save the path to use for playback
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
    } catch (e) {
      print("Error stopping recording: $e");
    }
    setState(() {
      isRecording = false;
    });
  }

  Future<void> _playAudio() async {
    if (_audioPath != null && !isPlaying) {
      setState(() {
        isPlaying = true;
      });
      try {
        await _audioPlayer!.startPlayer(
          fromURI: _audioPath,
          codec: Codec.aacADTS,
          whenFinished: () {
            setState(() {
              isPlaying = false;
            });
          },
        );
      } catch (e) {
        print("Error playing audio: $e");
        setState(() {
          isPlaying = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    if (isPlaying) {
      try {
        await _audioPlayer!.stopPlayer();
      } catch (e) {
        print("Error stopping audio: $e");
      }
      setState(() {
        isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // Set the card background to white
      title: Text(
        widget.fieldName,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0b3c66),
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Enter Value',
        labelStyle: TextStyle(color: Color(0xFF0b3c66)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF0b3c66)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        suffixIcon: IconButton(
          onPressed: isRecording ? _stopRecording : _startRecording,
          icon: Icon(
            isRecording ? Icons.stop : Icons.mic,
            color: isRecording ? Colors.red : Color(0xFF0b3c66),
          ),
        ),
      ),
      maxLines: 2,
      maxLength: 100, // Set character limit here
    ),

                  SizedBox(height: 8),
              Text(
                'How can I assist you with this section?',
                style: TextStyle(
                  fontSize: 12, // Small font size
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              if (_audioPath != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: Color(0xFF0b3c66),
                      ),
                      onPressed: isPlaying ? _stopAudio : _playAudio,
                    ),
                    Text(
                      isPlaying ? "Stop Audio" : "Play Audio",
                      style: TextStyle(color: Color(0xFF0b3c66)),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0b3c66),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Ensure that the entered value or recorded audio is available
                    if (_controller.text.isNotEmpty || _audioPath != null) {
                      // Proceed to the next screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnswerDisplayScreen(
                            answer: _controller.text.isNotEmpty
                                ? _controller.text
                                : 'Audio response recorded',
                          ),
                        ),
                      );
                    } else {
                      // Show a snackbar if neither text nor audio is provided
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a value or record audio before submitting'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      contentPadding: EdgeInsets.all(24),
    );
  }

  @override
  void dispose() {
    _audioRecorder?.closeRecorder();
    _audioPlayer?.closePlayer();
    super.dispose();
  }
}
