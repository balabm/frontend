import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiRepository {
  Future<String> get boundingBoxUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bounding_box_url') ?? 'http://192.168.62.227:8000/cv/form-detection-with-box/';
  }

  Future<String> get ocrTextUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ocr_text_url') ?? 'http://150.230.166.29/ocr/cv/ocr';
  }

  Future<String> get asrUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('asr_url') ?? 'http://150.230.166.29/abc_test/get_llm_response';
  }

  Future<String> get llmUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('llm_url') ?? 'http://150.230.166.29/llm//get_llm_response';
  }

  // Audio API calls
  Future<String?> sendAudioToApi(File zipFile) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse(await asrUrl)
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        zipFile.path,
        contentType: MediaType('application', 'zip'),
      ));

      var response = await request.send();
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        print('Audio ZIP sent successfully!');
        return responseBody;
      }
      print('Failed to upload ZIP: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error uploading audio ZIP file: $e');
      return null;
    }
  }

  // LLM API calls
  Future<Map<String, dynamic>?> sendToLLMApi(String formEntry, {String? voiceQuery}) async {
    final uri = Uri.parse(await llmUrl);
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'form_entry': formEntry,
          'voice_query': voiceQuery ?? '',
        }),
      );

      if (response.statusCode == 200) {
        print('LLM Response: ${response.body}');
        return jsonDecode(response.body);
      }
      print('Failed to get LLM response: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error occurred while sending data to LLM API: $e');
      return null;
    }
  }

  // OCR API calls
  Future<Map<String, dynamic>?> sendOCRRequest({
    required String imagePath,
    required Map<String, dynamic> box,
  }) async {
    final uri = Uri.parse(await ocrTextUrl);
    var request = http.MultipartRequest('POST', uri);

    var file = File(imagePath);
    if (!await file.exists()) {
      print('Image file does not exist at the given path: $imagePath');
      return null;
    }

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('image', 'png'),
    ));

    request.fields.addAll({
      'x_center': box['x_center'].toString(),
      'y_center': box['y_center'].toString(),
      'width': box['width'].toString(),
      'height': box['height'].toString(),
      'class_type': box['class'],
    });

    try {
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('OCR data sent successfully! Response: $responseBody');
        return jsonDecode(responseBody);
      }
      print('Failed to send OCR data: ${response.statusCode}');
      final errorResponse = await response.stream.bytesToString();
      print('Error response: $errorResponse');
      return null;
    } catch (e) {
      print('Error occurred while sending OCR data: $e');
      return null;
    }
  }
}
