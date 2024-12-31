import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path; // Add this import

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _documents = [];
  List<Map<String, dynamic>> get documents => _documents;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Fetch data from a Firestore collection
  Future<void> fetchCollection(String collectionPath) async {
    _setLoading(true);
    try {
      final querySnapshot = await _firestore.collection(collectionPath).get();
      _documents = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching collection: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add a document to a Firestore collection
  Future<void> addDocument(
      String collectionPath, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _firestore.collection(collectionPath).add(data);
      await fetchCollection(collectionPath); // Refresh data
    } catch (e) {
      print('Error adding document: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update a document in a Firestore collection
  Future<void> updateDocument(
      String collectionPath, String docId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _firestore.collection(collectionPath).doc(docId).update(data);
      await fetchCollection(collectionPath); // Refresh data
    } catch (e) {
      print('Error updating document: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a document from a Firestore collection
  Future<void> deleteDocument(String collectionPath, String docId) async {
    _setLoading(true);
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
      await fetchCollection(collectionPath); // Refresh data
    } catch (e) {
      print('Error deleting document: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveFormWithImage({
    required String uid,
    required String imagePath,
    required Map<String, dynamic> formData,
  }) async {
    _setLoading(true);
    try {
      // Read and encode image
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Create form document with image
      await _firestore.collection('users').doc(uid).collection('forms').add({
        'timestamp': FieldValue.serverTimestamp(),
        'imageBase64': base64Image,
        'fileName': path.basename(imagePath),
        'formData': formData,
      });
    } catch (e) {
      print('Error saving form with image: $e');
      throw Exception('Failed to save form');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveFormWithInteractions({
    required String uid,
    required String imagePath,
    required String fileName,
    required List<dynamic> boundingBoxes,
    required List<Map<String, dynamic>> chatMessages,
    required Map<String, dynamic> selectedFields,
  }) async {
    _setLoading(true);
    try {
      // Create form document reference
      final formRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('forms')
          .doc(); // Auto-generated ID

      // Convert image to base64
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Save main form document
      await formRef.set({
        'timestamp': FieldValue.serverTimestamp(),
        'imageBase64': base64Image,
        'fileName': path.basename(fileName),
        'status': 'active',
        'metadata': {
          'processedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'boundingBoxes': boundingBoxes,
        }
      });

      // Save fields and interactions as subcollections
      for (var field in selectedFields.entries) {
        final fieldRef = formRef.collection('fields').doc(field.key);
        await fieldRef.set({
          'fieldName': field.key,
          'ocrText': field.value['ocrText'],
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Save related interactions
        final relevantMessages =
            chatMessages.where((msg) => msg['fieldName'] == field.key).toList();

        for (var message in relevantMessages) {
          await fieldRef.collection('interactions').add({
            'timestamp': FieldValue.serverTimestamp(),
            'sender': message['sender'],
            'inputType': message['inputType'] ?? 'text',
            'asrResponse': message['asrResponse'],
            'llmResponse': message['message'],
          });
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error saving form data: $e');
      throw Exception('Failed to save form data');
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> getFormWithInteractions(
      String uid, String formId) async {
    try {
      print('Fetching form: $formId for user: $uid');
      final formDoc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('forms')
          .doc(formId)
          .get();

      if (!formDoc.exists) {
        print('Form document does not exist');
        return null;
      }

      final formData = formDoc.data()!;
      formData['id'] = formId;

      final interactionDoc = await formDoc.reference
          .collection('interactions')
          .doc('interactionLog')
          .get();

      print('Loading interaction data...');
      if (interactionDoc.exists) {
        // Ensure messages have correct content mapping
        final messages = (interactionDoc.data()?['messages'] ?? []).map((m) {
          if (m is Map) {
            return {
              ...m,
              'message': m['content'] ?? m['message'],
              'isAudioMessage': m['contentType'] == 'audio',
            };
          }
          return m;
        }).toList();

        formData['interactions'] = [{'messages': messages}];
      } else {
        formData['interactions'] = [];
      }

      print('Successfully loaded form data with ${formData['interactions']?[0]?['messages']?.length ?? 0} messages');
      return formData;
    } catch (e) {
      print('Error loading form with interactions: $e');
      return null;
    }
  }

  Future<String> saveFormWithDetails({
    required String uid,
    required String imagePath,
    required String selectedField,
    required String ocrText,
    required List<Map<String, dynamic>> chatMessages,
    required List<dynamic> boundingBoxes,
  }) async {
    _setLoading(true);
    try {
      // Clean up filename to match database format
      final fileName = path.basename(imagePath)
          .replaceAll('.', '_')
          .replaceAll('_png_png', '_png'); // Fix double extension
      
      final formRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('forms')
          .doc(fileName);

      print('Saving form with ID: $fileName');
      
      // Convert image to base64
      final File imageFile = File(imagePath);
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      // Save main form document
      await formRef.set({
        'id': fileName,
        'timestamp': FieldValue.serverTimestamp(),
        'lastInteractionAt': FieldValue.serverTimestamp(),
        'imageBase64': base64Image,
        'fileName': path.basename(imagePath),
        'boundingBoxes': boundingBoxes,
        'currentSelectedField': {
          'name': selectedField,
          'ocrText': ocrText,
        },
      }, SetOptions(merge: true));

      // Instead of separate docs, store all messages in a single 'interactionLog' doc
      final interactionDoc = formRef.collection('interactions').doc('interactionLog');
      await interactionDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _appendMessages(interactionDoc, chatMessages, selectedField, ocrText);

      notifyListeners();

      print('Saved form data: ${formRef.id}');
      return formRef.id; // Return the form ID
    } catch (e) {
      print('Error saving form data: $e');
      throw Exception('Failed to save form data');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addInteractionToForm({
    required String uid,
    required String formId,
    required String selectedField,
    required String ocrText,
    required List<Map<String, dynamic>> chatMessages,
  }) async {
    _setLoading(true);
    try {
      final formRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('forms')
          .doc(formId);

      // Update form's current state
      await formRef.update({
        'lastInteractionAt': FieldValue.serverTimestamp(),
        'currentSelectedField': {
          'name': selectedField,
          'ocrText': ocrText,
        },
      });

      // Add new interaction
      await _appendMessages(
        formRef.collection('interactions').doc('interactionLog'),
        chatMessages,
        selectedField,
        ocrText,
      );

      notifyListeners();
      print('Added interaction to form: $formId');
    } catch (e) {
      print('Error adding interaction: $e');
      throw Exception('Failed to add interaction');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _appendMessages(
      DocumentReference interactionDoc,
      List<Map<String, dynamic>> chatMessages,
      String selectedField,
      String ocrText) async {
    final List<Map<String, dynamic>> mappedMessages = [];

    for (var msg in chatMessages) {
      String? base64Audio;
      if (msg['isAudioMessage'] == true && msg['audioPath'] != null) {
        final fileBytes = await File(msg['audioPath']).readAsBytes();
        base64Audio = base64Encode(fileBytes);
      }

      mappedMessages.add({
        'timestamp': DateTime.now().toIso8601String(),
        'sender': msg['sender'],
        'content': msg['message'],
        'contentType': msg['isAudioMessage'] == true ? 'audio' : 'text',
        'base64Audio': base64Audio,
        'fieldName': selectedField,
        'ocrContext': ocrText,
      });
    }

    await interactionDoc.update({
      'messages': FieldValue.arrayUnion(mappedMessages),
    });
    print('Appended messages: $mappedMessages');
  }

  Future<List<Map<String, dynamic>>> getUserForms(String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('forms')
          .orderBy('lastInteractionAt', descending: true)
          .get();

      return await Future.wait(querySnapshot.docs.map((doc) async {
        final formData = doc.data();
        final interactionDoc = await doc.reference
            .collection('interactions')
            .doc('interactionLog')
            .get();

        final interactions = interactionDoc.exists
            ? [
                {
                  'messages': interactionDoc.data()?['messages'] ?? [],
                }
              ]
            : [];

        return {
          'id': doc.id,
          'timestamp': formData['timestamp'],
          'lastInteractionAt': formData['lastInteractionAt'],
          'fileName': formData['fileName'],
          'imageBase64': formData['imageBase64'],
          'boundingBoxes': formData['boundingBoxes'],
          'currentSelectedField': formData['currentSelectedField'],
          'interactions': interactions,
        };
      }));
    } catch (e) {
      print('Error fetching user forms: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubmittedForms() async {
    try {
      final querySnapshot = await _firestore.collectionGroup('forms').get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'formName': data['fileName'] ?? 'Unnamed Form',
          'formId': doc.id,
          'imageBase64': data['imageBase64'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error fetching submitted forms: $e');
      return [];
    }
  }
}
