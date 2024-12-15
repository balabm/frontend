import 'package:flutter/material.dart';
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
  Future<void> addDocument(String collectionPath, Map<String, dynamic> data) async {
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
  Future<void> updateDocument(String collectionPath, String docId, Map<String, dynamic> data) async {
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
}