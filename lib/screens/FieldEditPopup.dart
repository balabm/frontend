import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; 
import 'package:provider/provider.dart';
import 'api_response_provider.dart';
import 'dart:convert';  // For JSON encoding
import 'AnswerDisplayScreen.dart';  // Import statement at the top of your file


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
    await Permission.microphone.request();
    await _audioRecorder!.openRecorder();
    await _audioPlayer!.openPlayer();
  }

  Future<String> _getAudioDirPath() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Directory audioDir = Directory('${appDocDir.path}/_audiasro');

    if (!(await audioDir.exists())) {
      await audioDir.create(recursive: true);
    }

    return audioDir.path;
  }

  Future<void> _startRecording() async {
    String audioDir = await _getAudioDirPath();
    String audioFilePath = '$audioDir/audio_temp.wav';

    setState(() {
      isRecording = true;
    });

    try {
      await _audioRecorder!.startRecorder(
        toFile: audioFilePath,
        codec: Codec.pcm16WAV,
      );
      _audioPath = audioFilePath;
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
          codec: Codec.pcm16WAV,
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

  Future<File> _zipAudioFile(String filePath) async {
    Directory tempDir = await getTemporaryDirectory();
    String zipFilePath = '${tempDir.path}/audio_temp.zip';

    final archive = Archive();
    final wavFile = File(filePath);
    final wavBytes = wavFile.readAsBytesSync();

    if (wavBytes.isEmpty) {
      throw Exception("WAV file is empty.");
    }

    archive.addFile(ArchiveFile('audio_temp.wav', wavBytes.length, wavBytes));
    final zipData = ZipEncoder().encode(archive)!;
    final zipFile = File(zipFilePath);
    await zipFile.writeAsBytes(zipData);

    return zipFile;
  }

  Future<void> _sendAudioToApi(File zipFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.31.227:8001/upload-audio-zip/')
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        zipFile.path,
        contentType: MediaType('application', 'zip')
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Provider.of<ApiResponseProvider>(context, listen: false).setAudioZipResponse(responseBody);
      }
    } catch (e) {
      print('Error uploading audio file: $e');
    }
  }
  //new function for textbox
  Future<void> _sendDataToLLMApiWithText(String typedText, String ocrResponse) async {
  final url = Uri.parse('http://192.168.31.227:8021/get_llm_response');

  try {
    Map<String, dynamic> ocrData = jsonDecode(ocrResponse);
    String extractedText = ocrData['extracted_text'];

    // Create the request body, including the typed text.
    Map<String, dynamic> body = {
      "form_entry": extractedText,   // Pass extracted text from ocrResponse
      "voice_query": typedText       // Pass the typed text from the TextField
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      // Navigate to the AnswerDisplayScreen with the LLM response.
      Map<String, dynamic> llmResponse = jsonDecode(response.body);
      String query = llmResponse['query'] ?? 'No query';
      String responseText = llmResponse['response'] ?? 'No response';

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnswerDisplayScreen(
            query: query,
            answer: responseText,
          ),
        ),
      );
    } else {
      print("Failed to get LLM response: ${response.statusCode}");
    }
  } catch (e) {
    print("Error in LLM API call with text: $e");
  }
}


  Future<void> _sendDataToLLMApi(String audioZipResponse, String ocrResponse) async {
    final url = Uri.parse('http://192.168.31.227:8021/get_llm_response');

    try {
      // Parse the JSON response
      Map<String, dynamic> ocrData = jsonDecode(ocrResponse);
      Map<String, dynamic> audioData = jsonDecode(audioZipResponse);

      String extractedText = ocrData['extracted_text'];
      String dummyText = audioData['dummy_text'];
      
      // Create the request body
      Map<String, dynamic> body = {
        "form_entry": extractedText,   // Pass extracted text from ocrResponse
        "voice_query": dummyText       // Pass dummy text from audioZipResponse
      };

      // Send POST request
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // Navigate to the AnswerDisplayScreen with the response
        Map<String, dynamic> llmResponse = jsonDecode(response.body);
        String query = llmResponse['query'] ?? 'No query';
        String responseText = llmResponse['response'] ?? 'No response';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnswerDisplayScreen(
              query: query,
              answer: responseText,
            ),
          ),
        );
      } else {
        print("Failed to get LLM response: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in LLM API call: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioZipResponse = Provider.of<ApiResponseProvider>(context).audioZipResponse;
    final ocrResponse = Provider.of<ApiResponseProvider>(context).ocrResponse;

    return AlertDialog(
      backgroundColor: Colors.white,
      //title: Text(
        //widget.fieldName,
        //style: TextStyle(
          //fontSize: 22,
          //fontWeight: FontWeight.bold,
          //color: Color(0xFF0b3c66),
        //),
        //textAlign: TextAlign.center,
      //),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ocrResponse != null)
                Text(
  ocrResponse != null
      ? " ${jsonDecode(ocrResponse)['extracted_text'] ?? 'No text found'}"
      : "No API Response",
  style: TextStyle(
    fontSize: 22,
    color: Color(0xFF0b3c66),
    fontWeight: FontWeight.bold,
  ),
),

              SizedBox(height: 8),
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
                maxLength: 100,
              ),
              SizedBox(height: 8),
              Text(
                'How can I assist you with this section?',
                style: TextStyle(
                  fontSize: 12,
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
              ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFF0b3c66),  // Button background color
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () async {
    if (_controller.text.isNotEmpty) {
      // If text is typed in the TextField, directly send it with ocrResponse to the LLM model.
      if (ocrResponse != null) {
        await _sendDataToLLMApiWithText(_controller.text, ocrResponse);
      } else {
        print('OCR response is missing.');
      }
    } else if (_audioPath != null) {
      // Existing logic for audio: zip and send the audio file to the API.
      File zipFile = await _zipAudioFile(_audioPath!);
      await _sendAudioToApi(zipFile);

      // After audio is uploaded, if both audioZipResponse and ocrResponse are available, send them to LLM.
      final audioZipResponse = Provider.of<ApiResponseProvider>(context, listen: false).audioZipResponse;
      if (audioZipResponse != null && ocrResponse != null) {
        await _sendDataToLLMApi(audioZipResponse, ocrResponse);
      }
    }
  },
  child: Text(
    'Submit',
    style: TextStyle(
      color: Colors.white,  // Set the text color to white
    ),
  ),
),

            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    _audioPlayer!.closePlayer();
    _controller.dispose();
    super.dispose();
  }
}
