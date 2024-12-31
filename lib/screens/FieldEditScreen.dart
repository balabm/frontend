import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:formbot/providers/authprovider.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:formbot/screens/widgets/apirepository.dart';
import 'package:formbot/screens/widgets/audio_handler.dart';
import 'package:formbot/screens/widgets/bounding_box_overlay.dart';
import 'package:formbot/screens/widgets/chat_input.dart';
import 'package:formbot/screens/widgets/chat_section.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:formbot/screens/widgets/microphone_button.dart';
import 'package:formbot/screens/widgets/recording_indicator.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path; // Add this import


class FieldEditScreen extends StatefulWidget {
  const FieldEditScreen({super.key});
  @override
  _FieldEditScreenState createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> with AudioHandler {
  final _apiRepository = ApiRepository();
  final _messageController = TextEditingController();
  final _dragController = DraggableScrollableController();
  ScrollController _scrollController = ScrollController();
  late AuthProvider _authProvider;
  // New properties for tracking responses
  String? _pendingAsrResponse;
  Map<String, dynamic>? _pendingLlmResponse;
  var user;
  String? formId;

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
      _showBottomSheet = false,
      _isFieldLocked = false;
  // Add loading state
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
    initializeAudio();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _loadUserName();
  } 

  Future<void> _loadUserName() async {
    if (!mounted) return;
    final uid = _authProvider.user?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() => _userName = doc['userName'] ?? 'You');
    }
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
      enabled: !_isThinking, // Completely disable microphone button during processing
      isLongPressing: _isLongPressing,
      onLongPressStart: (_) {
        setState(() {
          _isLongPressing = true;
          _slidingOffset = 0; // Reset sliding offset when starting
        });
        startRecording();
      },
      onLongPressMoveUpdate: (details) {
        setState(() {
          _slidingOffset = details.offsetFromOrigin.dx;
          
          // Cancel recording if slid far enough to the left
          if (_slidingOffset < -50) {
            cancelRecording();
            _isLongPressing = false;
          }
        });
      },
      onLongPressEnd: (_) {
        // If not already canceled during slide
        if (_isLongPressing) {
          _slidingOffset < -50
              ? cancelRecording()
              : stopRecording().then((_) => _processAudioAndSendToLLM());
        }
        
        // Reset state
        setState(() {
          _slidingOffset = 0;
          _isLongPressing = false;
        });
      },
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

    setState(() {
      _inputEnabled = false;
    });

    final zipFile = File(await zipRecordedAudio());
    if (!await zipFile.exists()) {
      setState(() {
        _inputEnabled = true;
      });
      return;
    }

    final asrResponse = await _apiRepository.sendAudioToApi(zipFile);
    if (asrResponse == null) {
      setState(() {
        _inputEnabled = true;
      });
      return;
    }
    

    final asrData = jsonDecode(asrResponse);
    final transcribedText = asrData['dummy_text'] ?? 'No transcription available';

    setState(() {
      // Store ASR response temporarily
      _pendingAsrResponse = transcribedText;
      
      chatMessages.add({
        'sender': 'user',
        'message': 'Audio message • $transcribedText',
        'audioPath': recordedFilePath,
        'isAudioMessage': true,
      });
      _inputEnabled = true;
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
      _isFieldLocked = false;
      _inputEnabled = false;
    });

    final llmResponse = await _apiRepository.sendToLLMApi(
      _ocrText!,
      voiceQuery: isAudioQuery ? query : null,
    );

    setState(() {
      // Store LLM response temporarily
      _pendingLlmResponse = llmResponse;

      chatMessages.add({
        'sender': 'assistant',
        'message': llmResponse?['response'] ??
            'Failed to get response. Please try again.',
      });
      _needsScroll = true;
      _isThinking = false;
      _inputEnabled = true;
    });

    // Save responses to Firestore
    _saveResponsesToFirestore();
  }

Future<void> _saveResponsesToFirestore() async {
  final uid = _authProvider.user?.uid;
  if (uid == null) return;

  try {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);

    await firebaseProvider.saveFormWithDetails(
      uid: uid,
      imagePath: imagePath!, // doc ID will be derived from file name
      selectedField: _selectedFieldName ?? 'unnamed_field',
      ocrText: _ocrText ?? '',
      chatMessages: chatMessages,
      boundingBoxes: boundingBoxes ?? [],
    );

    // Reset pending responses
    _pendingAsrResponse = null;
    _pendingLlmResponse = null;

  } catch (e) {
    print('Error saving to Firestore: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving form data: $e')),
    );
  }
}

// Helper method to find last user input
String? _findLastUserInput() {
  for (var message in chatMessages.reversed) {
    if (message['sender'] == 'user') {
      return message['message'];
    }
  }
  return null;
}

// Add method to retrieve user's interaction history
Future<List<Map<String, dynamic>>> getInteractionHistory() async {
  final uid = _authProvider.user?.uid;
  if (uid == null) return [];

  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('interactions')
        .orderBy('timestamp', descending: true)
        .limit(50) // Adjust limit as needed
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();
  } catch (e) {
    print('Error fetching interaction history: $e');
    return [];
  }
}

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safely get arguments with null check
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null) {
      print('No arguments provided to FieldEditScreen');
      return;
    }

    // Parse arguments with type check
    if (args is Map<String, dynamic>) {
      imagePath = args['imagePath'];
      boundingBoxes = args['bounding_boxes'] ?? args['boundingBoxes']; // Try both possible keys
      formId = args['formId'];

      if (imagePath != null) {
        // Clean up filename to match database format
        final fileName = path.basename(imagePath!)
            .replaceAll('.', '_')
            .replaceAll('_png_png', '_png'); // Fix double extension
        print('Loading form data for: $fileName');
        _loadExistingFormData(fileName);
      } else {
        print('No imagePath provided in arguments');
      }
    } else {
      print('Invalid arguments type provided to FieldEditScreen');
    }
  }

  // Add method to convert base64 to audio file
  Future<String?> _base64ToAudioFile(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      print('Error converting base64 to audio: $e');
      return null;
    }
  }

  Future<void> _loadExistingFormData(String formId) async {
    setState(() => _isLoadingData = true);
    final uid = _authProvider.user?.uid;
    if (uid == null) {
      print('No user ID available');
      return;
    }

    try {
      print('Attempting to load form data for uid: $uid, formId: $formId');
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      final existingForm = await firebaseProvider.getFormWithInteractions(uid, formId);
      
      if (existingForm != null) {
        print('Found existing form data');
        if (mounted) {
          // Process messages and restore audio files
          final allInteractions = existingForm['interactions'] as List<dynamic>;
          chatMessages.clear();
          
          for (var interaction in allInteractions) {
            final messages = interaction['messages'] ?? [];
            for (var m in messages) {
              final messageData = Map<String, dynamic>.from(m);
              if (messageData['contentType'] == 'audio' && messageData['base64Audio'] != null) {
                // Convert base64 audio to file
                final audioPath = await _base64ToAudioFile(messageData['base64Audio']);
                if (audioPath != null) {
                  messageData['audioPath'] = audioPath;
                  messageData['isAudioMessage'] = true;
                }
              }
              chatMessages.add(messageData);
            }
          }

          setState(() {
            boundingBoxes = existingForm['boundingBoxes'] ?? [];
            final currentField = existingForm['currentSelectedField'] as Map<String, dynamic>?;
            if (currentField != null) {
              _selectedFieldName = currentField['name'];
              _ocrText = currentField['ocrText'];
            }
            
            print('Loaded ${chatMessages.length} messages');
            if (chatMessages.isNotEmpty) {
              _showBottomSheet = true;
              _inputEnabled = true;
            }
          });
        }
      } else {
        print('No existing form data found for formId: $formId');
      }
    } catch (e) {
      print('Error loading existing form data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _scrollToBottom() => setState(() {
        _needsScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _dragController.animateTo(
            0.6,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
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
    if (_isThinking) {
      return; // Prevent interaction while processing
    }

    if (_isFieldLocked) {
      setState(() {
        chatMessages.add({
          'sender': 'assistant',
          'message':
              'Please complete your queries for $_selectedFieldName first before selecting another field.',
        });
        _needsScroll = true;
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _inputEnabled = true;
      _selectedFieldName = box['class'];
      if (selectedBox != null) previouslySelectedBoxes.add(selectedBox!);
      selectedBox = box;
      _showBottomSheet = true;
      _isFieldLocked = true;
      _scrollToBottom();
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
        
        // This will ensure the instruction text shows "Ask/type a question" immediately after OCR
        _inputEnabled = true;
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

  Widget _buildInstructionBanner() {
    String instructionText;
    bool showCompletionBanner = false;

    if (_selectedFieldName == null) {
      // Initial state: No field selected
      instructionText = 'Select a field to begin';
    } else if (_ocrText == null) {
      // Field selected, waiting for OCR text
      instructionText = 'Reading text from $_selectedFieldName...';
    } else if (_ocrText != null && _inputEnabled && chatMessages.isEmpty) {
      // OCR text received, explicitly waiting for user input
      instructionText = 'Ask/type a question about $_selectedFieldName';
    } else if (!_isFieldLocked && !_isThinking && chatMessages.isNotEmpty) {
      // LLM response received, ready to go back
      instructionText = 'Tap here to go back';
      showCompletionBanner = true;
    } else if (_isThinking) {
      // Generic processing state
      instructionText = 'Processing...';
    } else {
      // Fallback state during chat interaction
      instructionText = 'Ask about $_selectedFieldName';
    }

    return GestureDetector(
      onTap: showCompletionBanner
          ? () {
              setState(() {
                selectedBox = null;
                _selectedFieldName = null;
                _inputEnabled = false;
                _showBottomSheet = false;
                _isFieldLocked = false;
                chatMessages.clear();
                _ocrText = null;
              });
              _minimizeDraggableSheet();
            }
          : null,
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 20.0,
          ),
          decoration: BoxDecoration(
            color: _isThinking
                ? Colors.orange[50]
                : showCompletionBanner
                    ? Colors.green[50]
                    : kPrimaryLightColor,
            borderRadius: BorderRadius.circular(8.0),
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
                  padding: const EdgeInsets.only(right: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  instructionText,
                  style: TextStyle(
                    color: _isThinking
                        ? Colors.orange[800]
                        : showCompletionBanner
                            ? Colors.green[800]
                            : kPrimaryDarkColor,
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (showCompletionBanner)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[600],
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    @override
    Widget build(BuildContext context) => Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: kPrimaryColor,
            elevation: 0,
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/camera');
                },
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: const Text(
                  'Upload Image',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            title: const Text(
              '',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: _isLoadingData
      ? const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        )
      : Stack(
            children: [
              Column(
                children: [
                  // Instruction Banner - Now directly under AppBar
                  
                  // Image Viewer
                  Expanded(
    child: FittedBox(
      fit: _showBottomSheet ? BoxFit.contain : BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 4.0,
        child: Stack(
          children: [
            if (imagePath != null)
              Center( 
                child: Image.file(
                  File(imagePath!),
                  fit: _showBottomSheet ? BoxFit.fitWidth : BoxFit.fitHeight,
                  width: _showBottomSheet
                      ? MediaQuery.of(context).size.width
                      : null,
                  height: _showBottomSheet
                      ? MediaQuery.of(context).size.height * 0.5
                      : MediaQuery.of(context).size.height,
                ),
              ),
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
  ),
                ],
              ),
              // Bottom Sheet
              if (_showBottomSheet)
                DraggableScrollableSheet(
  controller: _dragController,
  initialChildSize: 0.9,
  minChildSize: 0.4,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildInstructionBanner(),
          ),
          ChatInput(
            messageController: _messageController,
            
            inputEnabled: _inputEnabled && !_isThinking, // Disable if processing
            isRecording: isRecording,
            dragController: _dragController,
            recordingIndicator: _buildRecordingIndicator(),
            microphoneButton: _messageController.text.isEmpty && !_isThinking
    ? _buildMicrophoneButton()
    : null,
            onSendPressed: () {
              if (!_inputEnabled) return; 
              FocusScope.of(context).unfocus();
              if (_messageController.text.isEmpty) return;
              if (_ocrText?.isEmpty ?? true) {
                Common.showErrorMessage(context, "Please select a field");
                return;
              }
              setState(() {
                chatMessages.add({
                  'sender': 'user',
                  'message': _messageController.text,
                  'inputType': 'text'
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
)
            ],
          ),
        );
}
