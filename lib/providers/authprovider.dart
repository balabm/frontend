import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _user;
  User? get user => _user;

  Future<void> googleSignIn(BuildContext context) async {
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return; // User canceled the sign-in process
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      _user = userCredential.user;
      if (_user != null) {
        // Save to Firebase
        await _saveUserToFirebase(_user!.displayName ?? 'No Name', _user!.email ?? '', _user!.uid);

        // Save username to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _user!.displayName ?? 'No Name');

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during Google Sign-In: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }
Future<void> _saveUserToFirebase(String name, String email, String uid) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'userName': name,
      'email': email,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  } catch (e) {
    print('Error saving user data: $e');
  }
}

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}