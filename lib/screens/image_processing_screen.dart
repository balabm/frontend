import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'FieldEditScreen.dart'; // Import the FieldEditScreen class
import 'dart:convert'; // For base64 encoding
import 'package:http/http.dart' as http;

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

  Future<void> _cropImage() async {
    if (imagePath != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath!,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Color(0xFF0b3c66),
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

  // New method to send the image to the API
  Future<void> _sendImageToAPI() async {
    if (imagePath != null) {
      var url = Uri.parse('http://0.0.0.0:8000/cv/form-detection-with-box/');

      // Prepare the image file
      var request = http.MultipartRequest('POST', url);
      request.files.add(
        await http.MultipartFile.fromPath(
          'file', // Key expected by the FastAPI endpoint
          imagePath!,
        ),
      );

      try {
        var response = await request.send();

        if (response.statusCode == 200) {
          // Parse the response
          var responseData = await response.stream.bytesToString();
          var decodedResponse = jsonDecode(responseData);

          print('Response from API:');
          print(decodedResponse);

          // Handle the response, e.g., navigate to the FieldEditScreen
          Navigator.pushNamed(
            context,
            '/field_edit_screen',
            arguments: {
              'imagePath': imagePath!,
              'bounding_boxes': decodedResponse['bounding_boxes'], // Add this if needed for field editing
            },
          );
        } else {
          print('Error: ${response.statusCode}');
        }
      } catch (e) {
        print('Error sending image to API: $e');
      }
    } else {
      print('No image available to send.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Processing', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF0b3c66),
        iconTheme: IconThemeData(color: Colors.white), // Change arrow color to white
      ),
      body: Container(
        color: Colors.white, // Background color
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: imagePath != null
                  ? Image.file(File(imagePath!))
                  : Center(child: Text('No image selected')),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0b3c66), // Button background color
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                      elevation: 5, // Shadow effect
                    ),
                    icon: Icon(Icons.crop, color: Colors.white),
                    label: Text('Crop', style: TextStyle(color: Colors.white)),
                    onPressed: _cropImage,
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  width: 150,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0b3c66), // Button background color
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Rounded corners
                      ),
                      elevation: 5, // Shadow effect
                    ),
                    icon: Icon(Icons.navigate_next, color: Colors.white),
                    label: Text('Next', style: TextStyle(color: Colors.white)),
                    onPressed: _sendImageToAPI, // Call the API when "Next" is pressed
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
