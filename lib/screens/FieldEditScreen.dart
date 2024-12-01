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
      _isThinking = false,
      _showBottomSheet = false;

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
    // chatMessages.add(
    //     {'sender': 'assistant', 'message': 'Please select a field to edit.'});
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
      _showBottomSheet = true;
    });
    _sendDataToApi(box);
    _maximizeDraggableSheet();
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

  void _maximizeDraggableSheet() {
    _dragController.animateTo(
      0.6,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _minimizeDraggableSheet() {
    _dragController.animateTo(
      0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildCompletionBanner() {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBox = null;
          _selectedFieldName = null;
          _inputEnabled = false;
          _showBottomSheet = false;
        });
        _minimizeDraggableSheet();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: kPrimaryLightColor,
          border: Border(
            top: BorderSide(
              color: kPrimaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: kPrimaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap here to complete queries for $_selectedFieldName and select another field',
                style: const TextStyle(
                  color: kPrimaryDarkColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: kPrimaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _getInstructionText() {
    if (_isThinking) {
      return 'Processing...';
    } else if (_ocrText?.isEmpty ?? true) {
      return 'Type in your query for $_selectedFieldName or use voice.';
    } else if (_selectedFieldName != null) {
      return 'Type in your query for $_selectedFieldName or use voice.';
    } else {
      return 'Please select a field to edit.';
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: kPrimaryColor,
          elevation: 0,
          title: const Text(
            '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Instruction Banner - Now directly under AppBar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: _isThinking ? Colors.orange[50] : kPrimaryLightColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isThinking)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kPrimaryColor,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _getInstructionText(),
                          style: TextStyle(
                            color: _isThinking
                                ? Colors.orange[800]
                                : kPrimaryDarkColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Image Viewer
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.fitHeight,
                    alignment: Alignment.center,
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Stack(
                        children: [
                          if (imagePath != null)
                            Center(
                                child: Image.file(File(imagePath!),
                                    fit: BoxFit.contain)),
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
                )
              ],
            ),
            // Bottom Sheet
            if (_showBottomSheet)
              DraggableScrollableSheet(
                controller: _dragController,
                initialChildSize: 0.9,
                minChildSize: 0.9,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  _scrollController = scrollController;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, -2),
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
                        if (_selectedFieldName != null)
                          _buildCompletionBanner(),
                        ChatInput(
                          messageController: _messageController,
                          inputEnabled: _inputEnabled,
                          isRecording: isRecording,
                          dragController: _dragController,
                          recordingIndicator: _buildRecordingIndicator(),
                          microphoneButton:
                              !isRecording && _messageController.text.isEmpty
                                  ? _buildMicrophoneButton()
                                  : null,
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
