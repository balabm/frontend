import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get or create a form document for the user
  Future<String> getOrCreateFormDoc(String uid, String userName, String email) async {
    final formRef = _firestore.collection('forms').doc(uid);

    final existingForm = await formRef.get();
    if (!existingForm.exists) {
      await formRef.set({
        'userName': userName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await formRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
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
