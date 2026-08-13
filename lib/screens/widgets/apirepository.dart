import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:formbot/helpers/firebase_handler.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiRepository {
  Future<String> get boundingBoxUrl async {
    final prefs = await SharedPreferences.getInstance();
    return  prefs.getString('urlupdated') == 'true' ?   prefs.getString('bounding_box_url') ?? '' : 'http://15.206.206.190:8002/cv/form-detection-with-box/';
  }

  Future<String> get ocrTextUrl async {
    final prefs = await SharedPreferences.getInstance();
    return  prefs.getString('urlupdated') == 'true' ?   prefs.getString('ocr_text_url') ?? '' : 'http://15.206.206.190:8001/cv/ocr';
  }

  Future<String> get asrUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('urlupdated') == 'true' ?  prefs.getString('asr_url') ?? '' : 'http://15.206.206.190:8002/upload-audio-zip/';
  }

  Future<String> get llmUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('urlupdated') == 'true' ?  prefs.getString('llm_url') ?? '' : 'http://15.206.206.190:8036/get_llm_response_schemes';
  }

Future<Map<String, dynamic>?> sendAudioToApi(File zipFile, String uid) async {
  try {
    // Get the user's profile details
    final FirebaseHandler firebaseHandler = FirebaseHandler();
    final userProfile = await firebaseHandler.getUserProfileDetails(uid);

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(await asrUrl),
    );

    // Add the ZIP file
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      zipFile.path,
      contentType: MediaType('application', 'zip'),
    ));

    // Add user profile parameters
    request.fields['gender'] = userProfile['gender'];
    request.fields['age'] = userProfile['age'].toString();
    request.fields['state'] = userProfile['state'];
    request.fields['nation'] = userProfile['nation'];
    request.fields['first_language'] = userProfile['first_language'];

    print('Sending ASR request with user profile: ${userProfile}');

    final stopwatch = Stopwatch()..start();

    var response = await request.send();
    String? body;
    if (response.statusCode == 200) {
      body = await response.stream.bytesToString();
      print('Audio ZIP sent successfully!');
    } else if (response.statusCode == 400) {
      body = await response.stream.bytesToString();
      print('Failed to upload ZIP: $body');
    } else {
      print('Failed to upload ZIP: ${response.statusCode}');
    }

    stopwatch.stop();

    return {
      'response': body,
      'durationMs': stopwatch.elapsedMilliseconds,
    };
  } catch (e) {
    print('Error uploading audio ZIP file: $e');
    return null;
  }
}


  Future<Map<String, dynamic>?> sendToLLMApi(String formEntry, String schemeName, {String? voiceQuery, String? uid, String? formId}) async {
  final uri = Uri.parse(await llmUrl);

  // Print the request details for debugging
  print('LLM Request URL: $uri');
  print('LLM Request Form Entry: $formEntry');
  print('LLM Request Scheme Name: $schemeName');
  if (voiceQuery != null) {
    print('LLM Request Voice Query: $voiceQuery');
  }

  // Get current user ID if not provided
  String userId = uid ?? '';
  if (userId.isEmpty) {
    // Try to get the current user ID from Firebase Auth
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      print('Using current user ID: $userId');
    } else {
      print('Warning: No user ID available');
    }
  }

  // Get form ID if not provided and if we have a user ID
  String documentId = formId ?? '';
  if (documentId.isEmpty && userId.isNotEmpty) {
    try {
      // This is a simplified approach - you may need a more specific query
      final formDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('forms')
          .limit(1)
          .get();
      
      if (formDocs.docs.isNotEmpty) {
        documentId = formDocs.docs.first.id;
        print('Using form ID: $documentId');
      } else {
        print('Warning: No form ID found for user $userId');
      }
    } catch (e) {
      print('Error fetching form ID: $e');
    }
  }

  final requestBody = jsonEncode({
    'form_entry': formEntry,
    'voice_query': voiceQuery ?? '',
    'scheme_name': schemeName,
    'user_id': userId,                  // Add user ID 
    'form_id': documentId           // Add form ID
  });

  print('LLM Request Body: $requestBody');

  try {
    print('🚀 Sending LLM POST request...');
    final stopwatch = Stopwatch()..start();

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    ).timeout(const Duration(seconds: 30)); // Add timeout

    stopwatch.stop();

    print('📥 LLM Response Status Code: ${response.statusCode}');
    print('📥 LLM Response Body: ${response.body}');

    if (response.statusCode == 200) {
      print('✅ LLM Response Success!');
      try {
        final decodedResponse = jsonDecode(response.body);
        print('✅ Decoded Response: $decodedResponse');
        return {
          'response': decodedResponse,
          'durationMs': stopwatch.elapsedMilliseconds,
        };
      } catch (e) {
        print('❌ Error decoding JSON response: $e');
        print('Raw response: ${response.body}');
        return null;
      }
    } else {
      print('❌ Failed to get LLM response: ${response.statusCode}');
      print('❌ Response body: ${response.body}');
      return null;
    }
  } catch (e, stackTrace) {
    print('❌ Error occurred while sending data to LLM API: $e');
    print('❌ Stack trace: $stackTrace');
    return null;
  }
}

  // OCR API calls
  Future<Map<String, dynamic>?> sendOCRRequest({
  required String imagePath,
  required Map<String, dynamic> box,
}) async {
  final uri = Uri.parse(await ocrTextUrl);
  print('OCR Request URL: $uri');
  print('OCR Request Image Path: $imagePath');
  print('OCR Request Box: $box');
  var request = http.MultipartRequest('POST', uri);

  var file = File(imagePath);
  if (!await file.exists()) {
    print('Image file does not exist at the given path: $imagePath');
    return null;
  }

  request.files.add(await http.MultipartFile.fromPath(
    'form_image',
    file.path,
    filename: file.path.split('/').last,
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
    final stopwatch = Stopwatch()..start();

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();

    stopwatch.stop();

    if (response.statusCode == 200) {
      print('OCR data sent successfully! Response: $responseBody');
      final decoded = jsonDecode(responseBody);
      return {
        'response': decoded,
        'durationMs': stopwatch.elapsedMilliseconds,
      };
    }

    print('Failed to send OCR data: ${response.statusCode}');
    print('Error response: $responseBody');
    return null;
  } catch (e) {
    print('Error occurred while sending OCR data: $e');
    return null;
  }
}
}
