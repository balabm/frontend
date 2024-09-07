import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageProcessingScreen extends StatefulWidget {
  @override
  _ImageProcessingScreenState createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {
  String? imagePath;
  img.Image? image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    imagePath = ModalRoute.of(context)!.settings.arguments as String?;
    if (imagePath != null) {
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

  Future<void> _applyFilter(img.Image Function(img.Image) filter) async {
    if (image != null) {
      final filteredImage = filter(image!);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/filtered_image.jpg';
      File(tempPath).writeAsBytesSync(img.encodeJpg(filteredImage));
      setState(() {
        imagePath = tempPath;
        image = filteredImage;
      });
    }
  }

  Future<void> _cropImage() async {
    if (imagePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath!,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.blue,
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
        setState(() {
          imagePath = croppedFile.path;
          image = img.decodeImage(File(croppedFile.path).readAsBytesSync());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Process Image')),
      body: Column(
        children: [
          Expanded(
            child: imagePath != null
                ? Image.file(File(imagePath!))
                : Center(child: Text('No image selected')),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: Text('Enhance'),
                onPressed: () => _applyFilter(
                    (img.Image image) => img.adjustColor(image, contrast: 1.2)),
              ),
              ElevatedButton(
                child: Text('B&W'),
                onPressed: () => _applyFilter(img.grayscale),
              ),
              ElevatedButton(
                child: Text('Crop'),
                onPressed: _cropImage,
              ),
            ],
          ),
          SizedBox(height: 20),
          ElevatedButton(
            child: Text('Next'),
            onPressed: () {
              Navigator.pushNamed(context, '/audio_recording',
                  arguments: imagePath);
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
