// import 'package:flutter/material.dart';

// import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

// import 'package:image_picker/image_picker.dart';

// import 'package:flutter/services.dart';

// import 'dart:io';

// import 'package:path_provider/path_provider.dart';



// // Added imports

// import 'dart:convert';

// import 'package:http/http.dart' as http;

// import 'package:mime/mime.dart';

// import 'package:http_parser/http_parser.dart';

// import 'package:provider/provider.dart';

// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:formbot/providers/firebaseprovider.dart';

// import 'package:formbot/providers/authprovider.dart';

// // If DatabaseHelper is crucial for logging image paths, uncomment and ensure it's correctly set up.

// // import 'package:formbot/helpers/database_helper.dart';



// class CameraScreen extends StatefulWidget {

//   const CameraScreen({super.key});



//   @override

//   _CameraScreenState createState() => _CameraScreenState();

// }



// class _CameraScreenState extends State<CameraScreen> {

//   final ImagePicker _picker = ImagePicker();

//   String? selectedForm;

//   bool _isScanning = false; // Renamed from _isLoading for clarity

//   bool _scanFailed = false;

//   String _errorMessage = '';



//   // If DatabaseHelper is used:

//   // final DatabaseHelper _dbHelper = DatabaseHelper();



//   @override

//   void initState() {

//     super.initState();

//     WidgetsBinding.instance.addPostFrameCallback((_) {

//       final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

//       if (mounted) {

//         setState(() {

//           selectedForm = args?['selectedForm'];

//         });

//       }

//       print("Selected Form in CameraScreen: $selectedForm");



//       Future.delayed(const Duration(milliseconds: 200), () {

//         if (mounted) {

//           _launchScanner();

//         }

//       });

//     });

//   }



//   Future<void> _launchScanner() async {

//     if (_isScanning) return;



//     if (mounted) {

//       setState(() {

//         _isScanning = true;

//         _scanFailed = false;

//         _errorMessage = '';

//       });

//     }



//     try {

//       final scannedDocuments = await FlutterDocScanner().getScannedDocumentAsImages(page: 1);



//       if (mounted) {

//         await _handleScannerResult(scannedDocuments);

//       }

//     } on PlatformException catch (e) {

//       print("❌ PlatformException: Failed to scan document. Error: $e");

//       if (mounted) {

//         setState(() {

//           _isScanning = false;

//           _scanFailed = true;

//           _errorMessage = 'Scanner error: ${e.message ?? "Platform error"}';

//         });

//       }

//     } catch (e) {

//       print("❌ Unexpected Error during scan: $e");

//       if (mounted) {

//         setState(() {

//           _isScanning = false;

//           _scanFailed = true;

//           _errorMessage = 'Unexpected error occurred during scan';

//         });

//       }

//     }

//   }



//   Future<void> _handleScannerResult(Map<dynamic, dynamic> scannedDocuments) async {

//     try {

//       print("📸 Scanned Documents: $scannedDocuments");

//       final scannedPages = scannedDocuments['Uri'];



//       if (scannedPages == null) {

//         if (mounted) {

//           setState(() {

//             _isScanning = false; // User likely cancelled

//             _scanFailed = false; // Not an error, but no document

//             _errorMessage = 'Scan cancelled or no document found.';

//           });

//         }

//         return;

//       }



//       String scannedPath = "";

//       if (scannedPages is List && scannedPages.isNotEmpty) {

//         scannedPath = scannedPages.first['imageUri'] ?? "";

//       } else if (scannedPages is String) {

//         final match = RegExp(r'imageUri=(file://[^}]+)').firstMatch(scannedPages);

//         scannedPath = match?.group(1) ?? "";

//       }



//       if (scannedPath.isEmpty) {

//         if (mounted) {

//           setState(() {

//             _isScanning = false;

//             _scanFailed = true;

//             _errorMessage = 'Could not extract image path from scan.';

//           });

//         }

//         return;

//       }



//       final savedPath = await _saveImage(scannedPath);

//       if (savedPath.isEmpty) {

//         if (mounted) {

//           setState(() {

//             _isScanning = false;

//             _scanFailed = true;

//             _errorMessage = 'Failed to save scanned image.';

//           });

//         }

//         return;

//       }



//       // Directly process and navigate

//       await _processImageAndNavigate(savedPath, selectedForm);



//     } catch (e) {

//       print("❌ Error processing document result: $e");

//       if (mounted) {

//         setState(() {

//           _isScanning = false;

//           _scanFailed = true;

//           _errorMessage = 'Error processing scanned document.';

//         });

//       }

//     }

//   }



//   // New method: Combines ImageProcessingScreen's backend logic and navigation

//   Future<void> _processImageAndNavigate(String imagePath, String? currentSelectedForm) async {

//     if (!mounted) return;

//     // _isScanning is already true or should be set if this is called independently

//     if (!_isScanning) {

//         setState(() => _isScanning = true);

//     }



//     try {

//       final prefs = await SharedPreferences.getInstance();

//       final boundingBoxUrl = prefs.getString('bounding_box_url');



//       if (boundingBoxUrl == null || boundingBoxUrl.isEmpty) {

//         if (mounted) {

//           setState(() {

//             _scanFailed = true;

//             _errorMessage = 'Bounding box URL is not set in settings.';

//             _isScanning = false;

//           });

//         }

//         return;

//       }



//       // If _dbHelper is used:

//       // await _dbHelper.insertImagePath(imagePath);



//       var request = http.MultipartRequest('POST', Uri.parse(boundingBoxUrl));

//       final mimeTypeData = lookupMimeType(imagePath, headerBytes: [0xFF, 0xD8])?.split('/');



//       request.files.add(

//         await http.MultipartFile.fromPath(

//           'file', // API expects 'file'

//           imagePath,

//           contentType: mimeTypeData != null ? MediaType(mimeTypeData[0], mimeTypeData[1]) : null,

//         ),

//       );



//       final response = await request.send();

//       final responseData = await response.stream.bytesToString();

//       var decodedResponse = jsonDecode(responseData);



//       if (!mounted) return;



//       if (response.statusCode == 200) {

//         final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);

//         final authProvider = Provider.of<AuthProvider>(context, listen: false);



//         if (authProvider.user == null) {

//           if (mounted) {

//             setState(() {

//               _scanFailed = true;

//               _errorMessage = 'User not logged in. Cannot save form.';

//               _isScanning = false;

//             });

//           }

//           return;

//         }



//         List<dynamic> apiBoundingBoxes = decodedResponse['bounding_boxes'] ?? [];

//         List<Map<String, dynamic>> standardizedBoxes = apiBoundingBoxes.map<Map<String, dynamic>>((box) {

//             return {

//               'x_center': (box['x_center'] as num?)?.toDouble() ?? 0.0,

//               'y_center': (box['y_center'] as num?)?.toDouble() ?? 0.0,

//               'width': (box['width'] as num?)?.toDouble() ?? 0.0,

//               'height': (box['height'] as num?)?.toDouble() ?? 0.0,

//               'class': box['class']?.toString() ?? 'Unknown Field',

//             };

//         }).toList();



//         if (standardizedBoxes.isEmpty) {

//             if (mounted) {

//                 setState(() {

//                     _scanFailed = true;

//                     _errorMessage = 'No form fields detected by the API.';

//                     _isScanning = false;

//                 });

//             }

//             return;

//         }



//         final formId = await firebaseProvider.saveFormWithDetails(

//           uid: authProvider.user!.uid,

//           imagePath: imagePath,

//           boundingBoxes: standardizedBoxes,

//           selectedField: '',

//           ocrText: '',

//           chatMessages: [],

//           selectedForm: currentSelectedForm ?? 'Unknown Form',

//         );



//         Navigator.pushReplacementNamed(

//           context,

//           '/field_edit_screen',

//           arguments: {

//             'imagePath': imagePath,

//             'bounding_boxes': standardizedBoxes,

//             'formId': formId,

//             'selectedForm': currentSelectedForm,

//           },

//         );

//         // No need to set _isScanning = false here due to navigation

//       } else {

//         String apiErrorMessage = decodedResponse['message'] ?? 'Error processing image (API Status: ${response.statusCode})';

//          if (mounted) {

//             setState(() {

//               _scanFailed = true;

//               _errorMessage = apiErrorMessage;

//               _isScanning = false;

//             });

//           }

//       }

//     } catch (e) {

//       print("Error in _processImageAndNavigate: $e");

//       if (mounted) {

//         setState(() {

//           _scanFailed = true;

//           _errorMessage = 'An unexpected error occurred.';

//           _isScanning = false;

//         });

//       }

//     }

//     // No finally block to set _isScanning = false if navigation occurs

//   }



//   Future<String> _saveImage(String scannedPath) async {

//     try {

//       final File scannedFile = File(Uri.parse(scannedPath).toFilePath());

//       if (!await scannedFile.exists()) {

//         print("❌ ERROR: Scanned file does NOT exist at $scannedPath");

//         return "";

//       }



//       DateTime now = DateTime.now();

//       String formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";

//       //String formName = "FormScan_${selectedForm?.replaceAll(' ', '_') ?? 'Unknown'}_$formattedDate";

//       String formName = "Form_$formattedDate"; // Changed naming convention



//       Directory? directory = await getExternalStorageDirectory();

//       if (directory == null) {

//         print("❌ Error: Could not get external storage directory.");

//         return "";

//       }

//       String newPath = "${directory.path}/${formName}.jpg";



//       await scannedFile.copy(newPath);

//       print("✅ File successfully saved at: $newPath");

//       return newPath;

//     } catch (e) {

//       print("❌ Error saving file: $e");

//       return "";

//     }

//   }



//   Future<void> _pickImage() async { // Gallery flow remains unchanged

//     try {

//       final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//       if (pickedFile != null && mounted) {

//         Navigator.pushReplacementNamed( // Using pushReplacementNamed to align with scanner flow

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

//       if (mounted) {

//         setState(() {

//           _scanFailed = true; // Re-use existing error state for gallery pick errors

//           _errorMessage = 'Error selecting image from gallery.';

//         });

//       }

//     }

//   }



//   @override

//   Widget build(BuildContext context) {

//     return Scaffold(

//       backgroundColor: Colors.black,

//       body: Center(

//         child: Column(

//           mainAxisAlignment: MainAxisAlignment.center,

//           children: [

//             if (_isScanning)

//               const CircularProgressIndicator(color: Colors.white),

//             const SizedBox(height: 20),

//             if (_isScanning)

//               const Text(

//                 'Processing image...', // Updated message

//                 style: TextStyle(color: Colors.white, fontSize: 18),

//               )

//             else if (_scanFailed)

//               Padding(

//                 padding: const EdgeInsets.symmetric(horizontal: 20.0),

//                 child: Column(

//                   children: [

//                     const Icon(Icons.error_outline, color: Colors.red, size: 40),

//                     const SizedBox(height: 10),

//                     Text(

//                       _errorMessage.isNotEmpty ? _errorMessage : 'An error occurred.',

//                       style: const TextStyle(color: Colors.white, fontSize: 16),

//                       textAlign: TextAlign.center,

//                     ),

//                     const SizedBox(height: 20),

//                     ElevatedButton(

//                       onPressed: _launchScanner, // Retry scanning

//                       style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),

//                       child: const Text('Try Scan Again', style: TextStyle(color: Colors.white)),

//                     ),

//                      const SizedBox(height: 10),

//                     ElevatedButton(

//                       onPressed: () => Navigator.of(context).pop(), // Go back

//                       style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),

//                       child: const Text('Cancel', style: TextStyle(color: Colors.white)),

//                     ),

//                   ],

//                 ),

//               )

//             else // Initial state or after successful scan (before navigation)

//               Column(

//                 children: [

//                   const Text(

//                     'Ready to scan or select from gallery.',

//                     style: TextStyle(color: Colors.white, fontSize: 16),

//                     textAlign: TextAlign.center,

//                   ),

//                   const SizedBox(height: 20),

//                   Row(

//                     mainAxisAlignment: MainAxisAlignment.center,

//                     children: [

//                       ElevatedButton.icon(

//                         onPressed: _launchScanner,

//                         icon: const Icon(Icons.document_scanner),

//                         label: const Text('Scan Document'),

//                         style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),

//                       ),

//                       const SizedBox(width: 20),

//                       ElevatedButton.icon(

//                         onPressed: _pickImage,

//                         icon: const Icon(Icons.photo_library),

//                         label: const Text('From Gallery'),

//                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),

//                       ),

//                     ],

//                   ),

//                 ],

//               ),

//           ],

//         ),

//       ),

//     );

//   }

// }

import 'package:flutter/material.dart';

import 'package:flutter_doc_scanner/flutter_doc_scanner.dart';

import 'package:image_picker/image_picker.dart';

import 'package:flutter/services.dart';

import 'dart:io';

import 'package:path_provider/path_provider.dart';



// Added imports

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mime/mime.dart';

import 'package:http_parser/http_parser.dart';

import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:formbot/providers/firebaseprovider.dart';

import 'package:formbot/providers/authprovider.dart';

// Image compression import

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'dart:typed_data';

// If DatabaseHelper is crucial for logging image paths, uncomment and ensure it's correctly set up.

// import 'package:formbot/helpers/database_helper.dart';



class CameraScreen extends StatefulWidget {

  const CameraScreen({super.key});



  @override

  _CameraScreenState createState() => _CameraScreenState();

}



class _CameraScreenState extends State<CameraScreen> {

  final ImagePicker _picker = ImagePicker();
  int _boundingBoxMs = 0;


  String? selectedForm;

  bool _isScanning = false;

  bool _scanFailed = false;

  String _errorMessage = '';

  bool _isInitializing = true; // Add flag to track initialization
  



  // If DatabaseHelper is used:

  // final DatabaseHelper _dbHelper = DatabaseHelper();



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {

      final args =

          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (mounted) {

        setState(() {

          selectedForm = args?['selectedForm'];

          _isInitializing = false; // Set to false before launching

        });

      }

      print("Selected Form in CameraScreen: $selectedForm");



      // Launch scanner immediately

      _launchScanner();

    });

  }



  // Image compression method

  Future<String> _compressImage(String imagePath) async {

    try {

      final File originalFile = File(imagePath);

      if (!await originalFile.exists()) {

        print("❌ ERROR: Original file does not exist at $imagePath");

        return imagePath; // Return original path if file doesn't exist

      }



      // Get file size before compression

      final int originalSize = await originalFile.length();

      print(

          "📏 Original image size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB");



      // Create compressed file path

      final String dir = originalFile.parent.path;

      final String name = originalFile.uri.pathSegments.last;

      final String tempCompressedPath = '$dir/tmp_compressed_$name';



      // Compress the image aggressively to stay under Firestore's 1MB limit

      final XFile? compressedFile =

          await FlutterImageCompress.compressAndGetFile(

        imagePath,

        tempCompressedPath,

        quality:

            40, // Reduced quality for smaller file size (0-100, where 100 is highest quality)

        minWidth: 1024, // Reduced maximum width

        minHeight: 768, // Reduced maximum height

        format:

            CompressFormat.jpeg, // Always save as JPEG for better compression

      );



      if (compressedFile != null) {

        final File tempFile = File(compressedFile.path);

        final int compressedSize = await tempFile.length();

        print(

            "📏 Compressed image size: ${(compressedSize / 1024 / 1024).toStringAsFixed(2)} MB");

        // Delete the original file, then rename the compressed temp file
        // to the original file name so no "compressed_" prefix leaks into
        // the Firestore document ID derived from this file name.
        try {

          await originalFile.delete();

          print("🗑️ Original file deleted to save space");

        } catch (e) {

          print("⚠️ Could not delete original file: $e");

        }

        final String finalPath = '$dir/$name';

        final File finalFile = await tempFile.rename(finalPath);

        print("✅ Image compressed successfully: ${finalFile.path}");

        return finalFile.path;

      } else {

        print("❌ Image compression failed, using original image");

        return imagePath;

      }

    } catch (e) {

      print("❌ Error during image compression: $e");

      return imagePath; // Return original path if compression fails

    }

  }



  Future<void> _launchScanner() async {

    if (_isScanning) return;



    if (mounted) {

      setState(() {

        _isScanning = true;

        _scanFailed = false;

        _errorMessage = '';

      });

    }



    try {

      final scannedDocuments = await FlutterDocScanner().getScannedDocumentAsImages(

        page: 1,

        // The plugin's native UI is controlled by the underlying native SDK

        // We can only control the number of pages to scan

      );



      if (mounted) {

        await _handleScannerResult(scannedDocuments);

      }

    } on PlatformException catch (e) {

      print("❌ PlatformException: Failed to scan document. Error: $e");

      if (mounted) {

        setState(() {

          _isScanning = false;

          _scanFailed = true;

          _errorMessage = 'Scanner error: ${e.message ?? "Platform error"}';

        });

      }

    } catch (e) {

      print("❌ Unexpected Error during scan: $e");

      if (mounted) {

        setState(() {

          _isScanning = false;

          _scanFailed = true;

          _errorMessage = 'Unexpected error occurred during scan';

        });

      }

    }

  }



  Future<void> _handleScannerResult(

      Map<dynamic, dynamic> scannedDocuments) async {

    try {

      print("📸 Scanned Documents: $scannedDocuments");

      final scannedPages = scannedDocuments['Uri'];



      if (scannedPages == null) {

        if (mounted) {

          setState(() {

            _isScanning = false; // User likely cancelled

            _scanFailed = false; // Not an error, but no document

            _errorMessage = 'Scan cancelled or no document found.';

          });

        }

        return;

      }



      String scannedPath = "";

      if (scannedPages is List && scannedPages.isNotEmpty) {

        scannedPath = scannedPages.first['imageUri'] ?? "";

      } else if (scannedPages is String) {

        final match =

            RegExp(r'imageUri=(file://[^}]+)').firstMatch(scannedPages);

        scannedPath = match?.group(1) ?? "";

      }



      if (scannedPath.isEmpty) {

        if (mounted) {

          setState(() {

            _isScanning = false;

            _scanFailed = true;

            _errorMessage = 'Could not extract image path from scan.';

          });

        }

        return;

      }



      final savedPath = await _saveImage(scannedPath);

      if (savedPath.isEmpty) {

        if (mounted) {

          setState(() {

            _isScanning = false;

            _scanFailed = true;

            _errorMessage = 'Failed to save scanned image.';

          });

        }

        return;

      }



      // Compress the image after saving

      final compressedPath = await _compressImage(savedPath);



      // Directly process and navigate with compressed image

      await _processImageAndNavigate(compressedPath, selectedForm);

    } catch (e) {

      print("❌ Error processing document result: $e");

      if (mounted) {

        setState(() {

          _isScanning = false;

          _scanFailed = true;

          _errorMessage = 'Error processing scanned document.';

        });

      }

    }

  }



  // New method: Combines ImageProcessingScreen's backend logic and navigation

  Future<void> _processImageAndNavigate(

      String imagePath, String? currentSelectedForm) async {

    if (!mounted) return;

    // _isScanning is already true or should be set if this is called independently

    if (!_isScanning) {

      setState(() => _isScanning = true);

    }



    try {

      final prefs = await SharedPreferences.getInstance();

      final boundingBoxUrl = prefs.getString('bounding_box_url');



      if (boundingBoxUrl == null || boundingBoxUrl.isEmpty) {

        if (mounted) {

          setState(() {

            _scanFailed = true;

            _errorMessage = 'Bounding box URL is not set in settings.';

            _isScanning = false;

          });

        }

        return;

      }



      // If _dbHelper is used:

      // await _dbHelper.insertImagePath(imagePath);



      var request = http.MultipartRequest('POST', Uri.parse(boundingBoxUrl));
      final mimeTypeData =
          lookupMimeType(imagePath, headerBytes: [0xFF, 0xD8])?.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // API expects 'file'
          imagePath,
          contentType: mimeTypeData != null
              ? MediaType(mimeTypeData[0], mimeTypeData[1])
              : null,
        ),
      );

      final bboxStopwatch = Stopwatch()..start();

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      bboxStopwatch.stop();
      _boundingBoxMs = bboxStopwatch.elapsedMilliseconds;
      print('BBox duration: $_boundingBoxMs ms');

      var decodedResponse = jsonDecode(responseData);

      if (!mounted) return;



      if (response.statusCode == 200) {

        final firebaseProvider =

            Provider.of<FirebaseProvider>(context, listen: false);

        final authProvider = Provider.of<AuthProvider>(context, listen: false);



        if (authProvider.user == null) {

          if (mounted) {

            setState(() {

              _scanFailed = true;

              _errorMessage = 'User not logged in. Cannot save form.';

              _isScanning = false;

            });

          }

          return;

        }



        List<dynamic> apiBoundingBoxes =

            decodedResponse['bounding_boxes'] ?? [];

        List<Map<String, dynamic>> standardizedBoxes =

            apiBoundingBoxes.map<Map<String, dynamic>>((box) {

          return {

            'x_center': (box['x_center'] as num?)?.toDouble() ?? 0.0,

            'y_center': (box['y_center'] as num?)?.toDouble() ?? 0.0,

            'width': (box['width'] as num?)?.toDouble() ?? 0.0,

            'height': (box['height'] as num?)?.toDouble() ?? 0.0,

            'class': box['class']?.toString() ?? 'Unknown Field',

          };

        }).toList();



        if (standardizedBoxes.isEmpty) {

          if (mounted) {

            setState(() {

              _scanFailed = true;

              _errorMessage = 'No form fields detected by the API.';

              _isScanning = false;

            });

          }

          return;

        }



        final formId = await firebaseProvider.saveFormWithDetails(

          uid: authProvider.user!.uid,

          imagePath: imagePath,

          boundingBoxes: standardizedBoxes,

          selectedField: '',

          ocrText: '',

          chatMessages: [],

          selectedForm: currentSelectedForm ?? 'Unknown Form',

          boundingBoxMs: _boundingBoxMs,

        );



        Navigator.pushReplacementNamed(

          context,

          '/field_edit_screen',

          arguments: {

            'imagePath': imagePath,

            'bounding_boxes': standardizedBoxes,

            'formId': formId,

            'selectedForm': currentSelectedForm,

          },

        );

        // No need to set _isScanning = false here due to navigation

      } else {

        String apiErrorMessage = decodedResponse['message'] ??

            'Error processing image (API Status: ${response.statusCode})';

        if (mounted) {

          setState(() {

            _scanFailed = true;

            _errorMessage = apiErrorMessage;

            _isScanning = false;

          });

        }

      }

    } catch (e) {

      print("Error in _processImageAndNavigate: $e");

      if (mounted) {

        setState(() {

          _scanFailed = true;

          _errorMessage = 'An unexpected error occurred.';

          _isScanning = false;

        });

      }

    }

    // No finally block to set _isScanning = false if navigation occurs

  }



  Future<String> _saveImage(String scannedPath) async {

    try {

      final File scannedFile = File(Uri.parse(scannedPath).toFilePath());

      if (!await scannedFile.exists()) {

        print("❌ ERROR: Scanned file does NOT exist at $scannedPath");

        return "";

      }



      DateTime now = DateTime.now();

      String formattedDate =

          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";

      //String formName = "FormScan_${selectedForm?.replaceAll(' ', '_') ?? 'Unknown'}_$formattedDate";

      String formName = "Form_$formattedDate"; // Changed naming convention



      Directory? directory = await getExternalStorageDirectory();

      if (directory == null) {

        print("❌ Error: Could not get external storage directory.");

        return "";

      }

      String newPath = "${directory.path}/${formName}.jpg";



      await scannedFile.copy(newPath);

      print("✅ File successfully saved at: $newPath");

      return newPath;

    } catch (e) {

      print("❌ Error saving file: $e");

      return "";

    }

  }



  Future<void> _pickImage() async {

    // Gallery flow with compression

    try {

      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && mounted) {

        // Compress the gallery image before navigation

        final compressedPath = await _compressImage(pickedFile.path);



        Navigator.pushReplacementNamed(

          // Using pushReplacementNamed to align with scanner flow

          context,

          '/image_processing',

          arguments: {

            'imagePath': compressedPath,

            'selectedForm': selectedForm,

          },

        );

      }

    } catch (e) {

      print('Error picking image: $e');

      if (mounted) {

        setState(() {

          _scanFailed =

              true; // Re-use existing error state for gallery pick errors

          _errorMessage = 'Error selecting image from gallery.';

        });

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            if (_isScanning || _isInitializing)

              const CircularProgressIndicator(color: Colors.white),

            const SizedBox(height: 20),

            if (_isScanning || _isInitializing)

              const Text(

                'Preparing scanner...', // Updated message

                style: TextStyle(color: Colors.white, fontSize: 18),

              )

            else if (_scanFailed)

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 20.0),

                child: Column(

                  children: [

                    const Icon(Icons.error_outline,

                        color: Colors.red, size: 40),

                    const SizedBox(height: 10),

                    Text(

                      _errorMessage.isNotEmpty

                          ? _errorMessage

                          : 'An error occurred.',

                      style: const TextStyle(color: Colors.white, fontSize: 16),

                      textAlign: TextAlign.center,

                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(

                      onPressed: () {

                        setState(() {

                          _isInitializing = false;

                          _scanFailed = false;

                        });

                        _launchScanner();

                      },

                      style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.teal),

                      child: const Text('Try Scan Again',

                          style: TextStyle(color: Colors.white)),

                    ),

                    const SizedBox(height: 10),

                    ElevatedButton(

                      onPressed: () => Navigator.of(context).pop(), // Go back

                      style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.grey),

                      child: const Text('Cancel',

                          style: TextStyle(color: Colors.white)),

                    ),

                  ],

                ),

              ),

          ],

        ),

      ),

    );

  }

}

