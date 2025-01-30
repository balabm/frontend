import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

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
    if (cameras.isEmpty) return;

    _controller =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.high);
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _switchCamera() {
    if (cameras.isEmpty) return;
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;
    _initializeCamera();
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      isFlashOn = !isFlashOn;
    });
    _controller?.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _saveImage(String path) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch.toString()}.jpg';
    final imageFile = File(path);
    await imageFile.copy(imagePath);

    final prefs = await SharedPreferences.getInstance();
    List<String> capturedImages = prefs.getStringList('capturedImages') ?? [];
    capturedImages.add(imagePath);
    await prefs.setStringList('capturedImages', capturedImages);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (!mounted) return;
        Navigator.pushNamed(context, '/image_processing',
            arguments: pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 85.0),
              child: CameraPreview(_controller!),
            ),
          ),
       
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _toggleFlash,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
               padding:  EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.2),
                      
                      width: 60,
                      height: 60,
                      // decoration: BoxDecoration(
                      //   border: Border.all(color: Colors.white, width: 2),
                      //   borderRadius: BorderRadius.circular(12),
                      // ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (_controller == null || !_controller!.value.isInitialized)
                        return;
      
                      try {
                        final image = await _controller!.takePicture();
                        await _saveImage(image.path);
                        if (!mounted) return;
                        Navigator.pushNamed(
                          context,
                          '/image_processing',
                          arguments: image.path,
                        );
                      } catch (e) {
                        print('Error taking picture: $e');
                      }
                    },
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
                  const SizedBox(width: 60, height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
