// lib/models/form_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FormModel {
  final String id;
  final String imageBase64;
  final String fileName;
  final List<dynamic> boundingBoxes;
  final DateTime timestamp;
  final Map<String, dynamic> currentSelectedField;
  final List<Map<String, dynamic>> interactions;

  FormModel({
    required this.id,
    required this.imageBase64, 
    required this.fileName,
    required this.boundingBoxes,
    required this.timestamp,
    required this.currentSelectedField,
    this.interactions = const [],
  });

  factory FormModel.fromJson(String id, Map<String, dynamic> json) {
    return FormModel(
      id: id,
      imageBase64: json['imageBase64'],
      fileName: json['fileName'],
      boundingBoxes: json['boundingBoxes'] ?? [],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      currentSelectedField: json['currentSelectedField'] ?? {},
      interactions: (json['interactions'] ?? []).cast<Map<String, dynamic>>(),
    );
  }
}