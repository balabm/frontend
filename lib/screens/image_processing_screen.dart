import 'dart:io';
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
  img.Image? image;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    imagePath = ModalRoute.of(context)!.settings.arguments as String?;
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
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.teal,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );

      if (croppedFile != null) {
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

        setState(() {
          imagePath = newPath;
          image = img.decodeImage(File(newPath).readAsBytesSync());
        });
      }
    }
  }

  Future<void> _sendImageToAPI() async {
    if (imagePath != null) {
      setState(() {
        _isLoading = true;
      });

      String fileName = p.basename(imagePath!);
      final prefs = await SharedPreferences.getInstance();
      final boundingBoxUrl = prefs.getString('bounding_box_url');
      if (boundingBoxUrl == null || boundingBoxUrl.isEmpty) {
        _showErrorSnackBar('Bounding Box URL is not set in settings.');
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
          );

          await Navigator.pushNamed(
            context,
            '/field_edit_screen',
            arguments: {
              'imagePath': imagePath!,
              'bounding_boxes': decodedResponse['bounding_boxes'],
              'formId': formId, // Pass formId to FieldEditScreen
            },
          );
        } else if (response.statusCode == 400) {
          _showErrorSnackBar(
              decodedResponse['message'] ?? 'Error processing image');
        } else {
          _showErrorSnackBar(
              'Network error or server error. Please try again later.');
        }
      } catch (e) {
        _showErrorSnackBar('Error sending image. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      _showErrorSnackBar('No image selected.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Process Image',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
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
                            ? Hero(
                                tag: imagePath!,
                                child: Image.file(
                                  File(imagePath!),
                                  fit: BoxFit.contain,
                                ),
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
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildButton(
                          icon: Icons.crop,
                          label: 'Crop',
                          onPressed: _isLoading ? null : _cropImage,
                        ),
                        _buildButton(
                          icon: Icons.navigate_next,
                          label: 'Process',
                          onPressed: _isLoading ? null : _sendImageToAPI,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF0b3c66)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Text(
                            'Processing image...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
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
      ),
    );
  }
}
