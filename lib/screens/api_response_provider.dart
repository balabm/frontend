import 'package:flutter/material.dart';

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
