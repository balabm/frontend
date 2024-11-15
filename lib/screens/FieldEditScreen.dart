import 'dart:io';
import 'package:ass/helpers/database_helper.dart';
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
import 'dart:async';
import 'widgets/index.dart';


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
  DraggableScrollableController _dragController =
      DraggableScrollableController();
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
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _needsScroll = false;
  Map<String, dynamic>? selectedBox;
  Set<Map<String, dynamic>> previouslySelectedBoxes = {};

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
    _recordingTimer?.cancel();
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
        _recordingDuration = Duration.zero;
      });

      // Start the timer to update duration every 100ms
      _recordingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        if (_recordingStartTime != null) {
          setState(() {
            _recordingDuration =
                DateTime.now().difference(_recordingStartTime!);
          });
        }
      });

      print("Recording started");
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  void _cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder!.stopRecorder();
      if (_recordedFilePath != null && File(_recordedFilePath!).existsSync()) {
        await File(_recordedFilePath!).delete();
      }
      setState(() {
        _isRecording = false;
        _isLongPressing = false;
        _slidingOffset = 0;
        _recordingStartTime = null;
        _recordingDuration = Duration.zero;
      });
      print("Recording cancelled");
    } catch (e) {
      print("Error cancelling recording: $e");
    }
  }

  void _stopAndSendRecording() async {
    try {
      _recordingTimer?.cancel();
      await _audioRecorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _isLongPressing = false;
        _slidingOffset = 0;
        _recordingStartTime = null;
        _recordingDuration = Duration.zero;
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

 
    
  // Add a new method to handle the actual scrolling
  void _performScroll() {
    if (_needsScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      _needsScroll = false;
    }
  }

  // Override didUpdateWidget to handle scroll after state updates
  @override
  void didUpdateWidget(FieldEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _performScroll());
  }

// Replace the widget building methods with:
Widget _buildMicrophoneButton() {
  return MicrophoneButton(
    isLongPressing: _isLongPressing,
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
  );
}

Widget _buildRecordingIndicator() {
  if (!_isRecording) return SizedBox.shrink();

  return RecordingIndicator(
    recordingDuration: _recordingDuration,
    slidingOffset: _slidingOffset,
    formatDuration: _formatDuration,
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
          'POST', Uri.parse('http://192.168.77.227:8001/upload-audio-zip/'));

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        zipFile.path,
        contentType: MediaType('application', 'zip'),
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        _dbHelper.saveAsrResponse(responseBody);
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
        // Parse ASR response
        Map<String, dynamic> asrData = jsonDecode(asrResponse);
        String transcribedText = asrData['dummy_text'] ?? 'No transcription available';
        
        // Add audio message to chat
        setState(() {
          chatMessages.add({
            'sender': 'user',
            'message': 'Audio message • $transcribedText', // Combine audio message with ASR text
            'audioPath': _recordedFilePath,
            'isAudioMessage': true, // Add flag to identify audio messages
          });
        });

        // Ensure scroll to bottom
        _scrollToBottom();

        // Send to LLM API
        await _sendToLLMApi(asrResponse, isAudioQuery: true);
      }
    } else {
      print("ZIP file does not exist at the path: $zipFilePath");
    }
  }

  Future<void> _sendToLLMApi(String query, {bool isAudioQuery = false}) async {
    final uri = Uri.parse('http://192.168.77.227:8021/get_llm_response');
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
        print('my LLM Response: ${response.body}');
        final Map<String, dynamic> llmResponse = jsonDecode(response.body);
        _dbHelper.saveLlmResponse(jsonEncode(llmResponse));

        setState(() {
          chatMessages.add({
            'sender': 'assistant',
            'message': llmResponse['response'] ?? 'No response available',
          });
          _needsScroll = true;  // Set flag to scroll after setState
        });
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
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    imagePath = arguments['imagePath'] as String?;
    boundingBoxes = arguments['bounding_boxes'] as List<dynamic>?;

    chatMessages.add({
      'sender': 'assistant',
      'message': 'Please select a field to edit.',
    });
  }

  void _scrollToBottom() {
     setState(() {
      _needsScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
     });
  }


  void _onBoundingBoxTap(Map<String, dynamic> box) {
    setState(() {
      _inputEnabled = true;
      _selectedFieldName = box['class'];
      selectedBox = box;
      // If selecting a new box, add the current selected box to previouslySelectedBoxes
      if (selectedBox != null) {
        previouslySelectedBoxes.add(selectedBox!);
      }
      selectedBox = box; // Set the newly tapped box as the current selection
  
      
    });

    _sendDataToApi(box);
  }

  Future<void> _sendDataToApi(Map<String, dynamic> box) async {
    final uri = Uri.parse('http://192.168.77.227:8080/cv/ocr');
    var request = http.MultipartRequest('POST', uri);

    // Crop the image
    // String croppedImagePath = await _cropImage(
    //     imagePath!,
    //     box['x_center'].toInt(),
    //     box['y_center'].toInt(),
    //     box['width'].toInt(),
    //     box['height'].toInt());

    var file = File(imagePath as String);
    if (await file.exists()) {
    // Fix: Add filename and content-type to the MultipartFile
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      // Optional: Add content type if needed
      contentType: MediaType('image', 'png'),
    ));
    } else {
      print(
          'Cropped image file does not exist at the given path: $imagePath');
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
            'message':
                'Field ${box['class']} selected. The detected text is: $_ocrText',
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

  

  Future<String> _cropImage(
      String imagePath, int xCenter, int yCenter, int width, int height) async {
    final imageFile = img.decodeImage(File(imagePath).readAsBytesSync())!;
    int x = (xCenter - (width ~/ 2)).toInt();
    int y = (yCenter - (height ~/ 2)).toInt();
    int cropWidth = width.toInt();
    int cropHeight = height.toInt();
    img.Image croppedImage = img.copyCrop(imageFile,
        x: x, y: y, width: cropWidth, height: cropHeight);

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
        // Image and Bounding Boxes Container
        InteractiveViewer(
          
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center, 
            child: Stack(
              
              children: [
                // Base Image
                if (imagePath != null)
                  Align(
                    alignment: Alignment.center,
                    child: Image.file(
                      File(imagePath!),
                    ),
                  ),
                    
                // Bounding Boxes Overlay
                if (boundingBoxes != null)
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Image size to calculate scaling factors
                        final imageFile = File(imagePath!);
                        final image = Image.file(imageFile);
                        final ImageStream stream = image.image.resolve(ImageConfiguration());
                        late double scaleX;
                        late double scaleY;
                    
                        stream.addListener(ImageStreamListener((info, _) {
                          final double imageWidth = info.image.width.toDouble();
                          final double imageHeight = info.image.height.toDouble();
                    
                          // Calculate scaling factors
                          scaleX = constraints.maxWidth / imageWidth;
                          scaleY = constraints.maxHeight / imageHeight;
                        }));
                    
                        return Stack(
                          children: boundingBoxes!.map((box) {
                            // Scale the coordinates
                            final scaledX = box['x_center'] * scaleX - (box['width'] * scaleX / 2);
                            final scaledY = box['y_center'] * scaleY - (box['height'] * scaleY / 2);
                            final scaledWidth = box['width'] * scaleX;
                            final scaledHeight = box['height'] * scaleY;
                            final fieldType = box['class'];
                    
                            // Determine box color based on selection state
                            final isCurrentlySelected = selectedBox == box;
                            final wasEverSelected = previouslySelectedBoxes.contains(box);
                    
                            final borderColor = isCurrentlySelected
                                ? Colors.blue
                                : wasEverSelected
                                    ? const Color.fromARGB(255, 192, 191, 155)
                                    : Colors.green;
                            final fillColor = borderColor.withOpacity(0.1);
                    
                            return Positioned(
                              left: scaledX,
                              top: scaledY,
                              width: scaledWidth,
                              height: scaledHeight,
                              child: GestureDetector(
                                onTap: () => _onBoundingBoxTap(box),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                    ),
                                    color: fillColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: Text(
                                      fieldType,
                                      style: TextStyle(
                                        color: borderColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        backgroundColor: Colors.white.withOpacity(0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // DraggableScrollableSheet
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          snap: true,
          snapSizes: [0.3, 0.6, 0.9],
          builder: (BuildContext context, ScrollController scrollController) {
            _scrollController = scrollController;
            WidgetsBinding.instance.addPostFrameCallback((_) => _performScroll());
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
                          isAudioMessage: message['isAudioMessage'] ?? false,
                        );
                      },
                    ),
                  ),
                  // Chat Input Area
                  Container(
                    margin: EdgeInsets.all(8),
                  
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
                                              _needsScroll = true;  // Set flag to scroll
                                            });
                                            _sendToLLMApi(_messageController.text);
                                            _messageController.clear();
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
