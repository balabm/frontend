import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:formbot/helpers/database_helper.dart';
import 'package:formbot/screens/widgets/chat_input.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'widgets/index.dart';
import 'widgets/audio_handler.dart';
import 'widgets/apirepository.dart';
import 'widgets/common.dart';

class FieldEditScreen extends StatefulWidget {
  const FieldEditScreen({super.key});
  @override
  _FieldEditScreenState createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> with AudioHandler {
  final _apiRepository = ApiRepository();
  final _dbHelper = DatabaseHelper();
  final _messageController = TextEditingController();
  final _dragController = DraggableScrollableController();
  late ScrollController _scrollController;

  String? imagePath, _selectedFieldName, _ocrText;
  List<dynamic>? boundingBoxes;
  List<Map<String, dynamic>> chatMessages = [];
  Map<String, dynamic>? selectedBox;
  Set<Map<String, dynamic>> previouslySelectedBoxes = {};
  String _userName = 'You';
  double _slidingOffset = 0;
  bool _inputEnabled = false,
      _isLongPressing = false,
      _needsScroll = false,
      _isThinking = false;

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
    initializeAudio();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('userName') ?? 'You');
  }

  @override
  void dispose() {
    disposeAudio();
    _messageController.dispose();
    _scrollController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  void _performScroll() {
    if (_needsScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
      _needsScroll = false;
    }
  }

  @override
  void didUpdateWidget(covariant FieldEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _performScroll());
  }

  Widget _buildMicrophoneButton() => MicrophoneButton(
        isLongPressing: _isLongPressing,
        onLongPressStart: (_) {
          setState(() => _isLongPressing = true);
          startRecording();
        },
        onLongPressMoveUpdate: (details) =>
            setState(() => _slidingOffset = details.offsetFromOrigin.dx),
        onLongPressEnd: (_) => _slidingOffset < -50
            ? cancelRecording()
            : stopRecording().then((_) => _processAudioAndSendToLLM()),
      );

  Widget _buildRecordingIndicator() => !isRecording
      ? const SizedBox.shrink()
      : RecordingIndicator(
          recordingDuration: recordingDuration,
          slidingOffset: _slidingOffset,
          formatDuration: formatDuration,
        );

  Future<void> _processAudioAndSendToLLM() async {
    if (_ocrText?.isEmpty ?? true) {
      setState(() {
        chatMessages.add({
          'sender': 'assistant',
          'message': 'Please select a field to extract text first.',
        });
        _needsScroll = true;
      });
      return;
    }

    final zipFile = File(await zipRecordedAudio());
    if (!await zipFile.exists()) return;

    final asrResponse = await _apiRepository.sendAudioToApi(zipFile);
    if (asrResponse == null) return;

    final asrData = jsonDecode(asrResponse);
    final transcribedText =
        asrData['dummy_text'] ?? 'No transcription available';

    setState(() {
      chatMessages.add({
        'sender': 'user',
        'message': 'Audio message • $transcribedText',
        'audioPath': recordedFilePath,
        'isAudioMessage': true,
      });
    });

    _scrollToBottom();
    await _sendToLLMApi(asrResponse, isAudioQuery: true);
  }

  Future<void> _sendToLLMApi(String query, {bool isAudioQuery = false}) async {
    if (_ocrText?.isEmpty ?? true) {
      setState(() {
        chatMessages.add({
          'sender': 'assistant',
          'message': 'Please select a field to extract text first.',
        });
        _needsScroll = true;
      });
      return;
    }

    setState(() {
      _needsScroll = true;
      _isThinking = true;
    });

    final llmResponse = await _apiRepository.sendToLLMApi(
      _ocrText!,
      voiceQuery: isAudioQuery ? query : null,
    );

    if (llmResponse != null) {
      _dbHelper.saveLlmResponse(jsonEncode(llmResponse));
    }

    setState(() {
      chatMessages.add({
        'sender': 'assistant',
        'message': llmResponse?['response'] ??
            'Failed to get response. Please try again.',
      });
      _needsScroll = true;
      _isThinking = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    imagePath = args['imagePath'];
    boundingBoxes = args['bounding_boxes'];
    chatMessages.add(
        {'sender': 'assistant', 'message': 'Please select a field to edit.'});
  }

  void _scrollToBottom() => setState(() {
        _needsScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });

  void _onBoundingBoxTap(Map<String, dynamic> box) {
    setState(() {
      _inputEnabled = true;
      _selectedFieldName = box['class'];
      if (selectedBox != null) previouslySelectedBoxes.add(selectedBox!);
      selectedBox = box;
    });
    _sendDataToApi(box);
  }

  Future<void> _sendDataToApi(Map<String, dynamic> box) async {
    setState(() {
      _needsScroll = true;
      _isThinking = true;
    });

    final ocrResponse = await _apiRepository.sendOCRRequest(
      imagePath: imagePath!,
      box: box,
    );

    if (ocrResponse != null) {
      Provider.of<ApiResponseProvider>(context, listen: false)
          .setOcrResponse(jsonEncode(ocrResponse));
      _ocrText = ocrResponse['extracted_text'];

      setState(() {
        chatMessages.add({
          'sender': 'assistant',
          'message':
              'Field ${box['class']} selected. The detected text is: $_ocrText',
        });
        _isThinking = false;
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.teal,
          elevation: 0,
        ),
        body: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    if (imagePath != null)
                      Center(
                          child:
                              Image.file(File(imagePath!), fit: BoxFit.cover)),
                    if (boundingBoxes != null)
                      BoundingBoxOverlay(
                        imagePath: imagePath!,
                        boundingBoxes: boundingBoxes!,
                        selectedBox: selectedBox,
                        previouslySelectedBoxes: previouslySelectedBoxes,
                        onBoundingBoxTap: _onBoundingBoxTap,
                      ),
                  ],
                ),
              ),
            ),
            DraggableScrollableSheet(
              controller: _dragController,
              initialChildSize: 0.3,
              minChildSize: 0.3,
              maxChildSize: 1,
              builder: (context, scrollController) {
                _scrollController = scrollController;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _performScroll());
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      Expanded(
                        child: ChatSection(
                          scrollController: scrollController,
                          chatMessages: chatMessages,
                          isThinking: _isThinking,
                          userName: _userName,
                          onPlayAudio: playAudio,
                        ),
                      ),
                      ChatInput(
                        messageController: _messageController,
                        inputEnabled: _inputEnabled,
                        isRecording: isRecording,
                        dragController: _dragController,
                        recordingIndicator: _buildRecordingIndicator(),
                        microphoneButton: _buildMicrophoneButton(),
                        onSendPressed: () {
                          if (_messageController.text.isEmpty) return;
                          if (_ocrText?.isEmpty ?? true) {
                            Common.showErrorMessage(
                                context, "Please select a field");
                            return;
                          }
                          setState(() {
                            chatMessages.add({
                              'sender': 'user',
                              'message': _messageController.text,
                            });
                            _needsScroll = true;
                          });
                          _sendToLLMApi(_messageController.text);
                          _messageController.clear();
                        },
                        slidingOffset: _slidingOffset,
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
