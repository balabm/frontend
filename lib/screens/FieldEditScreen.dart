import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'api_response_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'dart:math';


class FieldEditScreen extends StatefulWidget {
  @override
  _FieldEditScreenState createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> {
  String? imagePath;
  List<dynamic>? boundingBoxes;
  List<Map<String, dynamic>> chatMessages = [];
  TextEditingController _messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  DraggableScrollableController _dragController = DraggableScrollableController();
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  bool _inputEnabled = false;
  String? _selectedFieldName;
  String? _ocrText;

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initializeRecorder();
    _initializePlayer();
  }

  Future<void> _initializeRecorder() async {
    await _audioRecorder!.openRecorder();
    await _audioRecorder!.setSubscriptionDuration(Duration(milliseconds: 10));
    print("Recorder initialized");
  }

  Future<void> _initializePlayer() async {
    await _audioPlayer!.openPlayer();
    print("Player initialized");
  }

  @override
  void dispose() {
    _audioRecorder!.closeRecorder();
    _audioPlayer!.closePlayer();
    _audioRecorder = null;
    _audioPlayer = null;
    _messageController.dispose();
    _scrollController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _recordedFilePath = path.join(tempDir.path, 'recorded_audio.wav');
      
      await _audioRecorder!.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
      });
      print("Recording started");
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
      });
      print("Recording stopped");
      await _processAudioAndSendToLLM();
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await _audioPlayer!.stopPlayer();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer!.startPlayer(
          fromURI: audioPath,
          whenFinished: () {
            setState(() {
              _isPlaying = false;
            });
          },
        );
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }
  
    Future<String> _zipRecordedAudio() async {
    Directory tempDir = await getTemporaryDirectory();
    String zipFilePath = path.join(tempDir.path, 'audio_zip.zip');
    
    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(zipFilePath);
    zipEncoder.addFile(File(_recordedFilePath!));
    zipEncoder.close();
    
    return zipFilePath;
  }

  Future<String?> _sendAudioToApi(File zipFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.31.227:8001/upload-audio-zip/')
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        zipFile.path,
        contentType: MediaType('application', 'zip'),
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        Provider.of<ApiResponseProvider>(context, listen: false)
            .setAudioZipResponse(responseBody);
        print('Audio ZIP sent successfully!');
        return responseBody;
      } else {
        print('Failed to upload ZIP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading audio ZIP file: $e');
      return null;
    }
  }

  Future<void> _processAudioAndSendToLLM() async {
    String zipFilePath = await _zipRecordedAudio();
    File zipFile = File(zipFilePath);
    
    if (await zipFile.exists()) {
      String? asrResponse = await _sendAudioToApi(zipFile);
      if (asrResponse != null) {
        // Add audio message to chat
        setState(() {
          chatMessages.add({
            'sender': 'user',
            'message': 'Audio message',
            'audioPath': _recordedFilePath,
          });
        });

        // Send to LLM API
        await _sendToLLMApi(asrResponse, isAudioQuery: true);
      }
    } else {
      print("ZIP file does not exist at the path: $zipFilePath");
    }
  }

  Future<void> _sendToLLMApi(String query, {bool isAudioQuery = false}) async {
    final uri = Uri.parse('http://192.168.31.227:8021/get_llm_response');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'form_entry': _ocrText ?? '',
          'voice_query': isAudioQuery ? query : '',
        }),
      );

      if (response.statusCode == 200) {
        final llmResponse = jsonDecode(response.body);
        setState(() {
          chatMessages.add({
            'sender': 'assistant',
            'message': llmResponse['response'],
          });
        });
        _scrollToBottom();
      } else {
        print('Failed to get LLM response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while sending data to LLM API: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    imagePath = arguments['imagePath'] as String?;
    boundingBoxes = arguments['bounding_boxes'] as List<dynamic>?;

    chatMessages.add({
      'sender': 'assistant',
      'message': 'Please select a field to edit.',
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onBoundingBoxTap(Map<String, dynamic> box) {
    setState(() {
      _inputEnabled = true;
      _selectedFieldName = box['class'];
    });

    _sendDataToApi(box);
  }

  Future<void> _sendDataToApi(Map<String, dynamic> box) async {
    final uri = Uri.parse('http://192.168.31.227:8080/cv/ocr');
    var request = http.MultipartRequest('POST', uri);

    // Crop the image
    String croppedImagePath = await _cropImage(
      imagePath!,
      box['x_center'].toInt(),
      box['y_center'].toInt(),
      box['width'].toInt(),
      box['height'].toInt()
    );

    var file = File(croppedImagePath);
    if (await file.exists()) {
      List<int> imageBytes = await file.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('form_image', imageBytes, filename: 'cropped_image.png'));
    } else {
      print('Cropped image file does not exist at the given path: $croppedImagePath');
      return;
    }

    request.fields['x_center'] = box['x_center'].toString();
    request.fields['y_center'] = box['y_center'].toString();
    request.fields['width'] = box['width'].toString();
    request.fields['height'] = box['height'].toString();
    request.fields['class_type'] = box['class'];

    try {
      var response = await request.send();
      final provider = Provider.of<ApiResponseProvider>(context, listen: false);

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Data sent successfully! Response: $responseBody');

        provider.setOcrResponse(responseBody);

        // Parse OCR response and extract text
        final ocrData = jsonDecode(responseBody);
        _ocrText = ocrData['extracted_text'];

        setState(() {
          chatMessages.add({
            'sender': 'assistant',
            'message': 'Field ${box['class']} selected. The detected text is: $_ocrText',
          });
        });
        _scrollToBottom();
      } else {
        print('Failed to send data: ${response.statusCode}');
        final errorResponse = await response.stream.bytesToString();
        print('Error response: $errorResponse');
      }
    } catch (e) {
      print('Error occurred while sending data: $e');
    }
  }

  Future<String> _cropImage(String imagePath, int xCenter, int yCenter, int width, int height) async {
    final imageFile = img.decodeImage(File(imagePath).readAsBytesSync())!;
    int x = (xCenter - (width ~/ 2)).toInt();
    int y = (yCenter - (height ~/ 2)).toInt();
    int cropWidth = width.toInt();
    int cropHeight = height.toInt();
    img.Image croppedImage = img.copyCrop(imageFile, x: x, y: y, width: cropWidth, height: cropHeight);

    final croppedImagePath = '${Directory.systemTemp.path}/cropped_image.png';
    File(croppedImagePath).writeAsBytesSync(img.encodePng(croppedImage));

    return croppedImagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Field Extraction'),
        backgroundColor: Color(0xFF0b3c66),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 4.0,
              child: Stack(
                children: [
                  if (imagePath != null)
                    Image.file(
                      File(imagePath!),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  if (boundingBoxes != null)
                    ...boundingBoxes!.map((box) {
                      final int x = box['x_center'].toInt() - (box['width'].toInt() ~/ 2);
                      final int y = box['y_center'].toInt() - (box['height'].toInt() ~/ 2);
                      final int width = box['width'].toInt();
                      final int height = box['height'].toInt();
                      final String fieldType = box['class'];

                      return Positioned(
                        left: x.toDouble(),
                        top: y.toDouble(),
                        width: width.toDouble(),
                        height: height.toDouble(),
                        child: GestureDetector(
                          onTap: () => _onBoundingBoxTap(box),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color.fromRGBO(245, 10, 10, 1), width: 2),
                              color: const Color.fromARGB(255, 243, 33, 33).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Center(
                              child: Text(
                                fieldType,
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 243, 37, 33),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: [0.3, 0.6, 0.9],
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),                 child: Column(
                  children: [
                    GestureDetector(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = chatMessages[index];
                            return ChatBubble(
  sender: message['sender'],
  message: message['message'],
  audioPath: message['audioPath'],
  onPlayAudio: _playAudio,
  avatar: message['sender'] == 'user' 
          ? 'assets/user_avatar.png' // User's avatar image path
          : 'assets/bot_avatar.png',  // Bot's avatar image path
);
                        },
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(8),
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              color: _inputEnabled ? Color(0xFF0b3c66) : Colors.grey,
                            ),
                            onPressed: _inputEnabled
                                ? () {
                                    if (_isRecording) {
                                      _stopRecording();
                                    } else {
                                      _startRecording();
                                    }
                                  }
                                : null,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[400]),
                              ),
                              enabled: _inputEnabled,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: _inputEnabled ? Color(0xFF0b3c66) : Colors.grey),
                            onPressed: _inputEnabled
                                ? () {
                                    if (_messageController.text.isNotEmpty) {
                                      setState(() {
                                        chatMessages.add({
                                          'sender': 'user',
                                          'message': _messageController.text,
                                        });
                                      });
                                      _sendToLLMApi(_messageController.text);
                                      _messageController.clear();
                                      _scrollToBottom();
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
class ChatBubble extends StatelessWidget {
  final String sender;
  final String message;
  final String? audioPath;
  final Function(String)? onPlayAudio;
  final String avatar;

  ChatBubble({
    required this.sender,
    required this.message,
    this.audioPath,
    this.onPlayAudio,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    bool isUser = sender == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: 24,
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: isUser ? Color(0xFFDCF8C6) : Color(0xFFE0E0E0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft:
                      isUser ? Radius.circular(16) : Radius.circular(0),
                  bottomRight:
                      isUser ? Radius.circular(0) : Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3), // changes position of shadow
                  ),
                ],
              ),
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (audioPath != null)
                    AudioPlayerWidget(
                        audioPath: audioPath!, onPlayAudio: onPlayAudio),
                  if (message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ),
                  SizedBox(height: 6),
                  
                ],
              ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(
              backgroundImage: AssetImage(avatar),
              radius: 24,
            ),
          ],
        ],
      ),
    );
  }
}
class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final Function(String)? onPlayAudio;

  AudioPlayerWidget({required this.audioPath, this.onPlayAudio});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    widget.onPlayAudio?.call(widget.audioPath);

    // Simulating playback progress
    if (_isPlaying) {
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted && _isPlaying) {
          setState(() {
            _playbackProgress += 0.01;
            if (_playbackProgress >= 1.0) {
              _playbackProgress = 0.0;
              _isPlaying = false;
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayback,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF00A884),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomPaint(
                  size: Size(double.infinity, 30),
                  painter: WaveformPainter(progress: _playbackProgress),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "0:${(_playbackProgress * 60).toInt().toString().padLeft(2, '0')}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      "1:00",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.mic, color: Color(0xFF00A884), size: 24),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;

  WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(0xFF00A884);

    final int barCount = 40;
    final double barWidth = size.width / (barCount * 2 - 1);
    final double maxBarHeight = size.height;

    for (int i = 0; i < barCount; i++) {
      final double normalizedHeight = _getNormalizedHeight(i, barCount);
      final double barHeight = normalizedHeight * maxBarHeight;
      final double left = 2 * i * barWidth;
      final double top = (size.height - barHeight) / 2;

      // Draw the bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeight),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
    }

    // Draw the progress overlay
    final Paint progressPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.5);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      progressPaint,
    );
  }

  double _getNormalizedHeight(int index, int total) {
    // This function returns a height value between 0 and 1 based on the index
    // You can adjust this to match the exact pattern in the image
    final List<double> heights = [
      0.2, 0.5, 0.7, 0.9, 1.0, 0.8, 0.6, 0.4, 0.3, 0.5,
      0.7, 0.9, 1.0, 0.8, 0.6, 0.4, 0.2, 0.5, 0.7, 0.9,
      1.0, 0.8, 0.6, 0.4, 0.3, 0.5, 0.7, 0.9, 1.0, 0.8,
      0.6, 0.4, 0.2, 0.5, 0.7, 0.9, 1.0, 0.8, 0.6, 0.4
    ];
    return heights[index % heights.length];
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}