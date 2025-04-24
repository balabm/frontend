import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

// Add this method to the FirebaseProvider class

// Future<void> updateFormName(String uid, String formId, String newName) async {
//   _setLoading(true);
//   try {
//     print('Updating form name for UID: $uid, Form ID: $formId, New Name: $newName');

//     // Reference to the specific form document in Firestore
//     final formRef = FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .collection('forms')
//         .doc(formId);

//     // Update the fileName field in Firestore
//     await formRef.update({
//       'fileName': newName, // Update the fileName field
//       'lastInteractionAt': FieldValue.serverTimestamp(), // Optional: Update timestamp
//     });

//     notifyListeners();
//     print('Form name updated in Firebase: $formId -> $newName');
//   } catch (e) {
//     print('Error updating form name in Firebase: $e');
//     throw Exception('Failed to update form name in Firebase');
//   } finally {
//     _setLoading(false);
//   }
// }
Future<void> updateFormName(String uid, String formId, String newName) async {
  _setLoading(true);
  try {
    print('🔹 Start: Updating form name');
    print('🔹 UID: $uid, Form ID: $formId, New Name: $newName');

    // Reference to the forms collection
    final formsCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('forms');

    // Print all document IDs to verify `formId`
    final snapshot = await formsCollection.get();
    if (snapshot.docs.isEmpty) {
      print('❌ No forms found for this user.');
      throw Exception('No forms found for this user.');
    }

    print('🔹 Existing Form IDs:');
    for (var doc in snapshot.docs) {
      print('   - ${doc.id}');
    }

    // Reference to the specific form document
    final formRef = formsCollection.doc(formId);

    print('🔹 Checking if the document exists in Firestore...');
    final docSnapshot = await formRef.get();

    if (!docSnapshot.exists) {
      print('❌ Error: Document does not exist! Form ID: $formId');
      throw Exception('Document does not exist');
    }

    // Print the current document data before updating
    print('🔹 Document Data Before Update: ${docSnapshot.data()}');

    print('🔹 Document exists, proceeding with update...');

    // Update the fileName field in Firestore
    await formRef.update({
      'fileName': newName, // Update the fileName field
      'lastInteractionAt': FieldValue.serverTimestamp(), // Update timestamp
    });

    print('✅ Success: Form name updated in Firebase');

    // Print the updated document data
    final updatedSnapshot = await formRef.get();
    print('🔹 Document Data After Update: ${updatedSnapshot.data()}');

    notifyListeners();
  } on FirebaseException catch (e) {
    print('❌ FirebaseException: Code: ${e.code}, Message: ${e.message}');
    throw Exception('Firebase error: ${e.message}');
  } catch (e) {
    print('❌ General Exception: $e');
    throw Exception('Failed to update form name: $e');
  } finally {
    print('🔹 Finished update operation');
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
Future<String> saveFormWithDetails({
    required String uid,
    required String imagePath,
    required String selectedField,
    required String ocrText,
    required List<Map<String, dynamic>> chatMessages,
    required List<dynamic> boundingBoxes,
    required String selectedForm,  // Add this parameter
    Map<String, dynamic>? selectedBox,
  }) async {
    _setLoading(true);
    try {
      // Clean up filename to match database format
      final fileName = path
          .basename(imagePath)
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
        'selectedForm': selectedForm,
        'fileName': path.basename(imagePath),
        'boundingBoxes': boundingBoxes,
        'currentSelectedField': {
          'name': selectedField,
          'ocrText': ocrText,
        },
      }, SetOptions(merge: true));

      

// Step 1: Ensure interactionLog exists before appending messages
final interactionDoc = formRef.collection('interactions').doc('interactionLog');

// Ensure the document exists first
DocumentSnapshot docSnapshot = await interactionDoc.get();
if (!docSnapshot.exists) {
  await interactionDoc.set({'timestamp': FieldValue.serverTimestamp(), 'messages': []});
}

// Append messages in a controlled manner
await _appendMessages(
  interactionDoc,
  chatMessages,
  selectedField,
  ocrText,
  selectedBox: selectedBox,
);

notifyListeners(); // Ensure this is not calling multiple times


      print('Saved form data: ${formRef.id}');
      return formRef.id; // Return the form ID
    } catch (e) {
      print('Error saving form data: $e');
      throw Exception('Failed to save form data');
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

// In FirebaseProvider class
  Future<void> saveFormWithInteractions({
    required String uid,
    required String imagePath,
    required String fileName,
    required List<dynamic> boundingBoxes,
    required List<Map<String, dynamic>> chatMessages,
    required Map<String, dynamic> selectedFields,
    required String selectedForm, 
  }) async {
    _setLoading(true);
    try {
      final formRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('forms')
          .doc(fileName);

      // Store both original and sanitized filenames
      final originalFileName = path.basename(imagePath);
      final sanitizedFileName = fileName;

      await formRef.set({
        'timestamp': DateTime.now().toIso8601String(),
        'lastInteractionAt': DateTime.now().toIso8601String(),
        'fileName': sanitizedFileName,
        'originalFileName': originalFileName,
        'selectedForm': selectedForm,
        'imagePath': imagePath,
        //'selectedForm': selectedForm,
        'boundingBoxes':
            boundingBoxes.map((box) => Map<String, dynamic>.from(box)).toList(),
        
        'currentSelectedField': Map<String, dynamic>.from(selectedFields),
      }, SetOptions(merge: true));
      
final interactionDoc = formRef.collection('interactions').doc('interactionLog');

// Step 1: Fetch existing messages
final docSnapshot = await interactionDoc.get();
List<dynamic> existingMessages = [];

if (docSnapshot.exists) {
  final data = docSnapshot.data();
  if (data != null && data['messages'] != null) {
    existingMessages = List.from(data['messages']);
  }
}

print("🔹 Step 1: Existing Messages from Firestore (Before Merge)");
for (int i = 0; i < existingMessages.length; i++) {
  print("📥 Index $i -> ${existingMessages[i]}");
}

// Step 2: Get new messages from `chatMessages`
final newMessages = chatMessages.map((msg) => {
  'sender': msg['sender'],
  'message': msg['message'],

  'isAudioMessage': msg['isAudioMessage'] ?? false,
  'audioBase64': msg['audioBase64'],
  'timestamp': DateTime.now().toIso8601String(),
}).toList();

print("🔹 Step 2: New Messages to be Added");
for (int i = 0; i < newMessages.length; i++) {
  print("🆕 Index $i -> ${newMessages[i]}");
}

// Step 3: Avoid duplicates (Check only sender and message)
for (var newMsg in newMessages) {
  bool alreadyExists = existingMessages.any((msg) =>
      msg['message'] == newMsg['message'] &&
      msg['sender'] == newMsg['sender']); // Ignore timestamp difference

  if (!alreadyExists) {
    existingMessages.add(newMsg);
    print("✅ Added New Message -> ${newMsg}");
  } else {
    print("⚠️ Duplicate Detected, Skipping -> ${newMsg}");
  }
}

print("🔹 Step 3: Final Messages List (Before Saving)");
for (int i = 0; i < existingMessages.length; i++) {
  print("📤 Index $i -> ${existingMessages[i]}");
}

// Step 4: Save merged messages to Firestore
await interactionDoc.set({
  'timestamp': DateTime.now().toIso8601String(),
  'messages': existingMessages, 
}, SetOptions(merge: true));

print("📝 Step 4: Messages successfully saved to Firestore!");

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

      final formData = Map<String, dynamic>.from(formDoc.data()!);
      formData['id'] = formId;

      final interactionDoc = await formDoc.reference
          .collection('interactions')
          .doc('interactionLog')
          .get();

      print('Loading interaction data...');
      if (interactionDoc.exists) {
        final messages =
            ((interactionDoc.data()?['messages'] ?? []) as List).map((m) {
          if (m is Map) {
            return {
              ...Map<String, dynamic>.from(m as Map<dynamic, dynamic>),
              'message': m['content'] ?? m['message'],
              'isAudioMessage': m['contentType'] == 'audio',
            };
          }
          return <String, dynamic>{};
        }).toList();

        formData['interactions'] = [
          {'messages': messages}
        ];
      } else {
        formData['interactions'] = [];
      }

      print(
          'Successfully loaded form data with ${formData['interactions']?[0]?['messages']?.length ?? 0} messages');
      return formData;
    } catch (e) {
      print('Error loading form with interactions: $e');
      return null;
    }
  }

  

  Future<String> FormWithDetails({
    required String uid,
    required String imagePath,
    required String selectedField,
    required String ocrText,
    required List<Map<String, dynamic>> chatMessages,
    required List<dynamic> boundingBoxes,
    required String selectedForm,  // Add this parameter
    Map<String, dynamic>? selectedBox,
  }) async {
    _setLoading(true);
    try {
      // Clean up filename to match database format
      final fileName = path
          .basename(imagePath)
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
        'selectedForm': selectedForm,
        'fileName': path.basename(imagePath),
        'boundingBoxes': boundingBoxes,
        'currentSelectedField': {
          'name': selectedField,
          'ocrText': ocrText,
        },
      }, SetOptions(merge: true));

      

// Step 1: Ensure interactionLog exists before appending messages
final interactionDoc = formRef.collection('interactions').doc('interactionLog');

// Ensure the document exists first
DocumentSnapshot docSnapshot = await interactionDoc.get();
if (!docSnapshot.exists) {
  await interactionDoc.set({'timestamp': FieldValue.serverTimestamp(), 'messages': []});
}

// Append messages in a controlled manner
await _appendMessages(
  interactionDoc,
  chatMessages,
  selectedField,
  ocrText,
  selectedBox: selectedBox,
);

notifyListeners(); // Ensure this is not calling multiple times


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


      notifyListeners();
      print('Added interaction to form: $formId');
    } catch (e) {
      print('Error adding interaction: $e');
      throw Exception('Failed to add interaction');
    } finally {
      _setLoading(false);
    }
  }

 // Add this method to your FirebaseProvider class
Future<void> updateMessageFeedback({
  required String uid,
  required String docId,
  required List<Map<String, dynamic>> feedbackUpdates,
}) async {
  print('🚀 Starting feedback update for doc: $docId');
  print('📤 Feedback updates: ${feedbackUpdates.length} items');

  try {
    // Get reference to INTERACTION LOG document
    final interactionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('forms')
        .doc(docId)
        .collection('interactions')
        .doc('interactionLog');

    print('🔍 Checking interaction log existence...');
    final docSnapshot = await interactionRef.get();
    
    if (!docSnapshot.exists) {
      print('❌ Interaction log not found for doc: $docId');
      throw Exception('Interaction log document does not exist');
    }

    final data = docSnapshot.data() as Map<String, dynamic>;
    print('📄 Document data keys: ${data.keys.join(', ')}');

    // Initialize messages list with fallback
    List<Map<String, dynamic>> messages = [];
    if (data.containsKey('messages')) {
      messages = List<Map<String, dynamic>>.from(data['messages']);
    } else {
      print('⚠️ No messages array found - initializing empty list');
    }

    print('📩 Found ${messages.length} messages in interaction log');

    bool hasUpdates = false;
    final updatedMessages = [...messages]; // Create a mutable copy

    for (final update in feedbackUpdates) {
      final messageId = update['messageId'];
      final index = update['index'];
      final feedback = update['feedback'];
      
      if (messageId == null && index == null) {
        print('🚨 Invalid update format - needs messageId or index: $update');
        continue;
      }

      print('\n🔎 Searching for message to update...');
      
      for (int i = 0; i < updatedMessages.length; i++) {
        final message = updatedMessages[i];
        
        // Try to match by messageId first (preferred method)
        if (messageId != null && message['messageId'] == messageId) {
          print('✅ Match found by messageId at index $i');
          print('   Old feedback: ${message['feedback']}');
          print('   New feedback: $feedback');
          
 updatedMessages[i] = {
    ...message,
    'feedback': feedback,
    'feedbackCategory': update['feedbackCategory'],
    'feedbackComments': update['feedbackText'],
  };          hasUpdates = true;
          break;
        }
        
        // Fallback to index-based matching if index is provided and within range
        if (messageId == null && index != null && index == i) {
          print('✅ Match found by index at position $i');
          updatedMessages[i] = {...message, 'feedback': feedback};
          hasUpdates = true;
          break;
        }
      }
    }

    if (hasUpdates) {
      print('\n💾 Saving updated messages to Firestore...');
      await interactionRef.update({'messages': updatedMessages});
      print('🎉 Successfully updated feedback');
    } else {
      print('\n⏩ No matching messages found for updates');
    }
  } on FirebaseException catch (e) {
    print('🔥 Firebase error: ${e.code} - ${e.message}');
    throw Exception('Firebase update failed: ${e.message}');
  } catch (e, stack) {
    print('💥 Critical error: $e');
    print('Stack trace: $stack');
    throw Exception('Feedback update failed: $e');
  }
}


Future<void> _appendMessages(
  DocumentReference interactionDoc,
  List<Map<String, dynamic>> chatMessages,
  String selectedField,
  String ocrText, {
  Map<String, dynamic>? selectedBox,
}) async {
  // Ensure the interactionLog document exists
  final docSnapshot = await interactionDoc.get();
  if (!docSnapshot.exists) {
    print('DEBUG: interactionLog document does not exist. Creating it...');
    await interactionDoc.set({'messages': []});
  }

  final List<Map<String, dynamic>> mappedMessages = [];

  for (var msg in chatMessages) {
    print('Processing message for Firestore: $msg');
    print('Feedback value being saved: ${msg['feedback']}');

    String? base64Audio;
    if (msg['isAudioMessage'] == true && msg['audioPath'] != null) {
      final fileBytes = await File(msg['audioPath']).readAsBytes();
      base64Audio = base64Encode(fileBytes);
    }

    // Generate a unique messageId if one doesn't exist
    final messageId = msg['messageId'] ?? _generateUniqueId();

    mappedMessages.add({
      'messageId': messageId,
      //'timestamp': msg['timestamp'] ?? DateTime.now().toIso8601String(), // Use existing timestamp or generate a new one

      'timestamp': DateTime.now().toIso8601String(),
      

// 'timestamp': msg['timestamp'] != null
//       ? DateTime.parse(msg['timestamp']).toUtc().toIso8601String() // Parse and convert to UTC
//       : DateTime.now().toUtc().toIso8601String(), // Use current time if timestamp is null      'sender': msg['sender'],
      'sender': msg['sender'], // Ensure sender is mapped correctly
      'content': msg['message'],
      'contentType': msg['isAudioMessage'] == true ? 'audio' : 'text',
      'base64Audio': base64Audio,
      'feedback': msg['feedback'],
      'selectedBox': selectedBox != null ? Map<String, dynamic>.from(selectedBox) : null,
    });

    print('Mapped message: ${mappedMessages.last}');
  }

  print('DEBUG: Attempting to append messages to Firestore...');
  await interactionDoc.update({
    'messages': FieldValue.arrayUnion(mappedMessages),
  });
  print('Appended messages: $mappedMessages');
}

// 3. Add a helper method to generate unique IDs:

String _generateUniqueId() {
  return DateTime.now().millisecondsSinceEpoch.toString() + 
         '_' + 
         (1000 + Random().nextInt(9000)).toString();
}// Helper method to generate a unique hash for a message
String _generateMessageHash(String sender, String content) {
  return '$sender|$content'.hashCode.toString();
}

  Future<List<Map<String, dynamic>>> getSubmittedForms({required String userId}) async {
    try {
      // Query forms specifically from the user's subcollection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('forms')
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No forms found for user: $userId');
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'formName': data['fileName'] ?? 'Unnamed Form',
          'formId': doc.id,
          'imageBase64': data['imageBase64'] ?? '',
          'timestamp': data['timestamp'],
          'lastInteractionAt': data['lastInteractionAt'],
          'currentSelectedField': data['currentSelectedField'],
          'userId': userId  // Add userId for verification
          
        };
      }).toList();
    } catch (e) {
      print('Error fetching submitted forms for user $userId: $e');
      return [];
    }
  }

  Map<String, dynamic> sanitizeForFirestore(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    
    // Remove fields that can't be stored in Firestore
    result.removeWhere((key, value) => 
      value is File || 
      key == 'audioPath' || // Local file paths can't be stored
      value == null || // Consider removing null values
      key.contains('.') || key.contains('/') || key.contains('[') || key.contains(']') // Invalid field name characters
    );
    
    // Convert timestamps if needed
    if (result.containsKey('timestamp') && result['timestamp'] is DateTime) {
      result['timestamp'] = (result['timestamp'] as DateTime).toIso8601String();
    }
    
    // Make sure messageId is a string
    if (result.containsKey('messageId') && result['messageId'] != null) {
      result['messageId'] = result['messageId'].toString();
    }
    
    return result;
  }
}
