import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FirebaseHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create a form document for the user
  // Future<String> getOrCreateFormDoc(String uid, String userName, String email) async {
  //   final formRef = _firestore.collection('forms').doc(uid);

  //   final existingForm = await formRef.get();
  //   if (!existingForm.exists) {
  //     await formRef.set({
  //       'userName': userName,
  //       'email': email,
  //       'createdAt': FieldValue.serverTimestamp(),
  //       'lastLogin': FieldValue.serverTimestamp(),
  //     });
  //   } else {
  //     await formRef.update({
  //       'lastLogin': FieldValue.serverTimestamp(),
  //     });
  //   }

  //   return formRef.id;
  // }

  

/// Get or create a form document for the user
// Future<String> getOrCreateFormDoc(
//   String uid,
//   String userName,
//   String email, {
//   String? language,
//   String? gender,
//   int? age,
//   String? profileImageUrl, // Added parameter
// }) async {
//   final formRef = _firestore.collection('forms').doc(uid);

//   final existingForm = await formRef.get();
//   if (!existingForm.exists) {
//     Map<String, dynamic> data = {
//       'userName': userName,
//       'email': email,
//       'preferredLanguage': language ?? 'English',
//       'gender': gender ?? 'Prefer not to say',
//       'age': age,
//       'createdAt': FieldValue.serverTimestamp(),
//       'lastLogin': FieldValue.serverTimestamp(),
//     };
//     // Add profile image if provided
//     if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
    
//     await formRef.set(data);
//   } else {
//     Map<String, dynamic> updates = {
//       'lastLogin': FieldValue.serverTimestamp(),
//     };
    
//     // Add fields only if provided
//     if (language != null) updates['preferredLanguage'] = language;
//     if (gender != null) updates['gender'] = gender;
//     if (age != null) updates['age'] = age;
//     if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    
//     await formRef.update(updates);
//   }
  
//   return formRef.id;
// }
Future<String> getOrCreateFormDoc(
  String uid,
  String userName,
  String email, {
  String? language,
  String? gender,
  int? age,
  String? state, // New parameter
  String? nation, // New parameter
  String? profileImageUrl,
}) async {
  final formRef = _firestore.collection('forms').doc(uid);

  final existingForm = await formRef.get();
  if (!existingForm.exists) {
    Map<String, dynamic> data = {
      'userName': userName,
      'email': email,
      'preferredLanguage': language ?? 'English',
      'gender': gender ?? 'Prefer not to say',
      'age': age,
      'state': state, // Add state
      'nation': nation, // Add nation
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
    // Add profile image if provided
    if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
    
    await formRef.set(data);
  } else {
    Map<String, dynamic> updates = {
      'lastLogin': FieldValue.serverTimestamp(),
    };
    
    // Add fields only if provided
    if (language != null) updates['preferredLanguage'] = language;
    if (gender != null) updates['gender'] = gender;
    if (age != null) updates['age'] = age;
    if (state != null) updates['state'] = state; // Update state
    if (nation != null) updates['nation'] = nation; // Update nation
    if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
    
    await formRef.update(updates);
  }
  
  return formRef.id;
}
  /// Store or update interaction data in a single document under `interactions`
  Future<void> storeInteraction({
    required String uid,
    required String fileName,
    required List<Map<String, dynamic>> boundingBoxes,
    required Map<String, dynamic> selectedFields,
  }) async {
    final interactionRef = _firestore
        .collection('forms')
        .doc(uid)
        .collection('interactions')
        .doc('mainInteraction');

    await interactionRef.set({
      'fileName': fileName,
      'boundingBoxes': boundingBoxes,
      'selectedFields': selectedFields,
      'chatMessages': FieldValue.arrayUnion([]), // Ensure array exists
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Merge to avoid overwriting
  }

  /// Add a chat message to the interaction document
  Future<void> addChatMessage({
    required String uid,
    required Map<String, dynamic> message,
  }) async {
    final interactionRef = _firestore
        .collection('forms')
        .doc(uid)
        .collection('interactions')
        .doc('mainInteraction');

    await interactionRef.update({
      'chatMessages': FieldValue.arrayUnion([message]),
    });
  }

  /// Get all interactions for a specific user
  Future<Map<String, dynamic>?> getMainInteraction(String uid) async {
    final interactionRef = _firestore
        .collection('forms')
        .doc(uid)
        .collection('interactions')
        .doc('mainInteraction');

    final interactionSnap = await interactionRef.get();
    return interactionSnap.exists ? interactionSnap.data() : null;
  }


  // Add this method to FirebaseHandler class
Future<Map<String, dynamic>> getUserProfileDetails(String uid) async {
  try {
    // First check in 'forms' collection which has the user profile
    final formDoc = await _firestore.collection('forms').doc(uid).get();
    
    if (formDoc.exists) {
      final data = formDoc.data() ?? {};
      return {
        'gender': data['gender'] ?? 'Prefer not to say',
        'age': data['age'] ?? 0,
        'state': data['state'] ?? '',
        'nation': data['nation'] ?? '',
        'first_language': data['preferredLanguage'] ?? 'English',
      };
    }
    
    // Fallback to check in 'users' collection if needed
    final userDoc = await _firestore.collection('users').doc(uid).get();
    
    if (userDoc.exists) {
      final data = userDoc.data() ?? {};
      return {
        'gender': data['gender'] ?? 'Prefer not to say',
        'age': data['age'] ?? 0,
        'state': data['state'] ?? '',
        'nation': data['nation'] ?? '',
        'first_language': data['preferredLanguage'] ?? 'English',
      };
    }
    
    // Return default values if no user profile is found
    return {
      'gender': 'Prefer not to say',
      'age': 0,
      'state': '',
      'nation': '',
      'first_language': 'English',
    };
  } catch (e) {
    print('Error fetching user profile details: $e');
    // Return default values on error
    return {
      'gender': 'Prefer not to say',
      'age': 0,
      'state': '',
      'nation': '',
      'first_language': 'English',
    };
  }
}

  /// Delete the main interaction document
  Future<void> deleteMainInteraction(String uid) async {
    final interactionRef = _firestore
        .collection('forms')
        .doc(uid)
        .collection('interactions')
        .doc('mainInteraction');

    await interactionRef.delete();
  }

  /// Delete a form document and its interactions
  Future<void> deleteForm(String uid, String formId) async {
    final formRef = _firestore.collection('users').doc(uid).collection('forms').doc(formId);

    // Delete interactions subcollection
    final interactions = await formRef.collection('interactions').get();
    for (var doc in interactions.docs) {
      await doc.reference.delete();
    }

    // Delete the form document
    await formRef.delete();
  }
}