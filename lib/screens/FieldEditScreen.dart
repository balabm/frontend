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
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img;





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
  bool _isLongPressing = false;
  double _slidingOffset = 0;
  DateTime? _recordingStartTime;
  
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
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes % 60);
  final seconds = twoDigits(duration.inSeconds % 60);
  return "${hours != '00' ? '$hours:' : ''}$minutes:$seconds";
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

  void _startRecording() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      _recordedFilePath = path.join(tempDir.path, 'recorded_audio.wav');
      
      await _audioRecorder!.startRecorder(
        toFile: _recordedFilePath,
        codec: Codec.pcm16WAV,
      );

      setState(() {
        _isRecording = true;
        _recordingStartTime = DateTime.now();
      });
      print("Recording started");
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  void _cancelRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
        await File(_recordedFilePath!).delete();
      }
      setState(() {
        _isRecording = false;
        _isLongPressing = false;
        _slidingOffset = 0;
        _recordingStartTime = null;
      });
      print("Recording cancelled");
    } catch (e) {
      print("Error cancelling recording: $e");
    }
  }

  void _stopAndSendRecording() async {
    try {
      await _audioRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _isLongPressing = false;
        _slidingOffset = 0;
        _recordingStartTime = null;
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

    Widget _buildMicrophoneButton() {
    return GestureDetector(
      onLongPressStart: (_) {
        setState(() {
          _isLongPressing = true;
        });
        _startRecording();
      },
      onLongPressMoveUpdate: (details) {
        setState(() {
          _slidingOffset = details.offsetFromOrigin.dx;
        });
      },
      onLongPressEnd: (_) {
        if (_slidingOffset < -50) {
          _cancelRecording();
        } else {
          _stopAndSendRecording();
        }
      },
      child: Container(
        margin: EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: _isLongPressing 
              ? Color(0xFF0b3c66).withOpacity(0.7)
              : Color(0xFF0b3c66),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.mic,
            color: Colors.white,
          ),
          onPressed: null, // Disable tap, we're using long press
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    if (!_isRecording) return SizedBox.shrink();

    Duration duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;

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
              _formatDuration(duration),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            SizedBox(width: 16),
            if (_slidingOffset < 0)
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
        Uri.parse('http://192.168.1.7:8001/upload-audio-zip/')
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
    final uri = Uri.parse('http://192.168.1.7:8021/get_llm_response');
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
    final uri = Uri.parse('http://192.168.1.7:8080/cv/ocr');
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
              ),
              child: Column(
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
                              ? 'assets/user_avatar.png'
                              : 'assets/bot_avatar.png',
                        );
                      },
                    ),
                  ),
                  // Chat Input Area
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
                        _isRecording
                            ? _buildRecordingIndicator()
                            : Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    hintText: 'Type a message',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                  ),
                                  enabled: _inputEnabled,
                                  onChanged: (text) {
                                    setState(() {});
                                  },
                                ),
                              ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          transform: Matrix4.translationValues(_slidingOffset, 0, 0),
                          child: _messageController.text.isEmpty
                              ? _buildMicrophoneButton()
                              : IconButton(
                                  icon: Icon(Icons.send, color: Color(0xFF0b3c66)),
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
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
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
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
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
                    FadeInWidget(
                      child: Padding(
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

class FadeInWidget extends StatefulWidget {
  final Widget child;

  const FadeInWidget({Key? key, required this.child}) : super(key: key);

  @override
  _FadeInWidgetState createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}



class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final Function(String)? onPlayAudio;

  AudioPlayerWidget({required this.audioPath, this.onPlayAudio});

  @override
  _AudioPlayerWidgetState createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  late AnimationController _progressController;
  Duration _audioDuration = Duration.zero;
  FlutterSoundPlayer? _audioPlayer;
  Duration _currentPosition = Duration.zero; // Track current audio position

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Initial duration, will be updated
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

      await Future.delayed(Duration(milliseconds: 100));
      Duration? duration = await _audioPlayer!.getProgress().then((value) => value['duration']);

      await _audioPlayer!.stopPlayer();

      setState(() {
        _audioDuration = duration ?? Duration.zero;
        _progressController.duration = _audioDuration;
      });
    } catch (e) {
      print('Error loading audio duration: $e');
      setState(() {
        _audioDuration = Duration(seconds: 30);
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
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF), // White background for contrast
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlayback,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF00A884),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          SizedBox(width: 16),

          // Progress bar and audio details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar using Slider
                Slider(
                  value: _playbackProgress,
                  min: 0,
                  max: 1,
                  onChanged: (newValue) {
                    setState(() {
                      _playbackProgress = newValue;
                      _audioPlayer!.seekToPlayer(Duration(seconds: (_playbackProgress * _audioDuration.inSeconds).toInt()));
                    });
                  },
                  activeColor: Color(0xFF00A884),
                  inactiveColor: Colors.grey.shade300,
                  thumbColor: Color(0xFF00A884), // Thumb color for the slider
                ),
                SizedBox(height: 4),

                // Current and total duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_currentPosition),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatDuration(_audioDuration),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 8),

          // Microphone Icon
          Icon(Icons.mic, color: Color(0xFF00A884), size: 28),
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