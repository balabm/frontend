// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:formbot/helpers/firebase_handler.dart';
// import 'package:formbot/providers/firebaseprovider.dart';
// import 'package:formbot/providers/authprovider.dart'; // Import AuthProvider
// import 'package:formbot/screens/widgets/common.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/services.dart'; // Import this for SystemNavigator.pop()


// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   final _searchController = TextEditingController();
//   late final AnimationController _animationController;
//   late final Animation<double> _scaleAnimation;

//   List<Map<String, dynamic>> _submittedForms = [];
//   List<String> _capturedImages = [];
//   String _userName = '';
//   bool _isLoading = true;

//   final _boxDecoration = BoxDecoration(
//     color: Colors.white,
//     borderRadius: BorderRadius.circular(16),
//     border: Border.all(style: BorderStyle.none),
//   );

//   final _textStyle = const TextStyle(
//     color: Colors.white,
//     fontSize: 18,
//     fontWeight: FontWeight.w600,
//   );

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _loadData();
//   }

//   void _initializeAnimations() {
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//   }

//   Future<void> _loadData() async {
//     try {
//       await Future.wait([
//         _loadSubmittedForms(),
//         _loadUserName(),
//         _loadCapturedImages(),
//         // _loadApiUrls(), // Add this line
//       ]);
//       _animationController.forward();
//     } catch (e) {
//       Common.showMessage(context, 'Error loading data: ${e.toString()}',
//           isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   // Future<void> _loadSubmittedForms() async {
//   //   final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
//   //   final forms = await firebaseProvider.getSubmittedForms();
//   //   if (mounted) {
//   //     setState(() => _submittedForms = forms);
//   //   }
//   // }

//   Future<void> _loadSubmittedForms() async {
//     try {
//       final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
//       final userId = authProvider.user?.uid;
//       if (userId == null) {
//         throw Exception('No authenticated user found');
//       }

//       // Fetch forms only for the current user
//       final forms = await firebaseProvider.getSubmittedForms(userId: userId);
      
//       if (mounted) {
//         setState(() {
//           // Only set forms that belong to the current user
//           _submittedForms = forms.where((form) => form['userId'] == userId).toList();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         Common.showMessage(
//           context, 
//           'Error loading forms: ${e.toString()}',
//           isError: true
//         );
//       }
//     }
//   }


//   Future<void> _loadCapturedImages() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (mounted)
//       setState(
//           () => _capturedImages = prefs.getStringList('capturedImages') ?? []);
//   }

//   Future<void> _loadUserName() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (mounted)
//       setState(() => _userName = prefs.getString('userName') ?? 'User');
//   }

//   Future<void> _loadApiUrls() async {
//     final prefs = await SharedPreferences.getInstance();
//     final boundingBoxUrl = prefs.getString('bounding_box_url') ?? 'http://10.64.26.89:8002/cv/form-detection-with-box/';
//     final ocrTextUrl = prefs.getString('ocr_text_url') ?? 'http://10.64.26.89:8001/cv/ocr';
//     final asrUrl = prefs.getString('asr_url') ?? 'http://10.64.26.83:8002/upload-audio-zip/';
//     final llmUrl = prefs.getString('llm_url') ?? 'http://10.64.26.89:8036/get_llm_response_schemes';
//     // Use the URLs as neededR
//   }

//   Future<void> _deleteForm(String formId) async {
//     try {
//       setState(() => _isLoading = true);
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       final uid = authProvider.user?.uid;
//       if (uid == null) {
//         throw Exception('User not logged in');
//       }
//       final firebaseHandler = FirebaseHandler(); // Create an instance of FirebaseHandler
//       await firebaseHandler.deleteForm(uid, formId); // Delete form from Firebase
//       setState(() => _submittedForms.removeWhere((form) => form['formId'] == formId));
//       Common.showMessage(context, 'Form Deleted successfully');
//     } catch (e) {
//       Common.showMessage(context, 'Error deleting form: ${e.toString()}',
//           isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   Widget _buildSearchBar() => Container(
//         decoration: _boxDecoration,
//         child: TextField(
//           controller: _searchController,
//           decoration: InputDecoration(
//             hintText: 'Search forms...',
//             hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide.none,
//             ),
//             prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
//             filled: true,
//             fillColor: Colors.white,
//           ),
//           onChanged: (query) => setState(() {
//             final lowercaseQuery = query.toLowerCase();
//             _submittedForms = _submittedForms
//                 .where((form) => form['formName']
//                     .toLowerCase()
//                     .contains(lowercaseQuery))
//                 .toList();
//           }),
//         ),
//       );

//   Widget _buildEmptyState() => Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.image_not_supported_outlined,
//                 size: 64, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               'No captured images yet',
//               style: TextStyle(
//                 fontSize: 18,
//                 color: Colors.grey[600],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             Text(
//               'Tap the button below to start capturing',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[400],
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );


// Future<void> _renameForm(String formId, String currentName) async {
//   final TextEditingController nameController = TextEditingController(text: currentName);
//   bool isNameValid = currentName.isNotEmpty;
//   bool isProcessing = false;

//   return showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: Text(
//             'Rename Form',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: nameController,
//                 enabled: !isProcessing,
//                 decoration: InputDecoration(
//                   hintText: 'Enter new form name',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.teal),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.teal),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide(color: Colors.teal, width: 2),
//                   ),
//                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 ),
//                 autofocus: true,
//                 cursorColor: Colors.teal,
//                 onChanged: (value) {
//                   setState(() {
//                     isNameValid = value.trim().isNotEmpty;
//                   });
//                 },
//               ),
//               if (isProcessing)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 16),
//                   child: Row(
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
//                           strokeWidth: 2,
//                         ),
//                       ),
//                       SizedBox(width: 12),
//                       Text('Renaming form...', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14)),
//               onPressed: isProcessing ? null : () => Navigator.pop(context),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Color(0xFF009688),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 disabledBackgroundColor: Colors.teal.withOpacity(0.5),
//               ),
//               child: Text('Rename', style: TextStyle(color: Colors.white, fontSize: 14)),
//               onPressed: (isNameValid && !isProcessing)
//                   ? () async {
//                       final newName = nameController.text.trim();
//                       if (newName.isNotEmpty) {
//                         setState(() {
//                           isProcessing = true;
//                         });
                        
//                         try {
//                           // Update the form name
//                           await _updateFormName(formId, newName);
                          
//                           // Get the navigator and scaffold messenger context before popping
//                           final navigatorContext = Navigator.of(context);
//                           final scaffoldContext = ScaffoldMessenger.of(context);
                          
//                           // Show the toast message BEFORE closing the dialog
//                           scaffoldContext.showSnackBar(
//                             SnackBar(
//                               content: Row(
//                                 children: [
//                                   Icon(Icons.check_circle, color: Colors.white, size: 20),
//                                   SizedBox(width: 12),
//                                   Text('Form Renamed', style: TextStyle(color: Colors.white)),
//                                 ],
//                                 ),
//                                 backgroundColor: const Color(0xFF66B2B2),
//                               behavior: SnackBarBehavior.floating,
//                               margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
//                               duration: Duration(seconds: 2),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           );
                          
//                           // Wait a tiny bit to ensure the snackbar is visible
//                           await Future.delayed(Duration(milliseconds: 100));
                          
//                           // Close the dialog
//                           if (context.mounted) {
//                             navigatorContext.pop();
//                           }
                          
//                         } catch (e) {
//                           // Reset processing state
//                           setState(() {
//                             isProcessing = false;
//                           });
                          
//                           // Show error message
//                           if (context.mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Row(
//                                   children: [
//                                     Icon(Icons.error, color: Colors.white, size: 20),
//                                     SizedBox(width: 12),
//                                     Expanded(
//                                       child: Text('Error renaming form: ${e.toString()}', 
//                                           style: TextStyle(color: Colors.white)),
//                                     ),
//                                   ],
//                                 ),
//                                 backgroundColor: Colors.red,
//                                 behavior: SnackBarBehavior.floating,
//                                 margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
//                                 duration: Duration(seconds: 3),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                             );
//                           }
//                         }
//                       }
//                     }
//                   : null,
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }

// // Alternative implementation using Common.showMessage
// Future<void> _renameFormAlt(String formId, String currentName) async {
//   final TextEditingController nameController = TextEditingController(text: currentName);
//   bool isNameValid = currentName.isNotEmpty;

//   return showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           bool isProcessing = false;

//           return AlertDialog(
//             backgroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             title: Text(
//               'Rename Form',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: nameController,
//                   enabled: !isProcessing,
//                   decoration: InputDecoration(
//                     hintText: 'Enter new form name',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide(color: Colors.teal),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide(color: Colors.teal),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                       borderSide: BorderSide(color: Colors.teal, width: 2),
//                     ),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                   ),
//                   autofocus: true,
//                   cursorColor: Colors.teal,
//                   onChanged: (value) {
//                     setState(() {
//                       isNameValid = value.trim().isNotEmpty;
//                     });
//                   },
//                 ),
//                 if (isProcessing)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16),
//                     child: Row(
//                       children: [
//                         const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
//                             strokeWidth: 2,
//                           ),
//                         ),
//                         SizedBox(width: 12),
//                         Text('Renaming form...', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//                       ],
//                     ),
//                   ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14)),
//                 onPressed: isProcessing ? null : () => Navigator.pop(context),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF009688),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                   disabledBackgroundColor: Colors.teal.withOpacity(0.5),
//                 ),
//                 child: Text('Rename', style: TextStyle(color: Colors.white, fontSize: 14)),
//                 onPressed: (isNameValid && !isProcessing)
//                     ? () async {
//                         final newName = nameController.text.trim();
//                         if (newName.isNotEmpty) {
//                           setState(() {
//                             isProcessing = true;
//                           });

//                           try {
//                             await _updateFormName(formId, newName);
                            
//                             // Close the dialog outside of setState
//                             if (context.mounted) {
//                               Navigator.pop(context);
//                             }

//                             // Show success message
//                             Common.showMessage(context, 'Form renamed');
//                           } catch (e) {
//                             setState(() {
//                               isProcessing = false;
//                             });

//                             // Show error message
//                             Common.showMessage(context, 'Error renaming form: ${e.toString()}', isError: true);
//                           }
//                         }
//                       }
//                     : null,
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }

// // Add this method to update the form name in Firebase
// Future<void> _updateFormName(String formId, String newName) async {
//   try {
//     setState(() => _isLoading = true);
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final uid = authProvider.user?.uid;
//     if (uid == null) {
//       throw Exception('User not logged in');
//     }

//     final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
//     await firebaseProvider.updateFormName(uid, formId, newName);

//     // Update the local list
//     setState(() {
//       final index = _submittedForms.indexWhere((form) => form['formId'] == formId);
//       if (index != -1) {
//         _submittedForms[index]['formName'] = newName;
//       }
//     });
//   } catch (e) {
//     Common.showMessage(context, 'Error renaming form: ${e.toString()}', isError: true);
//   } finally {
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
// }
// // Then, modify the _buildFormTile method to include the rename option in the popup menu
// Widget _buildFormTile(Map<String, dynamic> form) {
//   final formName = form['formName'] ?? 'Unnamed Form';
//   final formId = form['formId'];
//   final imageBase64 = form['imageBase64'];
  
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 12),
//     child: Container(
//       decoration: _boxDecoration,
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(12),
//         leading: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.memory(
//             base64Decode(imageBase64),
//             width: 60,
//             height: 60,
//             fit: BoxFit.cover,
//           ),
//         ),
//         title: Text(
//           formName,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//         trailing: PopupMenuButton<String>(
//           onSelected: (value) {
//             if (value == 'delete') {
//               _deleteForm(formId);
//             } else if (value == 'rename') {
//               _renameForm(formId, formName);
//             }
//           },
//           icon: Icon(Icons.more_vert, color: Color.fromRGBO(0, 150, 136, 1.0)),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           itemBuilder: (BuildContext context) => [
//             PopupMenuItem<String>(
//               value: 'rename',
//               child: ListTile(
//                 leading: Icon(Icons.edit, color: Color.fromRGBO(0, 150, 136, 1.0)),
//                 title: Text('Rename', style: TextStyle(color: Colors.black)),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
//                 horizontalTitleGap: 16.0,
//               ),
//             ),
//             PopupMenuItem<String>(
//               value: 'delete',
//               child: ListTile(
//                 leading: Icon(Icons.delete, color: Colors.red),
//                 title: Text('Delete', style: TextStyle(color: Colors.black)),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
//                 horizontalTitleGap: 16.0, 
//               ),
//             ),
//           ],
//           color: Colors.white,
//         ),
//         onTap: () {
//           // Save base64 image to temporary file and get path
//           final tempDir = Directory.systemTemp;
//           final tempFile = File('${tempDir.path}/$formId');
//           tempFile.writeAsBytesSync(base64Decode(imageBase64));
          
//           Navigator.pushNamed(
//             context,
//             '/field_edit_screen',
//             arguments: {
//               'imagePath': tempFile.path,
//               'formId': formId,
//               // Additional arguments will be loaded from Firebase
//             },
//           );
//         },
//       ),
//     ),
//   );
// }

// //   Widget _buildFormTile(Map<String, dynamic> form) {
// //     final formName = form['formName'] ?? 'Unnamed Form';
// //     final formId = form['formId'];
// //     final imageBase64 = form['imageBase64'];
    
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 12),
// //       child: Container(
// //         decoration: _boxDecoration,
// //         child: ListTile(
// //           contentPadding: const EdgeInsets.all(12),
// //           leading: ClipRRect(
// //             borderRadius: BorderRadius.circular(8),
// //             child: Image.memory(
// //               base64Decode(imageBase64),
// //               width: 60,
// //               height: 60,
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //           title: Text(
// //             formName,
// //             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// //           ),
// //           trailing: PopupMenuButton<String>(
// //             onSelected: (value) {
// //               if (value == 'delete') {
// //                 _deleteForm(formId);
// //               }
// //             },
// //             icon: Icon(Icons.more_vert, color: Color.fromRGBO(0, 150, 136, 1.0)
// // ),
// //             shape: RoundedRectangleBorder(
// //               borderRadius: BorderRadius.circular(8),
// //             ),
// //             itemBuilder: (BuildContext context) => [
// //               PopupMenuItem<String>(
// //                 value: 'delete',
// //                 child: ListTile(
// //                   leading: Icon(Icons.delete, color: Colors.red),
// //                   title: Text('Delete', style: TextStyle(color: Colors.black)),
// //                   contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
// //                   horizontalTitleGap: 16.0, 
// //                 ),
// //               ),
// //             ],
// //             color: Colors.white,
// //           ),
// //           onTap: () {
// //             // Save base64 image to temporary file and get path
// //             final tempDir = Directory.systemTemp;
// //             final tempFile = File('${tempDir.path}/$formId');
// //             tempFile.writeAsBytesSync(base64Decode(imageBase64));
            
// //             Navigator.pushNamed(
// //               context,
// //               '/field_edit_screen',
// //               arguments: {
// //                 'imagePath': tempFile.path,
// //                 'formId': formId,
// //                 // Additional arguments will be loaded from Firebase
// //               },
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }

//   Widget _buildFormList() => _submittedForms.isNotEmpty
//     ? AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: Scrollbar(
//           thumbVisibility: true, // Ensures the scrollbar is always visible when scrolling
//           child: ListView.builder(
//             key: ValueKey(_submittedForms.length),
//             itemCount: _submittedForms.length,
//             itemBuilder: (_, index) => _buildFormTile(_submittedForms[index]),
//           ),
//         ),
//       )
//     : _buildEmptyState();
//  Future<bool> _onWillPop() async {
//   SystemNavigator.pop(); // This will close the app
//   return false; // Returning false prevents the default back navigation
// }

// @override
// Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(        backgroundColor: Colors.grey[100],
//         appBar: AppBar(
//           elevation: 0,
//           backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
// ,
//           automaticallyImplyLeading: false, // Remove the back arrow icon

//           iconTheme: const IconThemeData(color: Colors.white), // Set back arrow color to white

//           title: Row(
//             children: [
//               // Hero(
//               //   tag: 'profile_icon',
//               //   child: Container(
//               //     padding: const EdgeInsets.all(8),
//               //     decoration: BoxDecoration(
//               //       color: Colors.white.withOpacity(0.2),
//               //       shape: BoxShape.circle,
//               //     ),
//               //     child:
//               //         const Icon(Icons.person, color: Colors.white, size: 24),
//               //   ),
//               // ),
//               const SizedBox(width: 12),
//               Text('Hi ${_userName.toUpperCase()}', style: _textStyle),
//             ],
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.refresh, color: Colors.white),
//               onPressed: _loadData,
//             ),
//             IconButton(
//               icon: const Icon(Icons.settings, color: Colors.white),
//               onPressed: () => Navigator.pushNamed(context, '/settings'),
//             ),
//           ],
//         ),
//         body: _isLoading
//             ? const Center(
//                 child: CircularProgressIndicator(
//                   valueColor: AlwaysStoppedAnimation<Color>(
//                       Colors.teal),
//                 ),
//               )
//             : ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: RefreshIndicator(
//                   onRefresh: _loadData,
//                   color: Color.fromRGBO(0, 150, 136, 1.0)
// ,
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         _buildSearchBar(),
//                         const SizedBox(height: 20),
//                         Expanded(child: _buildFormList()),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//         floatingActionButton: Padding(
//           padding: const EdgeInsets.only(bottom: 20.0),
//           child: FloatingActionButton.extended(
//             onPressed: () => Navigator.pushNamed(context, '/form_selection'),
//             icon: const Icon(Icons.add_a_photo, color: Colors.white),
//             label: const Text('New Form',
//                 style: TextStyle(
//                     color: Colors.white, fontWeight: FontWeight.w600)),
//             backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
// ,
//           ),
//         ),
//       ),
//       );
// }
//     }
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:formbot/helpers/firebase_handler.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:formbot/providers/authprovider.dart'; // Import AuthProvider
import 'package:formbot/screens/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // Import this for SystemNavigator.pop()
import 'package:intl/intl.dart'; // Add this import for date formatting


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  List<Map<String, dynamic>> _submittedForms = [];
  List<String> _capturedImages = [];
  String _userName = '';
  String _profileImageBase64 = ''; // Changed to store base64 image string

  String _img = '';
  //bool _isLoading = true;
  String _userEmail = ''; // Add this for displaying user email in drawer
  bool _isLoading = true;
  DateTime? _lastActivity; // Track user's last activity
  bool _isMultiSelectMode = false; // Track if multi-select mode is active
Set<String> _selectedFormIds = {}; // Store selected form IDs
  

  final _boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(style: BorderStyle.none),
  );

  final _textStyle = const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _checkUserActivity(); // Check activity on startup

  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

Future<void> _checkUserActivity() async {
  final prefs = await SharedPreferences.getInstance();
  final lastActivityString = prefs.getString('lastActivity');
  
  if (lastActivityString != null) {
    _lastActivity = DateTime.parse(lastActivityString);
    print('✅ Last activity loaded: $_lastActivity'); // Debug log
    final now = DateTime.now();
    final difference = now.difference(_lastActivity!);
    
    // Log out if inactive for 3 days (259200 seconds)
    if (difference.inSeconds > 259200) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signOut();
        Navigator.of(context).pushReplacementNamed('/userInput');
        Common.showMessage(context, 'You have been logged out due to inactivity', isError: false);
      }
    }
  } else {
    print('❌ No last activity found in SharedPreferences'); // Debug log
  }
  
  // Update last activity time
  _updateLastActivity();
}

Future<void> _updateLastActivity() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  await prefs.setString('lastActivity', now.toIso8601String());
  _lastActivity = now;
  print('✅ Last activity updated: $_lastActivity'); // Debug log
}
  Future<void> _loadData() async {
    try {
      _updateLastActivity(); // Update activity timestamp on data load
      await Future.wait([
        _loadSubmittedForms(),
        _loadUserInfo(),
        _loadCapturedImages(),
      ]);
      _animationController.forward();
    } catch (e) {
      Common.showMessage(context, 'Error loading data: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Future<void> _loadSubmittedForms() async {
  //   final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
  //   final forms = await firebaseProvider.getSubmittedForms();
  //   if (mounted) {
  //     setState(() => _submittedForms = forms);
  //   }
  // }

  Future<void> _loadSubmittedForms() async {
    try {
      final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final userId = authProvider.user?.uid;
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      // Fetch forms only for the current user
      final forms = await firebaseProvider.getSubmittedForms(userId: userId);
      
      if (mounted) {
        setState(() {
          // Only set forms that belong to the current user
          _submittedForms = forms.where((form) => form['userId'] == userId).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        Common.showMessage(
          context, 
          'Error loading forms: ${e.toString()}',
          isError: true
        );
      }
    }
  }

  // Updated to load user name and email
  // Future<void> _loadUserInfo() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
  //   if (mounted) {
  //     setState(() {
  //       _userName = prefs.getString('userName') ?? 'User';
  //       _userEmail = authProvider.user?.email ?? 'No email';
  //     });
  //   }
  // }
// Now, update the _loadUserInfo method to fetch the profile image URL
  Future<void> _loadUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  Map<String, dynamic>? userDetails = await authProvider.getUserDetails();
  
  if (mounted) {
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userEmail = authProvider.user?.email ?? 'No email';
      
      // Extract base64 data from data URI
      String? imageData = userDetails?['profileImageUrl'];
      if (imageData != null && imageData.contains(',')) {
        _profileImageBase64 = imageData.split(',').last;
      } else {
        _profileImageBase64 = imageData ?? '';
      }
    });
  }
}

   // Logout method
  Future<void> _logout() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/userInput');
      }
    } catch (e) {
      Common.showMessage(context, 'Error logging out: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _loadCapturedImages() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(
          () => _capturedImages = prefs.getStringList('capturedImages') ?? []);
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _userName = prefs.getString('userName') ?? 'User');
  }

  Future<void> _loadApiUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final boundingBoxUrl = prefs.getString('bounding_box_url') ?? 'http://10.64.26.89:8002/cv/form-detection-with-box/';
    final ocrTextUrl = prefs.getString('ocr_text_url') ?? 'http://10.64.26.89:8001/cv/ocr';
    final asrUrl = prefs.getString('asr_url') ?? 'http://10.64.26.83:8002/upload-audio-zip/';
    final llmUrl = prefs.getString('llm_url') ?? 'http://10.64.26.89:8036/get_llm_response_schemes';
    // Use the URLs as neededR
  }

  Future<void> _deleteForm(String formId) async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }
      final firebaseHandler = FirebaseHandler(); // Create an instance of FirebaseHandler
      await firebaseHandler.deleteForm(uid, formId); // Delete form from Firebase
      setState(() => _submittedForms.removeWhere((form) => form['formId'] == formId));
      Common.showMessage(context, 'Form Deleted successfully');
    } catch (e) {
      Common.showMessage(context, 'Error deleting form: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  

  Widget _buildSearchBar() => Container(
        decoration: _boxDecoration,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search forms...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (query) => setState(() {
            final lowercaseQuery = query.toLowerCase();
            _submittedForms = _submittedForms
                .where((form) => form['formName']
                    .toLowerCase()
                    .contains(lowercaseQuery))
                .toList();
          }),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No captured images yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Tap the button below to start capturing',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );


Future<void> _renameForm(String formId, String currentName) async {
  final TextEditingController nameController = TextEditingController(text: currentName);
  bool isNameValid = currentName.isNotEmpty;
  bool isProcessing = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Rename Form',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: !isProcessing,
                decoration: InputDecoration(
                  hintText: 'Enter new form name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                autofocus: true,
                cursorColor: Colors.teal,
                onChanged: (value) {
                  setState(() {
                    isNameValid = value.trim().isNotEmpty;
                  });
                },
              ),
              if (isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Renaming form...', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14)),
              onPressed: isProcessing ? null : () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF009688),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                disabledBackgroundColor: Colors.teal.withOpacity(0.5),
              ),
              child: Text('Rename', style: TextStyle(color: Colors.white, fontSize: 14)),
              onPressed: (isNameValid && !isProcessing)
                  ? () async {
                      final newName = nameController.text.trim();
                      if (newName.isNotEmpty) {
                        setState(() {
                          isProcessing = true;
                        });
                        
                        try {
                          // Update the form name
                          await _updateFormName(formId, newName);
                          
                          // Get the navigator and scaffold messenger context before popping
                          final navigatorContext = Navigator.of(context);
                          final scaffoldContext = ScaffoldMessenger.of(context);
                          
                          // Show the toast message BEFORE closing the dialog
                          scaffoldContext.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  SizedBox(width: 12),
                                  Text('Form Renamed', style: TextStyle(color: Colors.white)),
                                ],
                                ),
                                backgroundColor: const Color(0xFF66B2B2),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                              duration: Duration(seconds: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                          
                          // Wait a tiny bit to ensure the snackbar is visible
                          await Future.delayed(Duration(milliseconds: 100));
                          
                          // Close the dialog
                          if (context.mounted) {
                            navigatorContext.pop();
                          }
                          
                        } catch (e) {
                          // Reset processing state
                          setState(() {
                            isProcessing = false;
                          });
                          
                          // Show error message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.white, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Error renaming form: ${e.toString()}', 
                                          style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                duration: Duration(seconds: 3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    }
                  : null,
            ),
          ],
        ),
      );
    },
  );
}

// Alternative implementation using Common.showMessage
Future<void> _renameFormAlt(String formId, String currentName) async {
  final TextEditingController nameController = TextEditingController(text: currentName);
  bool isNameValid = currentName.isNotEmpty;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isProcessing = false;

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Rename Form',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !isProcessing,
                  decoration: InputDecoration(
                    hintText: 'Enter new form name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  autofocus: true,
                  cursorColor: Colors.teal,
                  onChanged: (value) {
                    setState(() {
                      isNameValid = value.trim().isNotEmpty;
                    });
                  },
                ),
                if (isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Renaming form...', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 14)),
                onPressed: isProcessing ? null : () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF009688),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.teal.withOpacity(0.5),
                ),
                child: Text('Rename', style: TextStyle(color: Colors.white, fontSize: 14)),
                onPressed: (isNameValid && !isProcessing)
                    ? () async {
                        final newName = nameController.text.trim();
                        if (newName.isNotEmpty) {
                          setState(() {
                            isProcessing = true;
                          });

                          try {
                            await _updateFormName(formId, newName);
                            
                            // Close the dialog outside of setState
                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            // Show success message
                            Common.showMessage(context, 'Form renamed');
                          } catch (e) {
                            setState(() {
                              isProcessing = false;
                            });

                            // Show error message
                            Common.showMessage(context, 'Error renaming form: ${e.toString()}', isError: true);
                          }
                        }
                      }
                    : null,
              ),
            ],
          );
        },
      );
    },
  );
}

// Add this method to update the form name in Firebase
Future<void> _updateFormName(String formId, String newName) async {
  try {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    await firebaseProvider.updateFormName(uid, formId, newName);

    // Update the local list
    setState(() {
      final index = _submittedForms.indexWhere((form) => form['formId'] == formId);
      if (index != -1) {
        _submittedForms[index]['formName'] = newName;
      }
    });
  } catch (e) {
    Common.showMessage(context, 'Error renaming form: ${e.toString()}', isError: true);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
// Then, modify the _buildFormTile method to include the rename option in the popup menu
Widget _buildFormTile(Map<String, dynamic> form) {
  final formName = form['formName'] ?? 'Unnamed Form';
  final formId = form['formId'];
  final imageBase64 = form['imageBase64'];
  final isSelected = _selectedFormIds.contains(formId);

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GestureDetector(
      onLongPress: () {
        setState(() {
          _isMultiSelectMode = true; // Enable multi-select mode
          _selectedFormIds.add(formId); // Select the current form
        });
      },
      onTap: () {
        if (_isMultiSelectMode) {
          setState(() {
            if (isSelected) {
              _selectedFormIds.remove(formId); // Deselect the form
            } else {
              _selectedFormIds.add(formId); // Select the form
            }
          });
        } else {
          // Normal tap behavior (e.g., navigate to form details)
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/$formId');
          tempFile.writeAsBytesSync(base64Decode(imageBase64));

          Navigator.pushNamed(
            context,
            '/field_edit_screen',
            arguments: {
              'imagePath': tempFile.path,
              'formId': formId,
            },
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.teal : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(imageBase64),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            formName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: !_isMultiSelectMode
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteForm(formId);
                    } else if (value == 'rename') {
                      _renameForm(formId, formName);
                    }
                  },
                  icon: Icon(Icons.more_vert, color: Color.fromRGBO(0, 150, 136, 1.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Color.fromRGBO(0, 150, 136, 1.0)),
                        title: Text('Rename', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                  color: Colors.white,
                )
              : null,
        ),
      ),
    ),
  );
}
// Widget _buildFormTile(Map<String, dynamic> form) {
//   final formName = form['formName'] ?? 'Unnamed Form';
//   final formId = form['formId'];
//   final imageBase64 = form['imageBase64'];
  
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 12),
//     child: Container(
//       decoration: _boxDecoration,
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(12),
//         leading: ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: Image.memory(
//             base64Decode(imageBase64),
//             width: 60,
//             height: 60,
//             fit: BoxFit.cover,
//           ),
//         ),
//         title: Text(
//           formName,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//         trailing: PopupMenuButton<String>(
//           onSelected: (value) {
//             if (value == 'delete') {
//               _deleteForm(formId);
//             } else if (value == 'rename') {
//               _renameForm(formId, formName);
//             }
//           },
//           icon: Icon(Icons.more_vert, color: Color.fromRGBO(0, 150, 136, 1.0)),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//           itemBuilder: (BuildContext context) => [
//             PopupMenuItem<String>(
//               value: 'rename',
//               child: ListTile(
//                 leading: Icon(Icons.edit, color: Color.fromRGBO(0, 150, 136, 1.0)),
//                 title: Text('Rename', style: TextStyle(color: Colors.black)),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
//                 horizontalTitleGap: 16.0,
//               ),
//             ),
//             PopupMenuItem<String>(
//               value: 'delete',
//               child: ListTile(
//                 leading: Icon(Icons.delete, color: Colors.red),
//                 title: Text('Delete', style: TextStyle(color: Colors.black)),
//                 contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
//                 horizontalTitleGap: 16.0, 
//               ),
//             ),
//           ],
//           color: Colors.white,
//         ),
//         onTap: () {
//           // Save base64 image to temporary file and get path
//           final tempDir = Directory.systemTemp;
//           final tempFile = File('${tempDir.path}/$formId');
//           tempFile.writeAsBytesSync(base64Decode(imageBase64));
          
//           Navigator.pushNamed(
//             context,
//             '/field_edit_screen',
//             arguments: {
//               'imagePath': tempFile.path,
//               'formId': formId,
//               // Additional arguments will be loaded from Firebase
//             },
//           );
//         },
//       ),
//     ),
//   );
// }
  Widget _buildFormList() => _submittedForms.isNotEmpty
    ? AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Scrollbar(
          thumbVisibility: true, // Ensures the scrollbar is always visible when scrolling
          child: ListView.builder(
            key: ValueKey(_submittedForms.length),
            itemCount: _submittedForms.length,
            itemBuilder: (_, index) => _buildFormTile(_submittedForms[index]),
          ),
        ),
      )
    : _buildEmptyState();
 Future<bool> _onWillPop() async {
  SystemNavigator.pop(); // This will close the app
  return false; // Returning false prevents the default back navigation
}
// Build the drawer for the home screen
Widget _buildDrawer() {
  return Drawer(
    child: Column(
      children: [
        // Make this entire header section clickable
        InkWell(
          onTap: () {
            // Close drawer first
            Navigator.pop(context);
            // Navigate to profile edit screen
            Navigator.pushNamed(context, '/profile_edit');
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color.fromRGBO(0, 150, 136, 1.0),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        _profileImageBase64.isNotEmpty
                          ? CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 30,
                              backgroundImage: MemoryImage(base64Decode(_profileImageBase64)),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 30,
                              child: Text(
                                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromRGBO(0, 150, 136, 1.0),
                                ),
                              ),
                            ),
                        // Add edit indicator
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 14,
                              color: Color.fromRGBO(0, 150, 136, 1.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _userName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _userEmail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  if (_lastActivity != null) 
                    Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(
                        'Last active: ${DateFormat('MMM d, yyyy').format(_lastActivity!)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            physics: BouncingScrollPhysics(),
            children: [
              // Home menu item with hover effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Color.fromRGBO(0, 150, 136, 0.2),
                  highlightColor: Color.fromRGBO(0, 150, 136, 0.1),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const ListTile(
                    leading: Icon(Icons.home, color: Color.fromRGBO(0, 150, 136, 1.0)),
                    title: Text(
                      'Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Settings menu item with hover effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: const Color.fromRGBO(0, 150, 136, 0.2),
                  highlightColor: const Color.fromRGBO(0, 150, 136, 0.1),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/settings');
                  },
                  child: const ListTile(
                    leading: Icon(Icons.settings, color: Color.fromRGBO(0, 150, 136, 1.0)),
                    title: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              
              const Divider(
                thickness: 1,
                height: 1,
              ),
              
              // Logout menu item with hover effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: Colors.red.withOpacity(0.2),
                  highlightColor: Colors.red.withOpacity(0.1),
                  onTap: () async {
                    Navigator.pop(context);
                    await _logout();
                  },
                  child: const ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  child: const Text(
                    'Note: You will be automatically logged out after 3 days of inactivity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> _deleteSelectedForms() async {
  try {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final firebaseHandler = FirebaseHandler();
    for (final formId in _selectedFormIds) {
      await firebaseHandler.deleteForm(uid, formId); // Delete each form
    }

    setState(() {
      _submittedForms.removeWhere((form) => _selectedFormIds.contains(form['formId']));
      _selectedFormIds.clear();
      _isMultiSelectMode = false;
    });

    Common.showMessage(context, 'Selected forms deleted successfully');
  } catch (e) {
    Common.showMessage(context, 'Error deleting forms: ${e.toString()}', isError: true);
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
@override
Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(        backgroundColor: Colors.grey[100],
      appBar: AppBar(
  elevation: 0,
  backgroundColor: const Color.fromRGBO(0, 150, 136, 1.0),
  automaticallyImplyLeading: true, // Ensure the drawer icon is visible
  iconTheme: const IconThemeData(color: Colors.white),
  titleSpacing: 0,
  title: Text(
    _isMultiSelectMode
        ? '${_selectedFormIds.length} Selected'
        : 'Hi ${_userName.toUpperCase()}',
    style: _textStyle,
  ),
  actions: [
    if (_isMultiSelectMode) ...[
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.white),
        onPressed: _selectedFormIds.isNotEmpty
            ? () async {
                await _deleteSelectedForms();
              }
            : null,
      ),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () {
          setState(() {
            _isMultiSelectMode = false;
            _selectedFormIds.clear();
          });
        },
      ),
    ],
    if (!_isMultiSelectMode) ...[
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _loadData,
      ),
    ],
    // Ensure the settings icon is always visible
    IconButton(
      icon: const Icon(Icons.settings, color: Colors.white),
      onPressed: () => Navigator.pushNamed(context, '/settings'),
    ),
  ],
),
        // appBar: AppBar(
        //   elevation: 0,
        //   backgroundColor: Color.fromRGBO(0, 150, 136, 1.0),
        //   automaticallyImplyLeading: true, // Show drawer icon

        //   //automaticallyImplyLeading: false, // Remove the back arrow icon

        //   iconTheme: const IconThemeData(color: Colors.white), // Set back arrow color to white
        //   titleSpacing: 0,

        //   title: Row(
        //     children: [
              
        //       Text('Hi ${_userName.toUpperCase()}', style: _textStyle),
        //     ],
        //   ),
        //   actions: [
        //     IconButton(
        //       icon: const Icon(Icons.refresh, color: Colors.white),
        //       onPressed: _loadData,
        //     ),
        //     IconButton(
        //       icon: const Icon(Icons.settings, color: Colors.white),
        //       onPressed: () => Navigator.pushNamed(context, '/settings'),
        //     ),
        //   ],
        // ),
        drawer: _buildDrawer(), // Add the drawer
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.teal),
                  ),
                )
              : ScaleTransition(
                  scale: _scaleAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: Color.fromRGBO(0, 150, 136, 1.0)
          ,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 20),
                          Expanded(child: _buildFormList()),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: FloatingActionButton.extended(
            onPressed: () {
              _updateLastActivity(); // Update activity when adding a new form
              Navigator.pushNamed(context, '/form_selection');
            },
            
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text('New Form',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
,
          ),
        ),
      ),
      );
}
    }
