// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:formbot/providers/authprovider.dart';
// import 'package:formbot/providers/firebaseprovider.dart';
// import 'package:formbot/screens/widgets/apirepository.dart';
// import 'package:formbot/screens/widgets/audio_handler.dart';
// import 'package:formbot/screens/widgets/bounding_box_overlay.dart';
// import 'package:formbot/screens/widgets/chat_input.dart';
// import 'package:formbot/screens/widgets/chat_section.dart';
// import 'package:formbot/screens/widgets/common.dart';
// import 'package:formbot/screens/widgets/microphone_button.dart';
// import 'package:formbot/screens/widgets/recording_indicator.dart';
// import 'package:provider/provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'dart:convert';
// import 'package:path/path.dart' as path; // Add this import


// class FieldEditScreen extends StatefulWidget {
//   const FieldEditScreen({super.key});
//   @override
//   _FieldEditScreenState createState() => _FieldEditScreenState();
// }

// class _FieldEditScreenState extends State<FieldEditScreen> with AudioHandler {
//   final _apiRepository = ApiRepository();
//   final _messageController = TextEditingController();
//   final _dragController = DraggableScrollableController();
//   ScrollController _scrollController = ScrollController();
//   late AuthProvider _authProvider;
//   // New properties for tracking responses
//   String? _pendingAsrResponse;
//   Map<String, dynamic>? _pendingLlmResponse;
//   var user;
//   String? formId;
//   String? selectedForm; //line to store the selected form

//   String? imagePath, _selectedFieldName, _ocrText;
//   List<dynamic>? boundingBoxes;
//   List<Map<String, dynamic>> chatMessages = [];
//   Map<String, dynamic>? selectedBox;
//   Set<Map<String, dynamic>> previouslySelectedBoxes = {};
//   String _userName = 'You';
//   double _slidingOffset = 0;
//   bool _inputEnabled = false,
//       _isLongPressing = false,
//       _needsScroll = false,
//       _isThinking = false,
//       _showBottomSheet = false,
//       _isFieldLocked = false;
//   // Add loading state
//   bool _isLoadingData = true;

//   @override
//   void initState() {
//     super.initState();
//     Permission.microphone.request();
//     initializeAudio();
//     _authProvider = Provider.of<AuthProvider>(context, listen: false);
//     _loadUserName();

//   } 

//   Future<void> _loadUserName() async {
//     if (!mounted) return;
//     final uid = _authProvider.user?.uid;
//     if (uid != null) {
//       final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
//       setState(() => _userName = doc['userName'] ?? 'You');
//     }
//   }

//   @override
//   void dispose() {
//     disposeAudio();
//     _messageController.dispose();
//     _scrollController.dispose();
//     _dragController.dispose();
//     super.dispose();
//   }

//   void _performScroll() {
//     if (_needsScroll && _scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.decelerate,
//       );
//       _needsScroll = false;
//     }
//   }

//   @override
//   void didUpdateWidget(covariant FieldEditScreen oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     WidgetsBinding.instance.addPostFrameCallback((_) => _performScroll());
//   }

//   Widget _buildMicrophoneButton() => MicrophoneButton(
//       enabled: !_isThinking , // Completely disable microphone button during processing
//       isLongPressing: _isLongPressing,
//       onLongPressStart: (_) {
        
//         setState(() {
//           _isLongPressing = true;
//           _slidingOffset = 0; // Reset sliding offset when starting
//         });
//         startRecording();
//       },
//       onLongPressMoveUpdate: (details) {
//         setState(() {
//           _slidingOffset = details.offsetFromOrigin.dx;
          
//           // Cancel recording if slid far enough to the left
//           if (_slidingOffset < -50) {
//             cancelRecording();
//             _isLongPressing = false;
//           }
//         });
//       },
//       onLongPressEnd: (_) {
//         // If not already canceled during slide
//         if (_isLongPressing) {
//           _slidingOffset < -50
//               ? cancelRecording()
//               : stopRecording().then((_) => _processAudioAndSendToLLM());
//         }
        
//         // Reset state
//         setState(() {
//           _slidingOffset = 0;
//           _isLongPressing = false;
//         });
//       },
//     );
      
//   Widget _buildRecordingIndicator() => !isRecording
//       ? const SizedBox.shrink()
//       : RecordingIndicator(
//           recordingDuration: recordingDuration,
//           slidingOffset: _slidingOffset,
//           formatDuration: formatDuration,
//         );

//   Future<void> _processAudioAndSendToLLM() async {
//     if (_ocrText?.isEmpty ?? true) {
//       setState(() {
//         chatMessages.add({
//           'sender': 'assistant',
//           'message': 'Please select a field to extract text first.',
//         });
//         _needsScroll = true;
//       });
//       return;
//     }

//     setState(() {
//       _inputEnabled = false;
//     });

//     final zipFile = File(await zipRecordedAudio());
//     if (!await zipFile.exists()) {
//       setState(() {
//         _inputEnabled = true;
//       });
//       return;
//     }

//     final asrResponse = await _apiRepository.sendAudioToApi(zipFile);
//     if (asrResponse == null) {
//       setState(() {
//         _inputEnabled = true;
//       });
//       return;
//     }
    

//     final asrData = jsonDecode(asrResponse);
//     final transcribedText = asrData['dummy_text'] ?? 'No transcription available';

//     setState(() {
//       // Store ASR response temporarily
//       _pendingAsrResponse = transcribedText;
      
//       chatMessages.add({
//         'sender': 'user',
//         'message': 'Audio message • $transcribedText',
//         'audioPath': recordedFilePath,
//         'asrResponse': transcribedText,
//         'isAudioMessage': true,
//       });
        
//         _needsScroll = true;
//       _inputEnabled = true;
//     });

//     _scrollToBottom();
//     await _sendToLLMApi(asrResponse, isAudioQuery: true);
//   }

  

//   Future<void> _sendToLLMApi(String query, {bool isAudioQuery = false}) async {
//     if (_ocrText?.isEmpty ?? true) {
//       setState(() {
//         chatMessages.add({
//           'sender': 'assistant',
//           'message': 'Please select a field to extract text first.',
//         });
//         _needsScroll = true;
        
//         _scrollToBottom();
//       });
//       return;
//     }

//     setState(() {
//       _needsScroll = true;
//       _isThinking = true;
//       _isFieldLocked = false;
//       _inputEnabled = false;
//     });

//     print('Sending to LLM API with scheme_name: $selectedForm');

//     final llmResponse = await _apiRepository.sendToLLMApi(
//       _ocrText!,
//       selectedForm ?? 'Unknown Scheme', // Pass the selected form as scheme_name
//       voiceQuery: isAudioQuery ? query : null,
//     );

//     setState(() {
//       // Store LLM response temporarily
//       _pendingLlmResponse = llmResponse;

//       chatMessages.add({
//         'sender': 'assistant',
//         'message': llmResponse?['response'] ??
//             'Failed to get response. Please try again.',
//       });
//       _needsScroll = true;
//       _isThinking = false;
//       _inputEnabled = true;
//         _scrollToBottom();
//     });
//     // Save responses to Firestore
//     _saveResponsesToFirestore();
//   }

//   // Future<void> _sendToLLMApi(String query, {bool isAudioQuery = false}) async {
//   //   if (_ocrText?.isEmpty ?? true) {
//   //     setState(() {
//   //       chatMessages.add({
//   //         'sender': 'assistant',
//   //         'message': 'Please select a field to extract text first.',
//   //       });
//   //       _needsScroll = true;
        
//   //       _scrollToBottom();
//   //     });
//   //     return;
//   //   }

//   //   setState(() {
//   //     _needsScroll = true;
//   //     _isThinking = true;
//   //     _isFieldLocked = false;
//   //     _inputEnabled = false;
//   //   });

//   //   final llmResponse = await _apiRepository.sendToLLMApi(
//   //     _ocrText!,
//   //     voiceQuery: isAudioQuery ? query : null,
//   //   );

//   //   setState(() {
//   //     // Store LLM response temporarily
//   //     _pendingLlmResponse = llmResponse;

//   //     chatMessages.add({
//   //       'sender': 'assistant',
//   //       'message': llmResponse?['response'] ??
//   //           'Failed to get response. Please try again.',
//   //     });
//   //     _needsScroll = true;
//   //     _isThinking = false;
//   //     _inputEnabled = true;
//   //       _scrollToBottom();
//   //   });
//   //   // Save responses to Firestore
//   //   _saveResponsesToFirestore();
//   // }

// Future<void> _saveResponsesToFirestore() async {
//   final uid = _authProvider.user?.uid;
//   if (uid == null) return;

//   try {
//     final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);

//     await firebaseProvider.saveFormWithDetails(
//       uid: uid,
//       imagePath: imagePath!, // doc ID will be derived from file name
//       selectedField: _selectedFieldName ?? 'unnamed_field',
//       ocrText: _ocrText ?? '',
//       chatMessages: chatMessages,
//       boundingBoxes: boundingBoxes ?? [],
//     );

//     // Reset pending responses
//     _pendingAsrResponse = null;
//     _pendingLlmResponse = null;

//   } catch (e) {
//     print('Error saving to Firestore: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error saving form data: $e')),
//     );
//   }
// }

// // Helper method to find last user input
// String? _findLastUserInput() {
//   for (var message in chatMessages.reversed) {
//     if (message['sender'] == 'user') {
//       return message['message'];
//     }
//   }
//   return null;
// }

// // Add method to retrieve user's interaction history
// Future<List<Map<String, dynamic>>> getInteractionHistory() async {
//   final uid = _authProvider.user?.uid;
//   if (uid == null) return [];

//   try {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('interactions')
//         .orderBy('timestamp', descending: true)
//         .limit(50) // Adjust limit as needed
//         .get();

//     return querySnapshot.docs
//         .map((doc) => {
//               'id': doc.id,
//               ...doc.data(),
//             })
//         .toList();
//   } catch (e) {
//     print('Error fetching interaction history: $e');
//     return [];
//   }
// }

// bool isloaded = false;

  
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (!isloaded) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args == null) {
//         print('No arguments provided to FieldEditScreen');
//         return;
//       }

//       if (args is Map<String, dynamic>) {
//         print('Arguments passed to FieldEditScreen: $args');
//         imagePath = args['imagePath'];
//         boundingBoxes = args['bounding_boxes'] ?? args['boundingBoxes'];
//         formId = args['formId'];
//         selectedForm = args['selectedForm']; // Retrieve the selected form
      
//         if (imagePath != null) {
//           final fileName = path.basename(imagePath!)
//               .replaceAll('.', '_')
//               .replaceAll('_png_png', '_png');
//           print('Loading form data for: $fileName');
//           _loadExistingFormData(fileName);
//         } else {
//           print('No imagePath provided in arguments');
//         }
//       } else {
//         print('Invalid arguments type provided to FieldEditScreen');
//       }
//       isloaded = true;
//     }
//   }


//   // Add method to convert base64 to audio file
//   Future<String?> _base64ToAudioFile(String base64Audio) async {
//     try {
//       final bytes = base64Decode(base64Audio);
//       final tempDir = await getTemporaryDirectory();
//       final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.wav');
//       await file.writeAsBytes(bytes);
//       return file.path;
//     } catch (e) {
//       print('Error converting base64 to audio: $e');
//       return null;
//     }
//   }

//   Future<void> _loadExistingFormData(String formId) async {
//     setState(() => _isLoadingData = true);
//     final uid = _authProvider.user?.uid;
//     if (uid == null) {
//       print('No user ID available');
//       return;
//     }

//     try {
//       print('Attempting to load form data for uid: $uid, formId: $formId');
//       final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
//       final existingForm = await firebaseProvider.getFormWithInteractions(uid, formId);
      
//       if (existingForm != null) {
//         print('Found existing form data');
//         if (mounted) {
//           // Process messages and restore audio files
//           final allInteractions = existingForm['interactions'] as List<dynamic>;
//           chatMessages.clear();
          
//           for (var interaction in allInteractions) {
//             final messages = interaction['messages'] ?? [];
//             for (var m in messages) {
//               final messageData = Map<String, dynamic>.from(m);
//               if (messageData['contentType'] == 'audio' && messageData['base64Audio'] != null) {
//                 // Convert base64 audio to file
//                 final audioPath = await _base64ToAudioFile(messageData['base64Audio']);
//                 if (audioPath != null) {
//                   messageData['audioPath'] = audioPath;
//                   messageData['isAudioMessage'] = true;
//                 }
//               }
//               chatMessages.add(messageData);
//             }
//           }

//           setState(() {
//             boundingBoxes = existingForm['boundingBoxes'] ?? [];
//             final currentField = existingForm['currentSelectedField'] as Map<String, dynamic>?;
//             if (currentField != null) {
//               _selectedFieldName = currentField['name'];
//               _ocrText = currentField['ocrText'];
//             }
            
//             print('Loaded ${chatMessages.length} messages');
//             if (chatMessages.isNotEmpty) {
//               _showBottomSheet = true;
//               _inputEnabled = true;
//             }
//           });
//         }
//       } else {
//         print('No existing form data found for formId: $formId');
//       }
//     } catch (e) {
//       print('Error loading existing form data: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isLoadingData = false);
//       }
//     }
//   }

//   void _scrollToBottom() => setState(() {
//         _needsScroll = true;
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _dragController.animateTo(
//             0.6,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeOut,
//           );
//           if (_scrollController.hasClients) {
//             _scrollController.animateTo(
//               _scrollController.position.maxScrollExtent,
//               duration: const Duration(milliseconds: 300),
//               curve: Curves.easeOut,
//             );
//           }
//         });
//       });

//   void _onBoundingBoxTap(Map<String, dynamic> box) {
//     if (_isThinking) {
//       return; // Prevent interaction while processing
//     }

//     if (_isFieldLocked) {
//       setState(() {
//         chatMessages.add({
//           'sender': 'assistant',
//           'message':
//               //'Please complete your queries for $_selectedFieldName first before selecting another field.',
//               'Please complete your queries before selecting another field.'
//         });
//         _needsScroll = true;
//       });
//       _scrollToBottom();
//       return;
//     }

//     setState(() {
//       _inputEnabled = true;
//       _selectedFieldName = box['class'];
//       if (selectedBox != null) previouslySelectedBoxes.add(selectedBox!);
//       selectedBox = box;
//       _showBottomSheet = true;
//       _isFieldLocked = true;
//       _scrollToBottom();
//     });
//     _sendDataToApi(box);
//     _maximizeDraggableSheet();
//   }

//   Future<void> _sendDataToApi(Map<String, dynamic> box) async {
//     setState(() {
//       _needsScroll = true;
//       _isThinking = true;
//     });

//     final ocrResponse = await _apiRepository.sendOCRRequest(
//       imagePath: imagePath!,
//       box: box,
//     );

//     if (ocrResponse != null) {
//       Provider.of<ApiResponseProvider>(context, listen: false)
//           .setOcrResponse(jsonEncode(ocrResponse));
//       _ocrText = ocrResponse['extracted_text'];

//       setState(() {
//         chatMessages.add({
//           'sender': 'assistant',
//           'message':
//               //'Field ${box['class']} selected. The detected text is: $_ocrText',
//               '$_ocrText',
//         });
//         _isThinking = false;
//         _needsScroll = true;
//         _scrollToBottom();
        
//         // This will ensure the instruction text shows "Ask/type a question" immediately after OCR
//         _inputEnabled = true;
//       });
//     }
//   }

//   void _maximizeDraggableSheet() {
//     _dragController.animateTo(
//       0.6,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//     );
//   }

//   void _minimizeDraggableSheet() {
//     _dragController.animateTo(
//       0.3,
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeOut,
//     );
//   }
// Widget _buildInstructionBanner() {
//   String instructionText;
//   bool showCompletionBanner = false;
//   IconData? leadingIcon;

//   if (_selectedFieldName == null) {
//     instructionText = 'Tap to select a field';
//     //leadingIcon = Icons.touch_app;
//   } else if (_ocrText == null) {
//     instructionText = 'Scanning $_selectedFieldName...';
//     //leadingIcon = Icons.scanner;
//   } else if (_ocrText != null && _inputEnabled && chatMessages.isEmpty) {
//     instructionText = 'Tap to ask or type a question';
//     //leadingIcon = Icons.question_answer;
//   } else if (!_isFieldLocked && !_isThinking && chatMessages.isNotEmpty) {
//     instructionText = 'Tap to select another field';
//     showCompletionBanner = true;
//     //leadingIcon = Icons.arrow_back;
//   } else if (_isThinking) {
//     instructionText = 'Analyzing content...';
//     //leadingIcon = Icons.psychology;
//   } else {
//     instructionText = 'Ask about selected field';
//     //leadingIcon = Icons.chat;
//   }

//   return TweenAnimationBuilder<double>(
//     tween: Tween(begin: 0.95, end: 1.0),
//     duration: const Duration(milliseconds: 200),
//     builder: (context, value, child) {
//       return Transform.scale(
//         scale: value,
//         child: child,
//       );
//     },
//     child: GestureDetector(
//       onTap: showCompletionBanner
//           ? () {
//               _minimizeDraggableSheet();
//             }
//           : null,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border(
//             top: BorderSide(
//               color: _isThinking
//                   ? Colors.amber.shade200
//                   : showCompletionBanner
//                       ? Colors.teal.shade200
//                       : Colors.blue.shade100,
//               width: 1.5,
//             ),
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (leadingIcon != null)
//               TweenAnimationBuilder(
//                 tween: Tween(begin: 0.0, end: 1.0),
//                 duration: const Duration(milliseconds: 400),
//                 builder: (context, value, child) {
//                   return Opacity(
//                     opacity: value,
//                     child: Transform.scale(
//                       scale: value,
//                       child: child,
//                     ),
//                   );
//                 },
//                 child: Icon(
//                   leadingIcon,
//                   color: _isThinking
//                       ? Colors.amber.shade700
//                       : showCompletionBanner
//                           ? Colors.teal.shade700
//                           : Colors.black,
//                   size: 24,
//                 ),
//               ),
//             if (leadingIcon != null) const SizedBox(width: 12),
//             Flexible(
//               child: AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 300),
//                 child: Text(
//                   instructionText,
//                   key: ValueKey(instructionText),
//                   style: TextStyle(
//                     color: _isThinking
//                         ? Colors.amber.shade800
//                         : showCompletionBanner
//                             ? Colors.teal.shade800
//                             : Colors.black,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: -0.2,
//                     height: 1.4,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//             if (_isThinking)
//               Padding(
//                 padding: const EdgeInsets.only(left: 12),
//                 child: SizedBox(
//                   width: 24,
//                   height: 24,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2.5,
//                     color: Colors.amber.shade700,
//                   ),
//                 ),
//               ),
//             // if (showCompletionBanner)
//             //   Padding(
//             //     padding: const EdgeInsets.only(left: 12),
//             //     child: Icon(
//             //       Icons.check_circle,
//             //       color: Colors.teal.shade700,
//             //       size: 24,
//             //     ),
//             //   ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

//     @override
//     Widget build(BuildContext context) => Scaffold(
//           appBar: AppBar(
//             iconTheme: const IconThemeData(color: Colors.white),
//             backgroundColor: kPrimaryColor,
//             elevation: 0,
//             actions: [
//               TextButton.icon(
//                 onPressed: () {
//                   Navigator.pushNamed(context, '/camera');
//                 },
//                 icon: const Icon(Icons.camera_alt, color: Colors.white),
//                 label: const Text(
//                   'Upload Image',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ],
//             title: const Text(
//               '',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           body: _isLoadingData
//       ? const Center(
//           child: CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
//           ),
//         )
//       : Stack(
//             children: [
//               Column(
//                 children: [
//                   // Instruction Banner - Now directly under AppBar
                  
//                   // Image Viewer
//                   Expanded(
//     child: FittedBox(
//       fit: _showBottomSheet ? BoxFit.contain : BoxFit.fitWidth,
//       alignment: Alignment.topCenter,
//       child: InteractiveViewer(
//         panEnabled: true,
//         minScale: 0.5,
//         maxScale: 4.0,
//         child: Stack(
//           children: [
//             if (imagePath != null)
//               Center( 
//                 child: Image.file(
//                   File(imagePath!),
//                   fit: _showBottomSheet ? BoxFit.fitWidth : BoxFit.fitHeight,
//                   width: _showBottomSheet
//                       ? MediaQuery.of(context).size.width
//                       : null,
//                   height: _showBottomSheet
//                       ? MediaQuery.of(context).size.height * 0.5
//                       : MediaQuery.of(context).size.height,
//                 ),
//               ),
//             if (boundingBoxes != null)
//               BoundingBoxOverlay(
//                 imagePath: imagePath!,
//                 boundingBoxes: boundingBoxes!,
//                 selectedBox: selectedBox,
//                 previouslySelectedBoxes: previouslySelectedBoxes,
//                 onBoundingBoxTap: _onBoundingBoxTap,
//               ),
//           ],
//         ),
//       ),
//     ),
//   ),
//                 ],
//               ),
//               // Bottom Sheet
//               if (_showBottomSheet)
//                 DraggableScrollableSheet(
//   controller: _dragController,
//   initialChildSize: 0.9,
//   minChildSize: 0.4,
//   maxChildSize: 0.9,
//   builder: (context, scrollController) {
//     _scrollController = scrollController;
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             spreadRadius: 0,
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
         
//           Container(
//             width: 40,
//             height: 5,
//             margin: const EdgeInsets.symmetric(vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2.5),
//             ),
//           ),
          
//           Expanded(
//             child: ChatSection(
//               scrollController: scrollController,
//               chatMessages: chatMessages,
//               isThinking: _isThinking,
//               userName: _userName,
//               onPlayAudio: playAudio,
//             ),
//           ),
//            Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: _buildInstructionBanner(),
//           ),
//           ChatInput(
//             messageController: _messageController,
            
//             inputEnabled: _inputEnabled && !_isThinking, // Disable if processing
//             isRecording: isRecording,
//             dragController: _dragController,
//             recordingIndicator: _buildRecordingIndicator(),
//             microphoneButton: _messageController.text.isEmpty && !_isThinking
//     ? _buildMicrophoneButton()
//     : null,
//             onSendPressed: () {
//               if (!_inputEnabled) return; 
//               FocusScope.of(context).unfocus();
//               if (_messageController.text.isEmpty) return;
//               if (_ocrText?.isEmpty ?? true) {
//                 Common.showErrorMessage(context, "Please select a field");
//                 return;
//               }
//               setState(() {
//                 chatMessages.add({
//                   'sender': 'user',
//                   'message': _messageController.text,
//                   'inputType': 'text'
//                 });
//                 _needsScroll = true;
//               });
//                _sendToLLMApi(_messageController.text);
//   _messageController.clear();
  
  
// },
//             slidingOffset: _slidingOffset,
//           ),
//         ],
//       ),
//     );
//   },
// )
//             ],
//           ),
//         );
// }


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
import 'package:image/image.dart' as img; // Add this import


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
  String? selectedForm; //line to store the selected form

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
      enabled: !_isThinking , // Completely disable microphone button during processing
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
          isLongPressing: _isLongPressing, // Pass the isLongPressing parameter
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
        'asrResponse': transcribedText,
        'isAudioMessage': true,
      });
        
        _needsScroll = true;
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
        
        _scrollToBottom();
      });
      return;
    }

    setState(() {
      _needsScroll = true;
      _isThinking = true;
      _isFieldLocked = false;
      _inputEnabled = false;
    });

    print('Sending to LLM API with scheme_name: $selectedForm');

    final llmResponse = await _apiRepository.sendToLLMApi(
      _ocrText!,
      selectedForm ?? 'Unknown Scheme', // Pass the selected form as scheme_name
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
        _scrollToBottom();
    });
    // Save responses to Firestore
    _saveResponsesToFirestore();
  }

  // Future<void> _sendToLLMApi(String query, {bool isAudioQuery = false}) async {
  //   if (_ocrText?.isEmpty ?? true) {
  //     setState(() {
  //       chatMessages.add({
  //         'sender': 'assistant',
  //         'message': 'Please select a field to extract text first.',
  //       });
  //       _needsScroll = true;
        
  //       _scrollToBottom();
  //     });
  //     return;
  //   }

  //   setState(() {
  //     _needsScroll = true;
  //     _isThinking = true;
  //     _isFieldLocked = false;
  //     _inputEnabled = false;
  //   });

  //   final llmResponse = await _apiRepository.sendToLLMApi(
  //     _ocrText!,
  //     voiceQuery: isAudioQuery ? query : null,
  //   );

  //   setState(() {
  //     // Store LLM response temporarily
  //     _pendingLlmResponse = llmResponse;

  //     chatMessages.add({
  //       'sender': 'assistant',
  //       'message': llmResponse?['response'] ??
  //           'Failed to get response. Please try again.',
  //     });
  //     _needsScroll = true;
  //     _isThinking = false;
  //     _inputEnabled = true;
  //       _scrollToBottom();
  //   });
  //   // Save responses to Firestore
  //   _saveResponsesToFirestore();
  // }

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

bool isloaded = false;

  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ModalRoute.of(context)?.addScopedWillPopCallback(_onWillPop);

    if (!isloaded) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        print('No arguments provided to FieldEditScreen');
        return;
      }

      if (args is Map<String, dynamic>) {
        print('Arguments passed to FieldEditScreen: $args');
        imagePath = args['imagePath'];
        boundingBoxes = args['bounding_boxes'] ?? args['boundingBoxes'];
        formId = args['formId'];
        selectedForm = args['selectedForm']; // Retrieve the selected form
      
        if (imagePath != null) {
          final fileName = path.basename(imagePath!)
              .replaceAll('.', '_')
              .replaceAll('_png_png', '_png');
          print('Loading form data for: $fileName');
          _loadExistingFormData(fileName);
        } else {
          print('No imagePath provided in arguments');
        }
      } else {
        print('Invalid arguments type provided to FieldEditScreen');
      }
      isloaded = true;
    }
  }

//   //to override back button
//   Future<bool> _onWillPop() async {
//   // Navigate to the form selection page
//   Navigator.pushNamed(context, '/form_selection');
//   return false; // Returning false prevents the default pop behavior
// }

  Future<bool> _onWillPop() async {
    // Navigate to the form selection page
    Navigator.pushNamed(context, '/form_selection');
    return false; // Returning false prevents the default pop behavior
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
              //'Please complete your queries for $_selectedFieldName first before selecting another field.',
              'Please complete your queries before selecting another field.'
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


Future<File> _cropImage(String imagePath, Map<String, dynamic> box) async {
    final imageFile = File(imagePath);
    final image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final x = (box['x_center'] - box['width'] / 2).toInt();
    final y = (box['y_center'] - box['height'] / 2).toInt();
    final width = box['width'].toInt();
    final height = box['height'].toInt();

    final croppedImage = img.copyCrop(image, x: x, y: y, width: width, height: height);

    final directory = await getTemporaryDirectory();
    final croppedImagePath = '${directory.path}/cropped_image.png';
    final croppedImageFile = File(croppedImagePath)
      ..writeAsBytesSync(img.encodePng(croppedImage));

    return croppedImageFile;
  }


  Future<void> _sendDataToApi(Map<String, dynamic> box) async {
    setState(() {
      _needsScroll = true;
      _isThinking = true;
    });
    final croppedImageFile = await _cropImage(imagePath!, box);
    final ocrResponse = await _apiRepository.sendOCRRequest(
      imagePath: croppedImageFile.path,
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
              //'Field ${box['class']} selected. The detected text is: $_ocrText',
              '$_ocrText',
        });
        _isThinking = false;
        _needsScroll = true;
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
  IconData? leadingIcon;

  if (_selectedFieldName == null) {
    instructionText = 'Tap to select a field';
    //leadingIcon = Icons.touch_app;
  } else if (_ocrText == null) {
    instructionText = 'Scanning $_selectedFieldName...';
    //leadingIcon = Icons.scanner;
  } else if (_ocrText != null && _inputEnabled && chatMessages.isEmpty) {
    instructionText = 'Tap to ask or type a question';
    //leadingIcon = Icons.question_answer;
  } else if (!_isFieldLocked && !_isThinking && chatMessages.isNotEmpty) {
    instructionText = 'Tap to select another field';
    showCompletionBanner = true;
    //leadingIcon = Icons.arrow_back;
  } else if (_isThinking) {
    instructionText = 'Analyzing content...';
    //leadingIcon = Icons.psychology;
  } else {
    instructionText = 'Ask about selected field';
    //leadingIcon = Icons.chat;
  }

  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.95, end: 1.0),
    duration: const Duration(milliseconds: 200),
    builder: (context, value, child) {
      return Transform.scale(
        scale: value,
        child: child,
      );
    },
    child: GestureDetector(
      onTap: showCompletionBanner
          ? () {
              _minimizeDraggableSheet();
            }
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: _isThinking
                  ? Colors.amber.shade200
                  : showCompletionBanner
                      ? Colors.teal.shade200
                      : Colors.blue.shade100,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null)
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: value,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  leadingIcon,
                  color: _isThinking
                      ? Colors.amber.shade700
                      : showCompletionBanner
                          ? Colors.teal.shade700
                          : Colors.black,
                  size: 24,
                ),
              ),
            if (leadingIcon != null) const SizedBox(width: 12),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  instructionText,
                  key: ValueKey(instructionText),
                  style: TextStyle(
                    color: _isThinking
                        ? Colors.amber.shade800
                        : showCompletionBanner
                            ? Colors.teal.shade800
                            : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (_isThinking)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            // if (showCompletionBanner)
            //   Padding(
            //     padding: const EdgeInsets.only(left: 12),
            //     child: Icon(
            //       Icons.check_circle,
            //       color: Colors.teal.shade700,
            //       size: 24,
            //     ),
            //   ),
          ],
        ),
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
                  Navigator.pushNamed(context, '/form_selection');
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
          backgroundColor: Colors.white,
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
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            transformationController: TransformationController(Matrix4.identity()),
            child: Container(
              color: Colors.white,
              child: Stack(
                children: [
                  if (imagePath != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(imagePath!),
                          fit: BoxFit.contain,
                          width: _showBottomSheet
                              ? MediaQuery.of(context).size.width
                              : MediaQuery.of(context).size.width * 0.8,
                          height: _showBottomSheet
                              ? MediaQuery.of(context).size.height * 0.5
                              : null,
                        ),
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
// child: FittedBox(
    //   fit: _showBottomSheet ? BoxFit.contain : BoxFit.fitWidth,
    //   alignment: Alignment.topCenter,
    //   child: InteractiveViewer(
    //     panEnabled: true,
    //     minScale: 0.5,
    //     maxScale: 4.0,
    //     child: Stack(
    //       children: [
    //         if (imagePath != null)
    //           Center( 
    //             child: Image.file(
    //               File(imagePath!),
    //               fit: _showBottomSheet ? BoxFit.fitWidth : BoxFit.fitHeight,
    //               width: _showBottomSheet
    //                   ? MediaQuery.of(context).size.width
    //                   : null,
    //               height: _showBottomSheet
    //                   ? MediaQuery.of(context).size.height * 0.5
    //                   : MediaQuery.of(context).size.height,
    //             ),
    //           ),
    //         if (boundingBoxes != null)
    //           BoundingBoxOverlay(
    //             imagePath: imagePath!,
    //             boundingBoxes: boundingBoxes!,
    //             selectedBox: selectedBox,
    //             previouslySelectedBoxes: previouslySelectedBoxes,
    //             onBoundingBoxTap: _onBoundingBoxTap,
    //           ),
    //       ],
    //     ),
    //   ),
    // ),