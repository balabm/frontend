import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'audio_player_widget.dart';
import 'package:flutter/services.dart'; // Required for clipboard functionality

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isUser;
  final bool isThinking;
  final bool isAudioMessage;
  final String? audioPath;
  final String? asrResponse;
  final DateTime timestamp;
  final VoidCallback? onPlayAudio;
  final bool isLLMResponse; // Add this field to indicate if it's an LLM response
  // In ChatBubble class
  final Function(bool, String?, String?)? onFeedback; // isHelpful, category, feedbackText
  final String? existingFeedback; // 'thumbs_up', 'thumbs_down', or null
  final String? existingFeedbackCategory;
  final String? existingFeedbackText;

  ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.isThinking = false,
    this.isAudioMessage = false,
    this.audioPath,
    this.asrResponse,
    required this.timestamp,
    this.onPlayAudio,
    this.isLLMResponse = false, // Default to false
    this.onFeedback, // Initialize onFeedback
     // Initialize new properties
    this.existingFeedback,
    this.existingFeedbackCategory,
    this.existingFeedbackText,
    
  }) : super(key: key);



  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}



class _ChatBubbleState extends State<ChatBubble> {
  bool? _feedback; // null: no feedback, true: thumbs up, false: thumbs down
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _customCategoryController = TextEditingController();
  bool _showingFeedbackOption = false;
  bool _isCustomCategory = false;
// These should be initialized at class level

String? _selectedCategory;

   String _formatTimestamp(DateTime timestamp) {
    return DateFormat('hh:mm a').format(timestamp);
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Initialize feedback state based on existing feedback
  //   if (widget.existingFeedback != null) {
  //   // Convert string values to boolean states
  //   if (widget.existingFeedback == 'thumbs_up') {
  //     _feedback = true;
  //   } else if (widget.existingFeedback == 'thumbs_down') {
  //     _feedback = false;
  //     _showingFeedbackOption = true; // Show the "Let us know why" option
  //   }
    
  //   _selectedCategory = widget.existingFeedbackCategory;
      
  //     // Pre-fill feedback text if it exists
  //     if (widget.existingFeedbackText != null && widget.existingFeedbackText!.isNotEmpty) {
  //       _feedbackController.text = widget.existingFeedbackText!;
  //     }
  //   }
   
  // }
  @override
void initState() {
  super.initState();
  
  // Add debug prints
  print('DEBUG: Restoring feedback: ${widget.existingFeedback}');
  print('DEBUG: Restoring feedback text: ${widget.existingFeedbackText}');
  print('DEBUG: Restoring feedback category: ${widget.existingFeedbackCategory}');
  
  // Initialize feedback state based on existing feedback
  if (widget.existingFeedback != null) {
    // Convert string values to boolean states
    if (widget.existingFeedback == 'thumbs_up') {
      _feedback = true;
      // When thumbs up, use 'Helpful' as category
      _selectedCategory = widget.existingFeedbackCategory ?? 'Helpful';
    } else if (widget.existingFeedback == 'thumbs_down') {
      _feedback = false;
      _showingFeedbackOption = true;
      
      // Set category from existing data
      if (widget.existingFeedbackCategory != null && widget.existingFeedbackCategory!.isNotEmpty) {
        _selectedCategory = widget.existingFeedbackCategory;
        
        // Check if it's a custom category (not in predefined list)
        final List<String> standardCategories = [
          'Incorrect information',
          'Not relevant to my question',
          'Unclear or confusing',
          'Incomplete answer',
          'Other'
        ];
        
        if (!standardCategories.contains(_selectedCategory)) {
          _isCustomCategory = true;
          _customCategoryController.text = _selectedCategory!;
        }
      }
    }
    
    // Pre-fill feedback text if it exists
    if (widget.existingFeedbackText != null && widget.existingFeedbackText!.isNotEmpty) {
      _feedbackController.text = widget.existingFeedbackText!;
    }
    
    print('Restored feedback state: $_feedback, category: $_selectedCategory, text: ${_feedbackController.text}');
  }
}
@override
void didUpdateWidget(ChatBubble oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // Check if feedback props have changed and update state accordingly
  if (widget.existingFeedback != oldWidget.existingFeedback ||
      widget.existingFeedbackCategory != oldWidget.existingFeedbackCategory ||
      widget.existingFeedbackText != oldWidget.existingFeedbackText) {
    
    print('Feedback props changed, updating state');
    
    // Update feedback state
    if (widget.existingFeedback == 'thumbs_up') {
      _feedback = true;
    } else if (widget.existingFeedback == 'thumbs_down') {
      _feedback = false;
      _showingFeedbackOption = true;
    }
    
    // Update category
    if (widget.existingFeedbackCategory != null && widget.existingFeedbackCategory != oldWidget.existingFeedbackCategory) {
      _selectedCategory = widget.existingFeedbackCategory;
    }
    
    // Update feedback text
    if (widget.existingFeedbackText != null && widget.existingFeedbackText != oldWidget.existingFeedbackText) {
      _feedbackController.text = widget.existingFeedbackText!;
    }
  }
}

  @override
  void dispose() {
    _feedbackController.dispose();
    _customCategoryController.dispose();
    
    super.dispose();
  }

//   @override
//   Widget build(BuildContext context) {
//     final timeString = _formatTimestamp(widget.timestamp);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Column(
//         crossAxisAlignment:
//             widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment:
//                 widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               if (!widget.isUser) ...[
//                 Container(
//                   padding: EdgeInsets.only(right: 10),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: CircleAvatar(
//                       backgroundImage: AssetImage('assets/5.png'),
//                       radius: 16,
//                     ),
//                   ),
//                 )
//               ],
//               Flexible(
//                 child: Column(
//                   crossAxisAlignment:
//                       widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 10),
//                       decoration: BoxDecoration(
//                         color: widget.isUser
//                             ? Color.fromRGBO(0, 150, 136, 1.0)
//                             : Colors.grey[200],
//                         borderRadius: BorderRadius.only(
//                           topLeft: Radius.circular(20),
//                           topRight: Radius.circular(20),
//                           bottomLeft:
//                               widget.isUser ? Radius.circular(20) : Radius.zero,
//                           bottomRight:
//                               widget.isUser ? Radius.zero : Radius.circular(20),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 3,
//                             offset: Offset(0, 1),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: widget.isUser
//                             ? CrossAxisAlignment.end
//                             : CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           if (widget.isAudioMessage && widget.audioPath != null) ...[
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 GestureDetector(
//                                   onTap: widget.onPlayAudio,
//                                   child: AudioPlayerWidget(
//                                       audioPath: widget.audioPath!),
//                                 ),
//                                 if (widget.asrResponse != null) ...[
//                                   const SizedBox(height: 4),
//                                   Container(
//                                     constraints:
//                                         BoxConstraints(maxWidth: 150),
//                                     child: Text(
//                                       widget.asrResponse!,
//                                       style: const TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 13,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ] else ...[
//                             GestureDetector(
//                               onLongPress: () {
//                                 Clipboard.setData(
//                                     ClipboardData(text: widget.message));
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(
//                                     content: Text("Text copied to clipboard"),
//                                     behavior: SnackBarBehavior.floating,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     duration: Duration(seconds: 1),
//                                   ),
//                                 );
//                               },
//                               child: SelectableText(
//                                 widget.message,
//                                 cursorColor: Colors.teal,
//                                 style: TextStyle(
//                                   color: widget.isUser
//                                       ? Colors.white
//                                       : Colors.black87,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
                    
//                     // Timestamp and feedback section
//                     if (!widget.isUser && !widget.isThinking) ...[
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Text(
//                               timeString,
//                               style: TextStyle(
//                                 color: Color.fromRGBO(117, 117, 117, 1),
//                                 fontSize: 10,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
                            
//                             // Direct thumbs up and down buttons
                          
//                           if (widget.isLLMResponse) ...[
                            
//                             if (_feedback == null) ...[
//                               Row(
//                                 children: [
//                                   // Thumbs up button
//                                   Material(
//                                     color: Colors.transparent,
//                                     child: InkWell(
//                                       borderRadius: BorderRadius.circular(20),
//                                       onTap: () {
//                                         setState(() {
//                                           _feedback = true; 
//                                         });
//                                         // Call the onFeedback callback to pass data to parent
//                                         if (widget.onFeedback != null) {
//                                           widget.onFeedback!(true, "Helpful", null);
//                                         }
//                                         // Show feedback confirmation
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           SnackBar(
//                                             content: Text("Thanks for your feedback!"),
//                                             behavior: SnackBarBehavior.floating,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(10),
//                                             ),
//                                             duration: Duration(seconds: 1),
//                                           ),
//                                         );
//                                       },
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(6.0),
//                                         child: Icon(
//                                           Icons.thumb_up_outlined,
//                                           size: 18,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
                                  
//                                   const SizedBox(width: 10),
                                  
//                                   // Thumbs down button
//                                   Material(
//                                     color: Colors.transparent,
//                                     child: InkWell(
//                                       borderRadius: BorderRadius.circular(20),
//                                       onTap: () {
//                                         setState(() {
//                                           _feedback = false;
//                                         });
//                                         // Show feedback dialog
//                                         _handleThumbsDown();
//                                         //_showFeedbackDialog(context);
//                                       },
//                                       child: Padding(
//                                         padding: const EdgeInsets.all(6.0),
//                                         child: Icon(
//                                           Icons.thumb_down_outlined,
//                                           size: 18,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ] 
//                             else if (_feedback == true) ...[
//                               // Show that positive feedback was given
//                               Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.teal.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(color: Colors.teal.withOpacity(0.3)),
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(
//                                       Icons.thumb_up,
//                                       size: 12,
//                                       color: Colors.teal,
//                                     ),
//                                     SizedBox(width: 4),
//                                     Text(
//                                       'Helpful',
//                                       style: TextStyle(
//                                         fontSize: 10,
//                                         color: Colors.teal,
//                                       ),
//                                     ),
//                                     SizedBox(width: 2),
//                                     InkWell(
//                                       onTap: () {
//                                         setState(() {
//                                           _feedback = null;
//                                         });
//                                       },
//                                       child: Icon(
//                                         Icons.close,
//                                         size: 12,
//                                         color: Colors.teal,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ] else if (_feedback == false) ...[
//                               // Show that negative feedback was given
//                               Container(
//                                 padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.withOpacity(0.1),
//                                   borderRadius: BorderRadius.circular(12),
//                                   border: Border.all(color: Colors.red.withOpacity(0.3)),
//                                 ),
//                                 child: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(
//                                       Icons.thumb_down,
//                                       size: 12,
//                                       color: Colors.red[400],
//                                     ),
//                                     SizedBox(width: 4),
//                                     Text(
//                                       'Not helpful',
//                                       style: TextStyle(
//                                         fontSize: 10,
//                                         color: Colors.red[400],
//                                       ),
//                                     ),
//                                     SizedBox(width: 2),
//                                     InkWell(
//                                       onTap: () {
//                                         setState(() {
//                                           _feedback = null;
//                                         });
//                                       },
//                                       child: Icon(
//                                         Icons.close,
//                                         size: 12,
//                                         color: Colors.red[400],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ],
//                           ],
//                         ),
//                       ),
//                     ] else ...[
//                       // Just timestamp for user messages
//                       Padding(
//                         padding: const EdgeInsets.only(top: 4.0),
//                         child: Text(
//                           timeString,
//                           style: TextStyle(
//                             color: Color.fromRGBO(117, 117, 117, 1),
//                             fontSize: 10,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//   void _handleThumbsDown() {
//   // Handle the thumbs down action without immediately showing feedback dialog
//   if (widget.onFeedback != null) {
//     // Just register the thumbs down without requiring feedback
//     widget.onFeedback!(false, "", "");
//   }
  
//   // Show a snackbar with the option to provide more feedback
//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Row(
//         children: [
//           Text("Thanks for your feedback"),
//           Spacer(),
//           TextButton(
//             onPressed: () {
//               // Dismiss the snackbar
//               ScaffoldMessenger.of(context).hideCurrentSnackBar();
//               // Show the feedback dialog
//               _showFeedbackDialog(context);
//             },
//             child: Text(
//               "Let us know why",
//               style: TextStyle(color: Colors.tealAccent),
//             ),
//           ),
//         ],
//       ),
//       behavior: SnackBarBehavior.floating,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//       ),
//       duration: Duration(seconds: 5),
//     ),
//   );
// }

// void _showFeedbackDialog(BuildContext context) {
//   // Reset controllers to ensure clean state when dialog reopens
//   _feedbackController.clear();
//   _customCategoryController.clear();
//   _selectedCategory = null;
//   _isCustomCategory = false;
  
//   final List<String> _feedbackCategories = [
//     'Incorrect information',
//     'Not relevant to my question',
//     'Unclear or confusing',
//     'Incomplete answer',
//     'Other',
//     'Custom',
//   ];
//   bool _isOtherCategory = false;
//   bool _isSubmitEnabled = false;
  
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           // Check if custom or other option is selected
//           _isCustomCategory = _selectedCategory == 'Custom';
//           _isOtherCategory = _selectedCategory == 'Other';
          
//           // Function to check if submit should be enabled
//           void _updateSubmitStatus() {
//             bool hasValidCategory = _selectedCategory != null && _selectedCategory!.isNotEmpty;
//             bool hasValidCustomText = _isCustomCategory ? _customCategoryController.text.trim().isNotEmpty : true;
//             bool hasValidFeedbackText = _isOtherCategory ? _feedbackController.text.trim().isNotEmpty : true;
            
//             setState(() {
//               _isSubmitEnabled = hasValidCategory && hasValidCustomText && hasValidFeedbackText;
//             });
//           }
          
//           return AlertDialog(
//             backgroundColor: Colors.white,
//             title: Text(
//               "Feedback",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             content: Container(
//               width: double.maxFinite,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Category Dropdown
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey[300]!),
//                     ),
//                     child: DropdownButtonHideUnderline(
//                       child: DropdownButton<String>(
//                         value: _selectedCategory,
//                         hint: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                           child: Text("Select category"),
//                         ),
//                         isExpanded: true,
//                         icon: Icon(Icons.arrow_drop_down),
//                         borderRadius: BorderRadius.circular(8),
//                         items: _feedbackCategories.map((String value) {
//                           return DropdownMenuItem<String>(
//                             value: value,
//                             child: Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                               child: Text(value),
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (newValue) {
//                           setState(() {
//                             _selectedCategory = newValue;
//                             // Clear feedback field if changing from Other to something else
//                             if (_isOtherCategory && newValue != 'Other') {
//                               _feedbackController.text = '';
//                             }
//                             _updateSubmitStatus();
//                           });
//                         },
//                         dropdownColor: Colors.white,
//                       ),
//                     ),
//                   ),
                  
//                   // Custom Category Field - only visible if Custom is selected
//                   if (_isCustomCategory) ...[
//                     SizedBox(height: 12),
//                     TextField(
//                       controller: _customCategoryController,
//                       decoration: InputDecoration(
//                         hintText: "Specify issue",
//                         fillColor: Colors.white,
//                         filled: true,
//                         contentPadding: EdgeInsets.all(12),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.teal),
//                         ),
//                       ),
//                       onChanged: (text) {
//                         _updateSubmitStatus();
//                       },
//                     ),
//                   ],
                  
//                   SizedBox(height: 16),
                  
//                   // Comments Field - label changes based on if it's required
//                   TextField(
//                     controller: _feedbackController,
//                     decoration: InputDecoration(
//                       hintText: _isOtherCategory ? "Please specify the issue (required)" : "Additional comments (optional)",
//                       fillColor: Colors.white,
//                       filled: true,
//                       contentPadding: EdgeInsets.all(12),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: _isOtherCategory && _feedbackController.text.isEmpty ? Colors.red[300]! : Colors.grey[300]!),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: _isOtherCategory && _feedbackController.text.isEmpty ? Colors.red[300]! : Colors.grey[300]!),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: Colors.teal),
//                       ),
//                     ),
//                     maxLines: 3,
//                     onChanged: (text) {
//                       _updateSubmitStatus();
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 child: Text(
//                   "Cancel",
//                   style: TextStyle(color: Colors.grey[700]),
//                 ),
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   this.setState(() {
//                     _feedback = null;
//                     _feedbackController.clear(); // Clear the feedback controller
 
//                   });
//                 },
//               ),
//               ElevatedButton(
//                 child: Text("Submit"),
//                 onPressed: _isSubmitEnabled ? () {
//                   // Double-check validation before submission
//                   if (_isOtherCategory && _feedbackController.text.trim().isEmpty) {
//                     return; // Prevent submission
//                   }
                  
//                   if (_isCustomCategory && _customCategoryController.text.trim().isEmpty) {
//                     return; // Prevent submission
//                   }
                  
//                   final String finalCategory = _isCustomCategory
//                       ? _customCategoryController.text
//                       : _selectedCategory ?? "";
                  
//                   if (widget.onFeedback != null) {
//                     widget.onFeedback!(false, finalCategory, _feedbackController.text);
//                   }
//                   // Clear the feedback controller
//           _feedbackController.clear();
                  
//                   // Close dialog
//                   Navigator.of(context).pop();
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text("Feedback submitted"),
//                       behavior: SnackBarBehavior.floating,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       duration: Duration(seconds: 2),
//                     ),
//                   );
//                 } : null,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.teal,
//                   foregroundColor: Colors.white,
//                   disabledBackgroundColor: Colors.grey[300],
//                   disabledForegroundColor: Colors.grey[500],
//                 ),
//               ),
//             ],
//           );
//         }
//       );
//     },
//   );
// }
// }
@override
Widget build(BuildContext context) {
  print('Building ChatBubble with:');
  print('- feedback state: $_feedback');
  print('- existing feedback from Firestore: ${widget.existingFeedback}');
  print('- feedback category: $_selectedCategory / ${widget.existingFeedbackCategory}');
  print('- feedback text: ${_feedbackController.text} / ${widget.existingFeedbackText}');
  print('- isLLMResponse: ${widget.isLLMResponse}');
 
  final timeString = _formatTimestamp(widget.timestamp);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: Column(
      crossAxisAlignment:
          widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isUser) ...[
              Container(
                padding: EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/5.png'),
                    radius: 16,
                  ),
                ),
              )
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.isUser
                          ? Color.fromRGBO(0, 150, 136, 1.0)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft:
                            widget.isUser ? Radius.circular(20) : Radius.zero,
                        bottomRight:
                            widget.isUser ? Radius.zero : Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: widget.isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isAudioMessage && widget.audioPath != null) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: widget.onPlayAudio,
                                child: AudioPlayerWidget(
                                    audioPath: widget.audioPath!),
                              ),
                              if (widget.asrResponse != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  constraints:
                                      BoxConstraints(maxWidth: 150),
                                  child: Text(
                                    widget.asrResponse!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          GestureDetector(
                            onLongPress: () {
                              Clipboard.setData(
                                  ClipboardData(text: widget.message));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Text copied to clipboard"),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: SelectableText(
                              widget.message,
                              cursorColor: Colors.teal,
                              style: TextStyle(
                                color: widget.isUser
                                    ? Colors.white
                                    : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Timestamp and feedback section
                  if (!widget.isUser && !widget.isThinking) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeString,
                            style: TextStyle(
                              color: Color.fromRGBO(117, 117, 117, 1),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Direct thumbs up and down buttons
//                           if (widget.isLLMResponse) ...[
//                             Row(
//                               children: [
//                                 // Thumbs up button
//                                 // Material(
//                                 //   color: Colors.transparent,
//                                 //   child: InkWell(
//                                 //     borderRadius: BorderRadius.circular(20),
//                                 //     onTap: () {
//                                 //       setState(() {
//                                 //         _feedback = true; 
//                                 //       });
//                                 //       // Call the onFeedback callback to pass data to parent
//                                 //       if (widget.onFeedback != null) {
//                                 //         widget.onFeedback!(true, "Helpful", null);
//                                 //       }
//                                 //       // Show feedback confirmation
//                                 //       ScaffoldMessenger.of(context).showSnackBar(
//                                 //         SnackBar(
//                                 //           content: Text("Thanks for your feedback!"),
//                                 //           behavior: SnackBarBehavior.floating,
//                                 //           shape: RoundedRectangleBorder(
//                                 //             borderRadius: BorderRadius.circular(10),
//                                 //           ),
//                                 //           duration: Duration(seconds: 1),
//                                 //         ),
//                                 //       );
//                                 //     },
//                                 //     child: Padding(
//                                 //       padding: const EdgeInsets.all(6.0),
//                                 //       child: Icon(
//                                 //         _feedback == true ? Icons.thumb_up : Icons.thumb_up_outlined,
//                                 //         size: 18,
//                                 //         color: _feedback == true ? Colors.teal : Colors.grey[600],
//                                 //       ),
//                                 //     ),
//                                 //   ),
//                                 // ),
                                
//                                 // const SizedBox(width: 10),
                                
//                                 // // Thumbs down button with inline "let us know why" option
//                                 // Row(
//                                 //   mainAxisSize: MainAxisSize.min,
//                                 //   children: [
//                                 //     Material(
//                                 //       color: Colors.transparent,
//                                 //       child: InkWell(
//                                 //         borderRadius: BorderRadius.circular(20),
//                                 //         onTap: () {
//                                 //           setState(() {
//                                 //             _feedback = false;
//                                 //             _showingFeedbackOption = true;
//                                 //           });
                                          
//                                 //           // Register the thumbs down feedback
//                                 //           if (widget.onFeedback != null) {
//                                 //             widget.onFeedback!(false, "", "");
//                                 //           }
//                                 //         },
//                                 //         child: Padding(
//                                 //           padding: const EdgeInsets.all(6.0),
//                                 //           child: Icon(
//                                 //             _feedback == false ? Icons.thumb_down : Icons.thumb_down_outlined,
//                                 //             size: 18,
//                                 //             color: _feedback == false ? const Color.fromARGB(255, 214, 173, 13) : Colors.grey[600],
//                                 //           ),
//                                 //         ),
//                                 //       ),
//                                 //     ),
                                    
//                                 //     // "Let us know why" option appears next to thumbs down when clicked
//                                 //     if (_feedback == false) ...[
//                                 //       //const SizedBox(width: 8),
//                                 //       TextButton(
//                                 //         onPressed: () {
//                                 //           _showFeedbackDialog(context);
//                                 //         },
//                                 //         style: TextButton.styleFrom(
//                                 //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 //           minimumSize: Size(0, 0),
//                                 //           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                                 //         ),
//                                 //         child: Text(
//                                 //           "Let us know why?",
//                                 //           style: TextStyle(
//                                 //             color: Colors.teal,
//                                 //             fontSize: 12,
//                                 //           ),
//                                 //         ),
//                                 //       ),
//                                 //     ],
//                                 //   ],
//                                 // ),
//                                 // Inside your build method, replace the thumbs up/down section with this:

// // Thumbs up button
// Material(
//   color: Colors.transparent,
//   child: InkWell(
//     borderRadius: BorderRadius.circular(20),
//     onTap: () {
//       setState(() {
//         _feedback = true; 
//         _showingFeedbackOption = false; // Hide feedback option when thumbs up
//       });
//       // Call the onFeedback callback to pass data to parent
//       if (widget.onFeedback != null) {
//         widget.onFeedback!(true, "Helpful", null);
//       }
//       // Show feedback confirmation
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Thanks for your feedback!"),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           duration: Duration(seconds: 1),
//         ),
//       );
//     },
//     child: Padding(
//       padding: const EdgeInsets.all(6.0),
//       child: Icon(
//         _feedback == true ? Icons.thumb_up : Icons.thumb_up_outlined,
//         size: 18,
//         color: _feedback == true ? Colors.teal : Colors.grey[600],
//       ),
//     ),
//   ),
// ),

// const SizedBox(width: 10),

// // Thumbs down button with inline "let us know why" option
// Row(
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     Material(
//       color: Colors.transparent,
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: () {
//           setState(() {
//             _feedback = false;
//             _showingFeedbackOption = true;
//           });
          
//           // Register the thumbs down feedback
//           if (widget.onFeedback != null && widget.existingFeedback != 'thumbs_down') {
//             // Only call onFeedback if not already thumbs down to avoid duplicate callbacks
//             widget.onFeedback!(false, "", "");
//           }
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(6.0),
//           child: Icon(
//             _feedback == false ? Icons.thumb_down : Icons.thumb_down_outlined,
//             size: 18,
//             color: _feedback == false ? const Color.fromARGB(255, 214, 173, 13) : Colors.grey[600],
//           ),
//         ),
//       ),
//     ),
    
//     // "Let us know why" option appears next to thumbs down when clicked
//     if (_feedback == false && _showingFeedbackOption) ...[
//       TextButton(
//         onPressed: () {
//           _showFeedbackDialog(context);
//         },
//         style: TextButton.styleFrom(
//           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//           minimumSize: Size(0, 0),
//           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         ),
//         child: Text(
//           "Let us know why?",
//           style: TextStyle(
//             color: Colors.teal,
//             fontSize: 12,
//           ),
//         ),
//       ),
//     ],
//   ],
// ),
//                               ],
//                             ),
//                           ],
// Modify the conditional that controls when feedback buttons are displayed in build method
// Find the section in your build method where you have:


// Replace it with this updated condition:
if (widget.isLLMResponse || widget.existingFeedback != null) ...[
  Row(
    children: [
      // Thumbs up button
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (widget.existingFeedback == 'thumbs_up') {
              // Already liked, do nothing or maybe allow to undo
              return;
            }
            setState(() {
              _feedback = true; 
              _showingFeedbackOption = false;
            });
            // Call the onFeedback callback to pass data to parent
            if (widget.onFeedback != null) {
              widget.onFeedback!(true, "Helpful", null);
            }
            // Show feedback confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Thanks for your feedback!"),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              _feedback == true ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: _feedback == true ? Colors.teal : Colors.grey[600],
            ),
          ),
        ),
      ),
      
      const SizedBox(width: 10),
      
      // Thumbs down button with inline "let us know why" option
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (widget.existingFeedback == 'thumbs_down') {
                  // Already disliked, show feedback dialog again
                  _showFeedbackDialog(context);
                  return;
                }
                setState(() {
                  _feedback = false;
                  _showingFeedbackOption = true;
                });
                
                // Register the thumbs down feedback
                if (widget.onFeedback != null) {
                  widget.onFeedback!(false, "", "");
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Icon(
                  _feedback == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                  size: 18,
                  color: _feedback == false ? const Color.fromARGB(255, 214, 173, 13) : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          // "Let us know why" option appears next to thumbs down when clicked
          if (_feedback == false) ...[
            TextButton(
              onPressed: () {
                _showFeedbackDialog(context);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                "Let us know why?",
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    ],
  ),
],
                    
                        ],
                      ),
                    ),
                  ] else ...[
                    // Just timestamp for user messages
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        timeString,
                        style: TextStyle(
                          color: Color.fromRGBO(117, 117, 117, 1),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Add a new state variable to track when showing feedback option
//bool _showingFeedbackOption = false;

// Modified _handleThumbsDown method - this is now mostly handled inline
void _handleThumbsDown() {
  // Handle the thumbs down action - this method is kept for compatibility
  // but the main logic is now handled directly in the build method
  
  setState(() {
    _feedback = false;
    _showingFeedbackOption = true;
  });
  
  if (widget.onFeedback != null) {
    // Just register the thumbs down without requiring feedback
    widget.onFeedback!(false, "", "");
  }
}

void _showFeedbackDialog(BuildContext context) {
  // Reset controllers to ensure clean state when dialog reopens
  _feedbackController.clear();
  _customCategoryController.clear();
  _selectedCategory = null;
  _isCustomCategory = false;
  
  final List<String> _feedbackCategories = [
    'Incorrect information',
    'Not relevant to my question',
    'Unclear or confusing',
    'Incomplete answer',
    'Other',
    'Custom',
  ];
  bool _isOtherCategory = false;
  bool _isSubmitEnabled = false;
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // Check if custom or other option is selected
          _isCustomCategory = _selectedCategory == 'Custom';
          _isOtherCategory = _selectedCategory == 'Other';
          
          // Function to check if submit should be enabled
          void _updateSubmitStatus() {
            bool hasValidCategory = _selectedCategory != null && _selectedCategory!.isNotEmpty;
            bool hasValidCustomText = _isCustomCategory ? _customCategoryController.text.trim().isNotEmpty : true;
            bool hasValidFeedbackText = _isOtherCategory ? _feedbackController.text.trim().isNotEmpty : true;
            
            setState(() {
              _isSubmitEnabled = hasValidCategory && hasValidCustomText && hasValidFeedbackText;
            });
          }
          
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              "Feedback",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text("Select category"),
                        ),
                        isExpanded: true,
                        icon: Icon(Icons.arrow_drop_down),
                        borderRadius: BorderRadius.circular(8),
                        items: _feedbackCategories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(value),
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                            // Clear feedback field if changing from Other to something else
                            if (_isOtherCategory && newValue != 'Other') {
                              _feedbackController.text = '';
                            }
                            _updateSubmitStatus();
                          });
                        },
                        dropdownColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  // Custom Category Field - only visible if Custom is selected
                  if (_isCustomCategory) ...[
                    SizedBox(height: 12),
                    TextField(
                      controller: _customCategoryController,
                      decoration: InputDecoration(
                        hintText: "Specify issue",
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.teal),
                        ),
                      ),
                      onChanged: (text) {
                        _updateSubmitStatus();
                      },
                    ),
                  ],
                  
                  SizedBox(height: 16),
                  
                  // Comments Field - label changes based on if it's required
                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      hintText: _isOtherCategory ? "Please specify the issue (required)" : "Additional comments (optional)",
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _isOtherCategory && _feedbackController.text.isEmpty ? Colors.red[300]! : Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _isOtherCategory && _feedbackController.text.isEmpty ? Colors.red[300]! : Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                    maxLines: 3,
                    onChanged: (text) {
                      _updateSubmitStatus();
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text("Submit"),
                onPressed: _isSubmitEnabled ? () {
                  // Double-check validation before submission
                  if (_isOtherCategory && _feedbackController.text.trim().isEmpty) {
                    return; // Prevent submission
                  }
                  
                  if (_isCustomCategory && _customCategoryController.text.trim().isEmpty) {
                    return; // Prevent submission
                  }
                  
                  final String finalCategory = _isCustomCategory
                      ? _customCategoryController.text
                      : _selectedCategory ?? "";
                  
                  if (widget.onFeedback != null) {
                    widget.onFeedback!(false, finalCategory, _feedbackController.text);
                  }
                  // Clear the feedback controller
                  _feedbackController.clear();
                  
                  // Close dialog
                  Navigator.of(context).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Feedback submitted"),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[500],
                ),
              ),
            ],
          );
        }
      );
    },
  );
}
}

//   void _showFeedbackDialog(BuildContext context) {
//     // Reset controllers to ensure clean state when dialog reopens
//     _feedbackController.clear();
//     _customCategoryController.clear();
//     _selectedCategory = null;
//     _isCustomCategory = false;
    
//     final List<String> _feedbackCategories = [
//       'Incorrect information',
//       'Not relevant to my question',
//       'Unclear or confusing',
//       'Incomplete answer',
//       'Other',
//       'Custom',
//     ];
//     bool _isOtherCategory = false;
//     bool _isSubmitEnabled = false;
    
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             // Check if custom or other option is selected
//             _isCustomCategory = _selectedCategory == 'Custom';
//             _isOtherCategory = _selectedCategory == 'Other';
            
//             // Function to check if submit should be enabled
//             void _updateSubmitStatus() {
//               bool hasValidCategory = _selectedCategory != null && _selectedCategory!.isNotEmpty;
//               bool hasValidCustomText = _isCustomCategory ? _customCategoryController.text.trim().isNotEmpty : true;
//               bool hasValidFeedbackText = _isOtherCategory ? _feedbackController.text.trim().isNotEmpty : true;
              
//               setState(() {
//                 _isSubmitEnabled = hasValidCategory && hasValidCustomText && hasValidFeedbackText;
//               });
//             }
            
//             return AlertDialog(
//               backgroundColor: Colors.white,
//               title: Text(
//                 "Feedback",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               content: Container(
//                 width: double.maxFinite,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Category Dropdown
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<String>(
//                           value: _selectedCategory,
//                           hint: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                             child: Text("Select category"),
//                           ),
//                           isExpanded: true,
//                           icon: Icon(Icons.arrow_drop_down),
//                           borderRadius: BorderRadius.circular(8),
//                           items: _feedbackCategories.map((String value) {
//                             return DropdownMenuItem<String>(
//                               value: value,
//                               child: Padding(
//                                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                                 child: Text(value),
//                               ),
//                             );
//                           }).toList(),
//                           onChanged: (newValue) {
//                             setState(() {
//                               _selectedCategory = newValue;
//                               // Clear feedback field if changing from Other to something else
//                               if (_isOtherCategory && newValue != 'Other') {
//                                 _feedbackController.text = '';
//                               }
//                               _updateSubmitStatus();
//                             });
//                           },
//                           dropdownColor: Colors.white,
//                         ),
//                       ),
//                     ),
                    
//                     // Custom Category Field - only visible if Custom is selected
//                     if (_isCustomCategory) ...[
//                       SizedBox(height: 12),
//                       TextField(
//                         controller: _customCategoryController,
//                         decoration: InputDecoration(
//                           hintText: "Specify issue",
//                           fillColor: Colors.white,
//                           filled: true,
//                           contentPadding: EdgeInsets.all(12),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.grey[300]!),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(8),
//                             borderSide: BorderSide(color: Colors.teal),
//                           ),
//                         ),
//                         onChanged: (text) {
//                           _updateSubmitStatus();
//                         },
//                       ),
//                     ],
                    
//                     SizedBox(height: 16),
                    
//                     // Comments Field - label changes based on if it's required
//                     TextField(
//                       controller: _feedbackController,
//                       decoration: InputDecoration(
//                         hintText: _isOtherCategory ? "Please specify the issue (required)" : "Additional comments (optional)",
//                         fillColor: Colors.white,
//                         filled: true,
//                         contentPadding: EdgeInsets.all(12),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: _isOtherCategory && _feedbackController.text.isEmpty ? Colors.red[300]! : Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: _isOtherCategory && _feedbackController.text.isEmpty ? Colors.red[300]! : Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.teal),
//                         ),
//                       ),
//                       maxLines: 3,
//                       onChanged: (text) {
//                         _updateSubmitStatus();
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   child: Text(
//                     "Cancel",
//                     style: TextStyle(color: Colors.grey[700]),
//                   ),
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     this.setState(() {
//                       _feedback = null;
//                     });
//                   },
//                 ),
//                 ElevatedButton(
//                   child: Text("Submit"),
//                   onPressed: _isSubmitEnabled ? () {
//                     // Double-check validation before submission
//                     if (_isOtherCategory && _feedbackController.text.trim().isEmpty) {
//                       return; // Prevent submission
//                     }
                    
//                     if (_isCustomCategory && _customCategoryController.text.trim().isEmpty) {
//                       return; // Prevent submission
//                     }
                    
//                     final String finalCategory = _isCustomCategory
//                         ? _customCategoryController.text
//                         : _selectedCategory ?? "";
                    
//                     if (widget.onFeedback != null) {
//                       widget.onFeedback!(false, finalCategory, _feedbackController.text);
//                     }
                    
//                     // Close dialog
//                     Navigator.of(context).pop();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text("Feedback submitted"),
//                         behavior: SnackBarBehavior.floating,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         duration: Duration(seconds: 2),
//                       ),
//                     );
//                   } : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                     foregroundColor: Colors.white,
//                     disabledBackgroundColor: Colors.grey[300],
//                     disabledForegroundColor: Colors.grey[500],
//                   ),
//                 ),
//               ],
//             );
//           }
//         );
//       },
//     );
//   }
// }

