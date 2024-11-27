import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class Common {
  static void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(message,
                      style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),
      );
  }

  static void showMessage(BuildContext context, String message,
      {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  static Future<String> cropImage(
      String imagePath, int xCenter, int yCenter, int width, int height) async {
    final imageFile = img.decodeImage(File(imagePath).readAsBytesSync())!;
    final croppedImage = img.copyCrop(
      imageFile,
      x: (xCenter - (width ~/ 2)).toInt(),
      y: (yCenter - (height ~/ 2)).toInt(),
      width: width.toInt(),
      height: height.toInt(),
    );

    final croppedImagePath = '${Directory.systemTemp.path}/cropped_image.png';
    File(croppedImagePath).writeAsBytesSync(img.encodePng(croppedImage));
    return croppedImagePath;
  }
}

class ApiResponseProvider with ChangeNotifier {
  String? _audioZipResponse;
  String? _ocrResponse; // Assuming you have this as well

  // Getter for the audioZipResponse
  String? get audioZipResponse => _audioZipResponse;

  // Getter for the ocrResponse
  String? get ocrResponse => _ocrResponse;

  // Method to set the audioZipResponse
  void setAudioZipResponse(String response) {
    _audioZipResponse = response;
    notifyListeners(); // Notify listeners to update UI
  }

  // Method to set the ocrResponse
  void setOcrResponse(String response) {
    _ocrResponse = response;
    notifyListeners(); // Notify listeners to update UI
  }
}
