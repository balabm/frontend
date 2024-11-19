import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReviewSubmitScreen extends StatelessWidget {
  const ReviewSubmitScreen({super.key});

  Future<void> _submitData(String imagePath, String audioPath) async {
    // Create a multipart request
    // var request = http.MultipartRequest('POST', Uri.parse('YOUR_API_ENDPOINT'));

    // // Add the image file to the request
    // request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    // // Add the audio file to the request
    // if (audioPath != null) {
    //   request.files.add(await http.MultipartFile.fromPath('audio', audioPath));
    // }

    // // Send the request
    // try {
    //   var response = await request.send();
    //   if (response.statusCode == 200) {
    //     print('Submission successful');
    //     await _storeFormLocally(imagePath, audioPath);
    //   } else {
    //     print('Submission failed');
    //   }
    // } catch (e) {
    //   print('Error submitting data: $e');
    // }
  }

  Future<void> _storeFormLocally(String imagePath, String audioPath) async {
    final prefs = await SharedPreferences.getInstance();
    final forms = prefs.getStringList('submittedForms') ?? [];
    final form = jsonEncode({'imagePath': imagePath, 'audioPath': audioPath});
    forms.add(form);
    await prefs.setStringList('submittedForms', forms);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, String?>;
    final String? imagePath = args['imagePath'];
    final String? audioPath = args['audioPath'];

    return Scaffold(
      appBar: AppBar(title: const Text('Review and Submit')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (imagePath != null) Image.file(File(imagePath)),
            const SizedBox(height: 20),
            if (audioPath != null)
              Text('Audio recorded: ${audioPath.split('/').last}'),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () async {
                await _submitData(imagePath!, audioPath!);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
