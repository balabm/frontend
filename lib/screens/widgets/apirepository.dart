// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class ApiRepository {
//   Future<String> get boundingBoxUrl async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('bounding_box_url') ?? 'http://192.168.62.227:8000/cv/form-detection-with-box/';
//   }

//   Future<String> get ocrTextUrl async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('ocr_text_url') ?? 'http://192.168.62.227:8080/cv/ocr';
//   }

//   Future<String> get asrUrl async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('asr_url') ?? 'http://192.168.62.227:8001/upload-audio-zip/';
//   }

//   Future<String> get llmUrl async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('llm_url') ?? 'http://192.168.62.227:8021/get_llm_response';
//   }

//   // Audio API calls
//   Future<String?> sendAudioToApi(File zipFile) async {
//     try {
//       var request = http.MultipartRequest(
//         'POST', 
//         Uri.parse(await asrUrl)
//       );

//       request.files.add(await http.MultipartFile.fromPath(
//         'file',
//         zipFile.path,
//         contentType: MediaType('application', 'zip'),
//       ));

//       var response = await request.send();
//       if (response.statusCode == 200) {
//         String responseBody = await response.stream.bytesToString();
//         print('Audio ZIP sent successfully!');
//         return responseBody;
//       }
//       print('Failed to upload ZIP: ${response.statusCode}');
//       return null;
//     } catch (e) {
//       print('Error uploading audio ZIP file: $e');
//       return null;
//     }
//   }

//   // LLM API calls
//   Future<Map<String, dynamic>?> sendToLLMApi(String formEntry, String schemeName, {String? voiceQuery}) async {
//     final uri = Uri.parse(await llmUrl);
//     try {
//       final response = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'form_entry': formEntry,
//           'voice_query': voiceQuery ?? '',
//           'scheme_name': schemeName,
//         }),
//       );

//       if (response.statusCode == 200) {
//         print('LLM Response: ${response.body}');
//         return jsonDecode(response.body);
//       }
//       print('Failed to get LLM response: ${response.statusCode}');
//       return null;
//     } catch (e) {
//       print('Error occurred while sending data to LLM API: $e');
//       return null;
//     }
//   }


  

//   // OCR API calls
//   Future<Map<String, dynamic>?> sendOCRRequest({
//     required String imagePath,
//     required Map<String, dynamic> box,
//   }) async {
//     final uri = Uri.parse(await ocrTextUrl);
//     var request = http.MultipartRequest('POST', uri);

//     var file = File(imagePath);
//     if (!await file.exists()) {
//       print('Image file does not exist at the given path: $imagePath');
//       return null;
//     }

//     request.files.add(await http.MultipartFile.fromPath(
//       'file',
//       file.path,
//       filename: file.path.split('/').last,
//       contentType: MediaType('image', 'png'),
//     ));

//     request.fields.addAll({
//       'x_center': box['x_center'].toString(),
//       'y_center': box['y_center'].toString(),
//       'width': box['width'].toString(),
//       'height': box['height'].toString(),
//       'class_type': box['class'],
//     });

//     try {
//       var response = await request.send();
//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         print('OCR data sent successfully! Response: $responseBody');
//         return jsonDecode(responseBody);
//       }
//       print('Failed to send OCR data: ${response.statusCode}');
//       final errorResponse = await response.stream.bytesToString();
//       print('Error response: $errorResponse');
//       return null;
//     } catch (e) {
//       print('Error occurred while sending OCR data: $e');
//       return null;
//     }
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiRepository {
  Future<String> get boundingBoxUrl async {
    final prefs = await SharedPreferences.getInstance();
    return  prefs.getString('urlupdated') == 'true' ?   prefs.getString('bounding_box_url') ?? '' : 'http://10.64.26.89:8002/cv/form-detection-with-box/';
  }

  Future<String> get ocrTextUrl async {
    final prefs = await SharedPreferences.getInstance();
    return  prefs.getString('urlupdated') == 'true' ?   prefs.getString('ocr_text_url') ?? '' : 'http://10.64.26.89:8001/cv/ocr';
  }

  Future<String> get asrUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('urlupdated') == 'true' ?  prefs.getString('asr_url') ?? '' : 'http://10.64.26.83:8002/upload-audio-zip/';
  }

  Future<String> get llmUrl async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('urlupdated') == 'true' ?  prefs.getString('llm_url') ?? '' : 'http://10.64.26.89:8036/get_llm_response_schemes';
  }

  // Audio API calls
  // Future<String?> sendAudioToApi(File zipFile) async {
  //   try {
  //     var request = http.MultipartRequest(
  //       'POST', 
  //       Uri.parse(await asrUrl)
  //     );

  //     request.files.add(await http.MultipartFile.fromPath(
  //       'file',
  //       zipFile.path,
  //       contentType: MediaType('application', 'zip'),
  //     ));

  //     var response = await request.send();
  //     if (response.statusCode == 200) {
  //       String responseBody = await response.stream.bytesToString();
  //       print('Audio ZIP sent successfully!');
  //       return responseBody;
  //     }
  //     print('Failed to upload ZIP: ${response.statusCode}');
  //     return null;
  //   } catch (e) {
  //     print('Error uploading audio ZIP file: $e');
  //     return null;
  //   }
  // }
  Future<String?> sendAudioToApi(File zipFile) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(await asrUrl),
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
    } else if (response.statusCode == 400) {
      String errorBody = await response.stream.bytesToString();
      print('Failed to upload ZIP: $errorBody');
      
      
      return errorBody;
    } else {
      print('Failed to upload ZIP: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error uploading audio ZIP file: $e');
    return null;
  }
}


  // LLM API calls
  // Future<Map<String, dynamic>?> sendToLLMApi(String formEntry, String schemeName, {String? voiceQuery}) async {
  //   final uri = Uri.parse(await llmUrl);
  //   print('LLM Request URL: $uri');
  //   print('LLM Request Form Entry: $formEntry');
  //   print('LLM Request Scheme Name: $schemeName');
  //   try {
  //     final response = await http.post(
  //       uri,
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({
  //         'form_entry': formEntry,
  //         'voice_query': voiceQuery ?? '',
  //         'scheme_name': schemeName,
  //       }),
  //     );
      

  //     if (response.statusCode == 200) {
  //       print('LLM Response: ${response.body}');
  //       return jsonDecode(response.body);
  //     }
  //     print('Failed to get LLM response: ${response.statusCode}');
  //     return null;
  //   } catch (e) {
  //     print('Error occurred while sending data to LLM API: $e');
  //     return null;
  //   }
  // }

// LLM API calls
  Future<Map<String, dynamic>?> sendToLLMApi(String formEntry, String schemeName, {String? voiceQuery}) async {
    final uri = Uri.parse(await llmUrl);

    // Print the request details for debugging
    print('LLM Request URL: $uri');
    print('LLM Request Form Entry: $formEntry');
    print('LLM Request Scheme Name: $schemeName');
    if (voiceQuery != null) {
      print('LLM Request Voice Query: $voiceQuery');
    }

    final requestBody = jsonEncode({
      'form_entry': formEntry,
      'voice_query': voiceQuery ?? '',
      'scheme_name': schemeName,
    });

    print('LLM Request Body: $requestBody');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
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
