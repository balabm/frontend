import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  int selectedCameraIndex = 0;
  bool isFlashOn = false;

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
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageFile = File(path);
    await imageFile.copy(imagePath);
    await ImageGallerySaver.saveFile(imagePath);
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
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.width,
                height: _controller!.value.previewSize!.height,
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
              onPressed: () {
                // Handle gallery button press
              },
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
