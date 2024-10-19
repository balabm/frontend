import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';


class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  int selectedCameraIndex = 0;
  bool isFlashOn = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  void _switchCamera() {
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
    _initializeCamera();
  }

  void _toggleFlash() {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    _controller?.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _saveImage(String path) async {
  // Get the application's document directory
  final directory = await getApplicationDocumentsDirectory();
  
  // Define a unique path for the image file based on the current timestamp
final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg'; // Convert int to String
  
  // Copy the image file to the new location
  final imageFile = File(path);
  await imageFile.copy(imagePath);
  
  // Save the image to the gallery
  await ImageGallerySaver.saveFile(imagePath);

  // Save the image path to SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  List<String> capturedImages = prefs.getStringList('capturedImages') ?? [];
  capturedImages.add(imagePath);  // Add the new image path
  await prefs.setStringList('capturedImages', capturedImages);  // Save the updated list
}


  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.pushNamed(context, '/image_processing',
          arguments: pickedFile.path);
    }
  }

  

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cameraPreviewSize = _controller!.value.previewSize;
    final screenSize = MediaQuery.of(context).size;
    final aspectRatio = cameraPreviewSize!.height / cameraPreviewSize.width;
    final previewHeight = screenSize.width * aspectRatio;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: screenSize.width,
                height: previewHeight,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.switch_camera, color: Colors.white),
              onPressed: _switchCamera,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.photo_library, color: Colors.white),
              onPressed: _pickImage, // Handle gallery button press
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.camera, color: Colors.white, size: 48),
                onPressed: () async {
                  try {
                    final image = await _controller!.takePicture();
                    await _saveImage(image.path);
                    Navigator.pushNamed(context, '/image_processing',
                        arguments: image.path);
                  } catch (e) {
                    print(e);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
