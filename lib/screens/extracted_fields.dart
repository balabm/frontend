import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ExtractedFieldsScreen extends StatefulWidget {
  @override
  _ExtractedFieldsScreenState createState() => _ExtractedFieldsScreenState();
}

class _ExtractedFieldsScreenState extends State<ExtractedFieldsScreen> {
  TextEditingController _queryController = TextEditingController();
  bool isRecording = false; // For mic recording status
  bool isPlaying = false; // For audio playback status
  FlutterSoundRecorder? _audioRecorder; // Flutter Sound recorder instance
  FlutterSoundPlayer? _audioPlayer; // Flutter Sound player instance
  String? _audioFilePath; // File path for recorded audio

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    // Request permission for the microphone
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _audioRecorder!.openRecorder(); // Open the recorder session
    await _audioPlayer!.openPlayer(); // Open the player session
  }

  Future<void> _startRecording() async {
    Directory tempDir = Directory.systemTemp;
    String tempPath = '${tempDir.path}/flutter_sound_temp.aac';

    setState(() {
      isRecording = true;
      isPlaying = false; // Ensure not playing when recording
    });

    await _audioRecorder!.startRecorder(
      toFile: tempPath,
      codec: Codec.aacADTS,
    );

    _audioFilePath = tempPath;
  }

  Future<void> _stopRecording() async {
    await _audioRecorder!.stopRecorder();
    setState(() {
      isRecording = false;
      _queryController.text = 'Audio recorded at $_audioFilePath'; // Display file path
    });
  }

  Future<void> _playAudio() async {
    if (_audioFilePath != null) {
      await _audioPlayer!.startPlayer(
        fromURI: _audioFilePath!,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            isPlaying = false;
          });
        },
      );
      setState(() {
        isPlaying = true;
      });
    }
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer!.stopPlayer();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _reRecord() async {
    setState(() {
      isPlaying = false;
    });
    await _startRecording();
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder(); // Close the recorder session when done
    _audioPlayer!.closePlayer(); // Close the player session when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> extractedFields =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;

    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Color.fromRGBO(16, 121, 63,1 ),
        iconTheme: IconThemeData(color: Colors.white), // Set arrow color to white
      ),
      body: Container(
        color: Colors.white, // Set background to white
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display extracted fields
            ...extractedFields.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text('${entry.key}: ${entry.value}',
                    style: TextStyle(fontSize: 18, color: Colors.black87)),
              );
            }).toList(),
            Spacer(),
            Row(
              children: [
                // Stylish Microphone button
                Container(
                  decoration: BoxDecoration(
                    color: isRecording
                        ? Colors.red
                        : isPlaying
                            ? Colors.green
                            : Color.fromRGBO(16, 121, 63,1 ), // Dynamic color change
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isRecording
                          ? Icons.stop
                          : isPlaying
                              ? Icons.pause
                              : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: isRecording
                        ? _stopRecording
                        : isPlaying
                            ? _stopPlaying
                            : _startRecording, // Start/Stop recording or playback functionality
                    iconSize: 24.0,
                  ),
                ),

                // Expanded TextField to occupy the entire width
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: 8.0), // Adjust space between mic and TextField
                    child: TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question or type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0), // Add radius to all sides
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        suffixIcon: IconButton(
                          icon: Icon(Icons.send, color: Color.fromRGBO(16, 121, 63,1 )),
                          onPressed: () {
                            // Handle submit action
                            print('User input: ${_queryController.text}');
                          },
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_audioFilePath != null && !isRecording) 
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.play_arrow, color: Colors.green),
                      onPressed: isPlaying ? null : _playAudio,
                    ),
                    IconButton(
                      icon: Icon(Icons.replay, color: Colors.blue),
                      onPressed: _reRecord,
                    ),
                    if (isPlaying)
                      IconButton(
                        icon: Icon(Icons.stop, color: Colors.red),
                        onPressed: _stopPlaying,
                      ),
                  ],
                ),
              ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
