// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import 'package:shared_preferences/shared_preferences.dart';

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});

//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   List<CameraDescription> cameras = [];
//   int selectedCameraIndex = 0;
//   bool isFlashOn = false;
//   final ImagePicker _picker = ImagePicker();
//   String? selectedForm; // State variable to store selectedForm

 

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _initializeCamera();
//   // }
//    @override
//   void initState() {
//     super.initState();
//     // Retrieve arguments immediately in initState
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//       setState(() {
//         selectedForm = args?['selectedForm'];
//       });
//       print("Selected Form in CameraScreen: $selectedForm");
//     });
//     _initializeCamera();
//   }



  

//   Future<void> _initializeCamera() async {
//     cameras = await availableCameras();
//     if (cameras.isEmpty) return;

//     _controller =
//         CameraController(cameras[selectedCameraIndex], ResolutionPreset.high);
//     try {
//       await _controller!.initialize();
//       if (mounted) {
//         setState(() {});
//       }
//     } catch (e) {
//       print('Error initializing camera: $e');
//     }
//   }

//   void _switchCamera() {
//     if (cameras.isEmpty) return;
//     selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
//     _initializeCamera();
//   }

//   void _toggleFlash() {
//     if (_controller == null) return;
//     setState(() {
//       isFlashOn = !isFlashOn;
//     });
//     _controller?.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
//   }

//   Future<void> _saveImage(String path) async {
//     final directory = await getApplicationDocumentsDirectory();
//     final imagePath =
//         '${directory.path}/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
//     final imageFile = File(path);
//     await imageFile.copy(imagePath);

//     final prefs = await SharedPreferences.getInstance();
//     List<String> capturedImages = prefs.getStringList('capturedImages') ?? [];
//     capturedImages.add(imagePath);
//     await prefs.setStringList('capturedImages', capturedImages);
//   }

//   Future<void> _pickImage() async {
//     try {
//       final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         if (!mounted) return;
//         Navigator.pushNamed(context, '/image_processing',
//             arguments: {
//               'imagePath': pickedFile.path,
//               'selectedForm': selectedForm, // Pass selectedForm
//             });
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

// //   @override
// //   Widget build(BuildContext context) {
// //     if (_controller == null || !_controller!.value.isInitialized) {
// //       return const Scaffold(
// //         body: Center(child: CircularProgressIndicator()),
// //       );
// //     }

// //     return Scaffold(
// //       backgroundColor: Colors.black,
// //       body: Stack(
// //         children: [
// //           Center(
// //             child: Padding(
// //               padding: const EdgeInsets.only(top: 85.0),
// //               child: CameraPreview(_controller!),
// //             ),
// //           ),
       
// //           Positioned(
// //             top: 40,
// //             left: 0,
// //             right: 0,
// //             child: Padding(
// //               padding: const EdgeInsets.symmetric(horizontal: 16),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   IconButton(
// //                     icon: Icon(
// //                       isFlashOn ? Icons.flash_on : Icons.flash_off,
// //                       color: Colors.white,
// //                       size: 28,
// //                     ),
// //                     onPressed: _toggleFlash,
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(
// //                       Icons.refresh,
// //                       color: Colors.white,
// //                       size: 28,
// //                     ),
// //                     onPressed: _switchCamera,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           Positioned(
// //             bottom: 30,
// //             left: 0,
// //             right: 0,
// //             child: Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 24),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   // Empty space on the left
// //                   const SizedBox(width: 60, height: 60),
                  
// //                   // Capture Button in center
// //                   GestureDetector(          
// //                     onTap: () async {
// //                       if (_controller == null || !_controller!.value.isInitialized)
// //                         return;
      
// //                       try {
// //                         final image = await _controller!.takePicture();
// //                         await _saveImage(image.path);
// //                         if (!mounted) return;
// //                         Navigator.pushNamed(
// //                           context,
// //                           '/image_processing',
// //                           arguments: image.path,
// //                         );
// //                       } catch (e) {
// //                         print('Error taking picture: $e');
// //                       }
// //                     },
// //                     child: Container(
// //                       width: 80,
// //                       height: 80,
// //                       decoration: BoxDecoration(
// //                         border: Border.all(color: Colors.white, width: 3),
// //                         shape: BoxShape.circle,
// //                       ),
// //                       child: Container(
// //                         margin: const EdgeInsets.all(3),
// //                         decoration: const BoxDecoration(
// //                           color: Colors.white,
// //                           shape: BoxShape.circle,
// //                         ),
// //                       ),
// //                     ),
// //                   ),
                  
// //                   // Photo Library button on the right
// //                   GestureDetector(
// //                     onTap: _pickImage,
// //                     child: Container(
// //                       width: 60,
// //                       height: 60,
// //                       child: const Icon(
// //                         Icons.photo_library,
// //                         color: Colors.white,
// //                         size: 28,
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// @override
// Widget build(BuildContext context) {
//   // final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//   // final selectedForm = args?['selectedForm']; // Retrieve selected form
//   // //print("Captured Image Path: ${image.path}");
//   //   print("Selected Form in CameraScreen: $selectedForm"); // Print the selected form

//   if (_controller == null || !_controller!.value.isInitialized) {
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     final selectedForm = args?['selectedForm']; // Retrieve selected form
//     print("Selected Form in camera screennnnnnnnnnnnnnnnnnnnnnnnnnnnnn: $selectedForm"); // Print the selected form
//     return const Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }

//   return Scaffold(
//     backgroundColor: Colors.black,
//     body: Stack(
//       children: [
//         Center(
//           child: Padding(
//             padding: const EdgeInsets.only(top: 85.0),
//             child: CameraPreview(_controller!),
//           ),
//         ),
//         Positioned(
//           bottom: 30,
//           left: 0,
//           right: 0,
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const SizedBox(width: 60, height: 60),
                
//                 GestureDetector(          
//                   onTap: () async {
//                     if (_controller == null || !_controller!.value.isInitialized) return;
    
//                     try {
//                       final image = await _controller!.takePicture();
//                       await _saveImage(image.path);
//                       if (!mounted) return;

//                       print("Selected Form before navigating to FieldEditScreen: $selectedForm"); // Print the selected form

//                       Navigator.pushNamed(
//                         context,
//                         '/image_processing',
//                         //'/field_edit_screen',
//                         arguments: {
//                           'imagePath': image.path,
//                           'selectedForm': selectedForm, // Pass selectedForm
//                         },
                        
//                       );
//                     } catch (e) {
//                       print('Error taking picture: $e');
//                     }
//                   },
//                   child: Container(
//                     width: 80,
//                     height: 80,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.white, width: 3),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Container(
//                       margin: const EdgeInsets.all(3),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: _pickImage,
//                   child: Container(
//                     width: 60,
//                     height: 60,
//                     child: const Icon(
//                       Icons.photo_library,
//                       color: Colors.white,
//                       size: 28,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }
// }
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/services.dart';
// //import 'package:pdf_render/pdf_render.dart';

// class CameraScreen extends StatefulWidget {
//   const CameraScreen({super.key});

//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   late List<CameraDescription> _cameras;
//   bool _isCameraInitialized = false;
//   final ImagePicker _picker = ImagePicker();
//   String? selectedForm;

//   @override
// void initState() {
//   super.initState();
//   _initializeCamera();

//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     setState(() {
//       selectedForm = args?['selectedForm'];
//     });
//     print("Selected Form in CameraScreen: $selectedForm");

//     // 🚀 Automatically trigger document scan after UI is built
//     Future.delayed(Duration(milliseconds: 500), () {
//       scanDocument();
//     });
//   });
// }

//   /// 📸 Initialize Camera
//   Future<void> _initializeCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras.isNotEmpty) {
//         _controller = CameraController(_cameras[0], ResolutionPreset.high);
//         await _controller!.initialize();
//         if (!mounted) return;
//         setState(() => _isCameraInitialized = true);
//       } else {
//         print("No available cameras found.");
//       }
//     } catch (e) {
//       print("Error initializing camera: $e");
//     }
//   }

//   /// 📃 Scan Document
//   /// 📃 Scan Document
// /// 📃 Scan Document with Debugging
// /// 📃 Scan Document with Debugging
// Future<void> scanDocument() async {
//   try {
//     print("🚀 Triggering document scan...");

//     // Ensure UI updates before scanning
//     if (!mounted) return;
//     setState(() {}); // Force UI refresh

//     final scannedDocuments = await FlutterDocScanner().getScannedDocumentAsImages(page: 1);
//     print("📸 Scanned Documents: $scannedDocuments");

//     final scannedPages = scannedDocuments['Uri']; // Extract scanned pages
//     print("🔍 Debug: scannedPages -> $scannedPages");
//     print("🔍 Debug: scannedPages Type -> ${scannedPages.runtimeType}");

//     if (scannedPages != null) {
//       String scannedPath = "";

//       if (scannedPages is List) {
//         // ✅ Case 1: If `scannedPages` is an actual list, extract the first URI
//         scannedPath = scannedPages.first['imageUri'] ?? "";
//       } else if (scannedPages is String) {
//         // ✅ Case 2: If `scannedPages` is a string, extract using regex
//         final match = RegExp(r'imageUri=(file://[^}]+)').firstMatch(scannedPages);
//         scannedPath = match?.group(1) ?? "";
//       }

//       print("✅ Extracted Image Path: $scannedPath");

//       if (scannedPath.isNotEmpty) {
//         final savedPath = await _saveImage(scannedPath); // Save image
//         print("💾 Image saved at: $savedPath");

//         if (!mounted) return;

//         // Ensure navigation happens after the UI is built
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           print("🛣 Navigating to /image_processing with imagePath: $savedPath");
//           Navigator.pushReplacementNamed(
//             context,
//             '/image_processing',
//             arguments: {
//               'imagePath': savedPath,
//               'selectedForm': selectedForm,
//             },
//           );
//         });
//       } else {
//         print("⚠️ Could not extract a valid scanned document path.");
//       }
//     } else {
//       print("⚠️ No valid scanned documents found. Retrying...");
//       Future.delayed(Duration(milliseconds: 500), () {
//         scanDocument(); // 🚀 Retry scanning if no document was captured
//       });
//     }
//   } on PlatformException catch (e) {
//     print("❌ PlatformException: Failed to scan document. Error: $e");
//   } catch (e) {
//     print("❌ Unexpected Error: $e");
//   }
// }

//   /// 💾 Save Scanned Image
//   Future<String> _saveImage(String scannedPath) async {
//   try {
//     print("💾 Saving scanned file from: $scannedPath");

//     // Convert file path to Uri and check existence
//     final File scannedFile = File(Uri.parse(scannedPath).toFilePath());
//     if (!await scannedFile.exists()) {
//       print("❌ ERROR: Scanned file does NOT exist at $scannedPath");
//       return "";
//     }

//     // Extract file extension from the original scanned file
//     String extension = scannedPath.split('.').last; 
//     if (extension.isEmpty || !['jpg', 'jpeg', 'png'].contains(extension.toLowerCase())) {
//       extension = "jpg"; // Default to jpg if extraction fails
//     }

//     // Define a new path with the correct extension
//     final String newPath = "/storage/emulated/0/Download/scanned_document.$extension";
//     await scannedFile.copy(newPath);
//     print("✅ File successfully saved at: $newPath");

//     return newPath;
//   } catch (e) {
//     print("❌ Error saving file: $e");
//     return "";
//   }
// }


//   /// 📂 Pick Image from Gallery
//   Future<void> _pickImage() async {
//     try {
//       final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         if (!mounted) return;
//         Navigator.pushNamed(
//           context,
//           '/image_processing',
//           arguments: {
//             'imagePath': pickedFile.path,
//             'selectedForm': selectedForm,
//           },
//         );
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//     }
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }

//   /// 📱 Build UI
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // 📷 Camera Preview
//           _isCameraInitialized && _controller != null
//               ? CameraPreview(_controller!)
//               : const Center(child: CircularProgressIndicator()),

//           // 🏷 Title
//           Positioned(
//             top: 85,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Text(
//                 'Scan a document',
//                 style: TextStyle(color: Colors.white, fontSize: 20),
//               ),
//             ),
//           ),

//           // 🎛 Bottom Controls
//           Positioned(
//             bottom: 30,
//             left: 0,
//             right: 0,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const SizedBox(width: 60, height: 60), // Placeholder
                  
//                   // 📸 Capture Button
//                   GestureDetector(
//                     onTap: scanDocument,
//                     child: Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.white, width: 3),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Container(
//                         margin: const EdgeInsets.all(3),
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                   ),

//                   // 📂 Open Gallery
//                   GestureDetector(
//                     onTap: _pickImage,
//                     child: const Icon(
//                       Icons.photo_library,
//                       color: Colors.white,
//                       size: 32,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  String? selectedForm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      setState(() {
        selectedForm = args?['selectedForm'];
      });
      print("Selected Form in CameraScreen: $selectedForm");

      // Automatically trigger document scan after UI is built
      Future.delayed(Duration(milliseconds: 500), () {
        scanDocument();
      });
    });
  }

  /// Scan Document
  Future<void> scanDocument() async {
    try {
      print("🚀 Triggering document scan...");

      final scannedDocuments = await FlutterDocScanner().getScannedDocumentAsImages(page: 1);
      print("📸 Scanned Documents: $scannedDocuments");

      final scannedPages = scannedDocuments['Uri'];
      print("🔍 Debug: scannedPages -> $scannedPages");

      if (scannedPages != null) {
        String scannedPath = "";

        if (scannedPages is List) {
          scannedPath = scannedPages.first['imageUri'] ?? "";
        } else if (scannedPages is String) {
          final match = RegExp(r'imageUri=(file://[^}]+)').firstMatch(scannedPages);
          scannedPath = match?.group(1) ?? "";
        }

        print("✅ Extracted Image Path: $scannedPath");

        if (scannedPath.isNotEmpty) {
          final savedPath = await _saveImage(scannedPath);
          print("💾 Image saved at: $savedPath");

          if (!mounted) return;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(
              context,
              '/image_processing',
              arguments: {
                'imagePath': savedPath,
                'selectedForm': selectedForm,
              },
            );
          });
        }
      }
    } on PlatformException catch (e) {
      print("❌ PlatformException: Failed to scan document. Error: $e");
    } catch (e) {
      print("❌ Unexpected Error: $e");
    }
  }

  /// Save Scanned Image
  Future<String> _saveImage(String scannedPath) async {
    try {
      final File scannedFile = File(Uri.parse(scannedPath).toFilePath());
      if (!await scannedFile.exists()) {
        print("❌ ERROR: Scanned file does NOT exist at $scannedPath");
        return "";
      }

      String extension = scannedPath.split('.').last;
      if (extension.isEmpty || !['jpg', 'jpeg', 'png'].contains(extension.toLowerCase())) {
        extension = "jpg";
      }

      final String newPath = "/storage/emulated/0/Download/scanned_document.$extension";
      await scannedFile.copy(newPath);
      print("✅ File successfully saved at: $newPath");

      return newPath;
    } catch (e) {
      print("❌ Error saving file: $e");
      return "";
    }
  }

  /// Pick Image from Gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        Navigator.pushNamed(
          context,
          '/image_processing',
          arguments: {
            'imagePath': pickedFile.path,
            'selectedForm': selectedForm,
          },
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CircularProgressIndicator()),

          // Positioned(
          //   top: 85,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: Text(
          //       'Scan a document',
          //       style: TextStyle(color: Colors.white, fontSize: 20),
          //     ),
          //   ),
          // ),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60, height: 60),

                  GestureDetector(
                    onTap: scanDocument,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _pickImage,
                    child: const Icon(
                      Icons.photo_library,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
