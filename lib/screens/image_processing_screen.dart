// import 'dart:io';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:formbot/helpers/database_helper.dart';
// import 'package:flutter/material.dart';
// import 'package:formbot/providers/authprovider.dart';
// import 'package:formbot/providers/firebaseprovider.dart';
// import 'package:image/image.dart' as img;
// import 'package:image_cropper/image_cropper.dart';
// // Import the FieldEditScreen class
// import 'dart:convert'; // For base64 encoding
// import 'package:http/http.dart' as http;
// import 'package:mime/mime.dart'; // For MIME type lookup
// //import 'package:path/path.dart'; // For file paths
// import 'package:http_parser/http_parser.dart'; // For MediaType
// import 'package:path/path.dart' as p;
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// String? originalFileName;

// class ImageProcessingScreen extends StatefulWidget {
//   const ImageProcessingScreen({super.key});

//   @override
//   _ImageProcessingScreenState createState() => _ImageProcessingScreenState();
// }

// class _ImageProcessingScreenState extends State<ImageProcessingScreen>
//     with SingleTickerProviderStateMixin {
//   String? imagePath;
//    String? selectedForm;
  
//   img.Image? image;
//   final DatabaseHelper _dbHelper = DatabaseHelper();
//   bool _isLoading = false;
//   late AnimationController _fadeController;
//   SharedPreferences? _prefs; // Remove 'late' keyword
//   late Animation<double> _fadeAnimation;
//   String _forceRebuild = DateTime.now().millisecondsSinceEpoch.toString();

//   Future<void> setPrefs() async {
//     _prefs = await SharedPreferences.getInstance();
//   }
  

//   @override
//   void initState() {
//     super.initState();
//     setPrefs(); // Call setPrefs in initState
    
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 500),
//       vsync: this,
//     );
//     _fadeAnimation =
//         Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
//     _fadeController.forward();
//   }

//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }

//   // @override
//   // void didChangeDependencies() {
//   //   super.didChangeDependencies();
//   //   imagePath = ModalRoute.of(context)!.settings.arguments as String?;
    
//   //   if (imagePath != null) {
//   //     originalFileName = p.basename(imagePath!); // Store the original filename
//   //     _loadImage();
//   //   }
//   // }

//   @override
// void didChangeDependencies() {
//   super.didChangeDependencies();
//   final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
//   imagePath = args?['imagePath'];
//   selectedForm = args?['selectedForm'];
  
//   if (imagePath != null) {
//     originalFileName = p.basename(imagePath!); // Store the original filename
//     _loadImage();
//   }
// }

//   Future<void> _loadImage() async {
//     final File file = File(imagePath!);
//     final img.Image? loadedImage = img.decodeImage(await file.readAsBytes());
//     setState(() {
//       image = loadedImage;
//     });
//   }
// // this is the crop function here 
//   // Future<void> _cropImage() async {
//   //   if (imagePath != null) {
//   //     CroppedFile? croppedFile = await ImageCropper().cropImage(
//   //       sourcePath: imagePath!,
//   //       aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
//   //       uiSettings: [
//   //         AndroidUiSettings(
//   //           toolbarTitle: 'Crop Image',
//   //           toolbarColor: Color.fromRGBO(0, 150, 136, 1.0)

//   //           toolbarWidgetColor: Colors.white,
//   //           initAspectRatio: CropAspectRatioPreset.original,
//   //           lockAspectRatio: false,
//   //         ),
//   //         IOSUiSettings(
//   //           minimumAspectRatio: 1.0,
//   //         ),
//   //       ],
//   //     );

//   //     if (croppedFile != null) {
//   //       // Get the directory of the cropped file
//   //       String directory = p.dirname(croppedFile.path);
//   //       // Create a new path with the original filename
//   //       String newPath = p.join(directory, originalFileName!);

//   //       // If a file already exists at the new path, delete it
//   //       if (await File(newPath).exists()) {
//   //         await File(newPath).delete();
//   //       }

//   //       // Copy the cropped file to the new path with original filename
//   //       await File(croppedFile.path).copy(newPath);
//   //       // Delete the temporary cropped file
//   //       await File(croppedFile.path).delete();

//   //       setState(() {
//   //         imagePath = newPath;
//   //         image = img.decodeImage(File(newPath).readAsBytesSync());
//   //       });
//   //     }
//   //   }
//   // }
// Future<void> _cropImage() async {
//   if (imagePath != null) {
//     CroppedFile? croppedFile = await ImageCropper().cropImage(
//       sourcePath: imagePath!,
//       aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
//       compressQuality: 100,
//       uiSettings: [
//         AndroidUiSettings(
//           toolbarTitle: 'Crop',
//           toolbarColor: Color.fromRGBO(0, 150, 136, 1.0)
// ,
//           toolbarWidgetColor: Colors.white,
//           cropGridColor: Colors.black,
//           initAspectRatio: CropAspectRatioPreset.original,
//           lockAspectRatio: false,
//         ),
//         IOSUiSettings(
//           title: 'Crop',
//         ),
//       ],
//     );

//     if (croppedFile != null) {
//       // Clear image cache
//       imageCache.clear();
//       imageCache.clearLiveImages();

//       try {
//         // Get the directory of the cropped file
//         String directory = p.dirname(croppedFile.path);
//         // Create a new path with the original filename
//         String newPath = p.join(directory, originalFileName!);

//         // If a file already exists at the new path, delete it
//         if (await File(newPath).exists()) {
//           await File(newPath).delete();
//         }

//         // Copy the cropped file to the new path with original filename
//         await File(croppedFile.path).copy(newPath);
//         // Delete the temporary cropped file
//         await File(croppedFile.path).delete();

//         // Create a new file instance to force reload
//         final newFile = File(newPath);
        
//         if (mounted) {
//           setState(() {
//             imagePath = newPath;
//             image = img.decodeImage(newFile.readAsBytesSync());
//             // Add a timestamp to force rebuild
//             _forceRebuild = DateTime.now().millisecondsSinceEpoch.toString();
//           });
//         }
//       } catch (e) {
//         print('Error updating cropped image: $e');
//       }
//     }
//   }
// }

//   Future<void> _sendImageToAPI() async {
//     if (imagePath != null) {
//       setState(() {
//         _isLoading = true;
//       });

//       String fileName = p.basename(imagePath!);
//       final boundingBoxUrl = _prefs?.getString('bounding_box_url');
//       if (boundingBoxUrl == null || boundingBoxUrl.isEmpty) {
//         _showErrorToast(context, 'Bounding Box URL is not set in settings..');

//         //_showErrorToast('Bounding Box URL is not set in settings.');
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }
//       var url = Uri.parse(boundingBoxUrl);

//       try {
//         _dbHelper.saveUploadedImage(imagePath!);
//         var mimeType = lookupMimeType(imagePath!);
//         var request = http.MultipartRequest('POST', url);

//         request.files.add(
//           await http.MultipartFile.fromPath(
//             'file',
//             imagePath!,
//             contentType:
//                 MediaType.parse(mimeType ?? 'application/octet-stream'),
//           ),
//         );

//         var response = await request.send();
//         var responseData = await response.stream.bytesToString();
//         var decodedResponse = jsonDecode(responseData);
//         print('Bounding Box Response: $decodedResponse');

        

//         if (response.statusCode == 200) {
//           final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
//           final authProvider = Provider.of<AuthProvider>(context, listen: false);
          
//           // Create new form and get formId
//           final formId = await firebaseProvider.saveFormWithDetails(
//             uid: authProvider.user!.uid,
//             imagePath: imagePath!,
//             boundingBoxes: decodedResponse['bounding_boxes'],
//             selectedField: '', // Initial empty field
//             ocrText: '', // Initial empty OCR
//             chatMessages: [], // Initial empty messages
//             selectedForm: selectedForm ?? 'Unknown Form', 
//           );

//           await Navigator.pushNamed(
//             context,
//             '/field_edit_screen',
//             arguments: {
//               'imagePath': imagePath!,
//               'bounding_boxes': decodedResponse['bounding_boxes'],
//               'formId': formId, // Pass formId to FieldEditScreen
//               'selectedForm': selectedForm,
//             },
//           );
//         } else if (response.statusCode == 400) {
//           _showErrorToast(context, decodedResponse['message'] ?? 'Error processing image');

//         } else {
//           _showErrorToast(context, 'Network error or server error. Please try again later.');

//         }
//       } catch (e) {
//        _showErrorToast(context, 'Error sending image. Please check the settings.');

//       } finally {
//         if (mounted) {
//           setState(() {
//             _isLoading = false;
//           });
//         }
//       }
//     } else {
//       _showErrorToast(context, 'No image selected.');

//     }
//   }

//   // void _showErrorSnackBar(String message) {
//   //   if (!mounted) return;
//   //   ScaffoldMessenger.of(context).showSnackBar(
//   //     SnackBar(
//   //       content: Text(message),
//   //       backgroundColor: const Color.fromRGBO(255, 159, 126, 1.0),
//   //       behavior: SnackBarBehavior.floating,
//   //       shape: RoundedRectangleBorder(
//   //         borderRadius: BorderRadius.circular(10),
//   //       ),
//   //       action: SnackBarAction(
//   //         label: 'Dismiss',
//   //         textColor: Colors.white,
//   //         onPressed: () {
//   //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//   //         },
//   //       ),
//   //     ),
//   //   );
//   // }
// // void _showErrorToast(String message) {
// //   if (!mounted) return;
// //   Fluttertoast.showToast(
// //     msg: message,
// //     toastLength: Toast.LENGTH_SHORT,
// //     gravity: ToastGravity.BOTTOM,
// //     backgroundColor: const Color.fromRGBO(255, 159, 126, 1.0),
// //     textColor: Colors.white,
// //     fontSize: 16.0,
// //   );
// // }
// void _showErrorToast(BuildContext context, String message) {
//   FToast fToast = FToast();
//   fToast.init(context);
  

//   Widget toast = Container(
//     padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//     decoration: BoxDecoration(
//       color: Colors.black.withOpacity(0.85), // Semi-transparent background
//       borderRadius: BorderRadius.circular(4.0), // Reduced border radius for a sharper look
//       boxShadow: const [
//         BoxShadow(
//           color: Colors.black26,
//           blurRadius: 4.0,
//           offset: Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(Icons.error_outline, color: Colors.white, size: 20),
//         SizedBox(width: 8),
//         Expanded(
//           child: Text(
//             message,
//             style: TextStyle(color: Colors.white, fontSize: 16),
//           ),
//         ),
//       ],
//     ),
//   );

//   fToast.showToast(
//     child: toast,
//     gravity: ToastGravity.BOTTOM,
//     toastDuration: Duration(seconds: 2),
//   );
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
// ,
//         iconTheme: const IconThemeData(color: Colors.white),
//         // title: const Text(
//         //   'Process Image',
//         //   style: TextStyle(
//         //     color: Colors.white,
//         //     fontWeight: FontWeight.bold,
//         //   ),
//         // ),
//       ),
//       body: Container(
//         color: Colors.grey[50],
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: Stack(
//             children: [
//               Column(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       margin: const EdgeInsets.all(16.0),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(16),
//                         child: imagePath != null
//     ? Expanded(
//       child: Image.file(
//           File(imagePath!),
//           key: ValueKey('${imagePath}_${_forceRebuild}'),
//           fit: BoxFit.fitWidth,
//           gaplessPlayback: false, // Force image reload
//           cacheWidth: null, // Disable width caching
//           cacheHeight: null, // Disable height caching
//         ),
//     )
//     : const Center(
//         child: Text(
//           'No image selected',
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 16,
//           ),
//         ),
//       ),
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         _buildButton(
//                           icon: Icons.crop,
//                           label: 'Crop',
//                           onPressed: _isLoading ? null : _cropImage,
//                         ),
//                         _buildButton(
//                           icon: Icons.navigate_next,
//                           label: 'Process',
//                           onPressed: _isLoading ? null : _sendImageToAPI,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                 ],
//               ),
//               if (_isLoading)
//                 Container(
//                   color: Colors.black54,
//                   child: Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const CircularProgressIndicator(
//                           valueColor:
//                               AlwaysStoppedAnimation<Color>(Color.fromRGBO(0, 150, 136, 1.0)
// ),
//                         ),
//                         const SizedBox(height: 16),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 24,
//                             vertical: 12,
//                           ),
//                           // decoration: BoxDecoration(
//                           //   color: Colors.white,
//                           //   borderRadius: BorderRadius.circular(25),
//                           // ),
//                           // child: const Text(
//                           //   'Processing image...',
//                           //   style: TextStyle(
//                           //     fontSize: 16,
//                           //     fontWeight: FontWeight.w500,
//                           //   ),
//                           // ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback? onPressed,
//   }) {
//     return SizedBox(
//       width: 150,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
// ,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: onPressed == null ? 0 : 3,
//         ),
//         onPressed: onPressed,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:formbot/helpers/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:formbot/providers/authprovider.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
// Import the FieldEditScreen class
import 'dart:convert'; // For base64 encoding
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // For MIME type lookup
//import 'package:path/path.dart'; // For file paths
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? originalFileName;

class ImageProcessingScreen extends StatefulWidget {
  const ImageProcessingScreen({super.key});

  @override
  _ImageProcessingScreenState createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen>
    with SingleTickerProviderStateMixin {
  String? imagePath;
  String? selectedForm;
  
  img.Image? image;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  late AnimationController _fadeController;
  SharedPreferences? _prefs; // Remove 'late' keyword
  late Animation<double> _fadeAnimation;
  String _forceRebuild = DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> setPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  @override
  void initState() {
    super.initState();
    setPrefs(); // Call setPrefs in initState
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    imagePath = args?['imagePath'];
    selectedForm = args?['selectedForm'];
    
    if (imagePath != null) {
      originalFileName = p.basename(imagePath!); // Store the original filename
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final File file = File(imagePath!);
    final img.Image? loadedImage = img.decodeImage(await file.readAsBytes());
    setState(() {
      image = loadedImage;
    });
  }

  Future<void> _cropImage() async {
    if (imagePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath!,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Color.fromRGBO(0, 150, 136, 1.0),
            toolbarWidgetColor: Colors.white,
            cropGridColor: Colors.black,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop',
          ),
        ],
      );

      if (croppedFile != null) {
        // Clear image cache
        imageCache.clear();
        imageCache.clearLiveImages();

        try {
          // Get the directory of the cropped file
          String directory = p.dirname(croppedFile.path);
          // Create a new path with the original filename
          String newPath = p.join(directory, originalFileName!);

          // If a file already exists at the new path, delete it
          if (await File(newPath).exists()) {
            await File(newPath).delete();
          }

          // Copy the cropped file to the new path with original filename
          await File(croppedFile.path).copy(newPath);
          // Delete the temporary cropped file
          await File(croppedFile.path).delete();

          // Create a new file instance to force reload
          final newFile = File(newPath);
          
          if (mounted) {
            setState(() {
              imagePath = newPath;
              image = img.decodeImage(newFile.readAsBytesSync());
              // Add a timestamp to force rebuild
              _forceRebuild = DateTime.now().millisecondsSinceEpoch.toString();
            });
          }
        } catch (e) {
          print('Error updating cropped image: $e');
        }
      }
    }
  }

  Future<void> _sendImageToAPI() async {
    if (imagePath != null) {
      setState(() {
        _isLoading = true;
      });

      String fileName = p.basename(imagePath!);
      final boundingBoxUrl = _prefs?.getString('bounding_box_url');
      if (boundingBoxUrl == null || boundingBoxUrl.isEmpty) {
        _showErrorToast(context, 'Bounding Box URL is not set in settings..');

        setState(() {
          _isLoading = false;
        });
        return;
      }
      var url = Uri.parse(boundingBoxUrl);

      try {
        _dbHelper.saveUploadedImage(imagePath!);
        var mimeType = lookupMimeType(imagePath!);
        var request = http.MultipartRequest('POST', url);

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imagePath!,
            contentType:
                MediaType.parse(mimeType ?? 'application/octet-stream'),
          ),
        );

        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseData);
        print('Bounding Box Response: $decodedResponse');

        if (response.statusCode == 200) {
          final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          
          // Create new form and get formId
          final formId = await firebaseProvider.saveFormWithDetails(
            uid: authProvider.user!.uid,
            imagePath: imagePath!,
            boundingBoxes: decodedResponse['bounding_boxes'],
            selectedField: '', // Initial empty field
            ocrText: '', // Initial empty OCR
            chatMessages: [], // Initial empty messages
            selectedForm: selectedForm ?? 'Unknown Form', 
          );

          await Navigator.pushNamed(
            context,
            '/field_edit_screen',
            arguments: {
              'imagePath': imagePath!,
              'bounding_boxes': decodedResponse['bounding_boxes'],
              'formId': formId, // Pass formId to FieldEditScreen
              'selectedForm': selectedForm,
            },
          );
        } else if (response.statusCode == 400) {
          _showErrorToast(context, decodedResponse['message'] ?? 'Error processing image');
        } else {
          _showErrorToast(context, 'Network error or server error. Please try again later.');
        }
      } catch (e) {
        _showErrorToast(context, 'Error sending image. Please check the settings.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showErrorToast(context, 'No image selected.');
    }
  }

  void _showErrorToast(BuildContext context, String message) {
    FToast fToast = FToast();
    fToast.init(context);
    
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85), // Semi-transparent background
        borderRadius: BorderRadius.circular(4.0), // Reduced border radius for a sharper look
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color.fromRGBO(0, 150, 136, 1.0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          color: Colors.grey[50],
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imagePath != null
                            ? Image.file(
                                File(imagePath!),
                                key: ValueKey('${imagePath}_${_forceRebuild}'),
                                fit: BoxFit.contain,
                                gaplessPlayback: false, // Force image reload
                                cacheWidth: null, // Disable width caching
                                cacheHeight: null, // Disable height caching
                              )
                            : const Center(
                                child: Text(
                                  'No image selected',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildButton(
                              icon: Icons.crop,
                              label: 'Crop',
                              onPressed: _isLoading ? null : _cropImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildButton(
                              icon: Icons.navigate_next,
                              label: 'Next',
                              onPressed: _isLoading ? null : _sendImageToAPI,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(0, 150, 136, 1.0)),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromRGBO(0, 150, 136, 1.0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: onPressed == null ? 0 : 3,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}