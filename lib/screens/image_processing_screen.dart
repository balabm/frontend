import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'FieldEditScreen.dart'; // Import the FieldEditScreen class
import 'dart:convert'; // For base64 encoding
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart'; // For MIME type lookup
//import 'package:path/path.dart'; // For file paths
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:path/path.dart' as p;



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
    var url = Uri.parse('http://192.168.31.227:8000/cv/form-detection-with-box/');

    // Prepare the image file and lookup MIME type
    var mimeType = lookupMimeType(imagePath!);
    var request = http.MultipartRequest('POST', url);

    // Add the file to the request
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', // The key expected by the FastAPI endpoint
        imagePath!,
        contentType: MediaType.parse(mimeType ?? 'application/octet-stream'), // Handle unknown MIME types
      ),
    );

    try {
      var response = await request.send();

      // Check for 400 status code (client errors from FastAPI)
      if (response.statusCode == 400) {
        var responseData = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseData);

        // Print the error response for debugging
        print('Error response: $decodedResponse');

        // Display error message from the server (specific to 400 errors)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decodedResponse['message'] ?? 'Error processing image'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (response.statusCode == 200) {
        // Parse the response for successful processing
        var responseData = await response.stream.bytesToString();
        var decodedResponse = jsonDecode(responseData);

        // Print the successful response for debugging
        print('Success response: $decodedResponse');

        // Proceed with navigation if the image is valid
        Navigator.pushNamed(
          context,
          '/field_edit_screen',
          arguments: {
            'imagePath': imagePath!,
            'bounding_boxes': decodedResponse['bounding_boxes'], // Pass bounding boxes
          },
        );
      } else {
        // Handle other non-200 or non-400 errors (network errors, etc.)
        print('Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error or server error. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle exceptions during sending
      print('Error sending image to API: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } else {
    print('No image available to send.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No image selected.'),
        backgroundColor: Colors.red,
      ),
    );
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
