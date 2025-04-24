// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   User? _user;
//   User? get user => _user;

//   Future<void> googleSignIn(BuildContext context) async {
//     _setLoading(true);
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         _setLoading(false);
//         return; // User canceled the sign-in process
//       }

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential = await _auth.signInWithCredential(credential);

//       _user = userCredential.user;
//       if (_user != null) {
//         // Save to Firebase
//         await _saveUserToFirebase(_user!.displayName ?? 'No Name', _user!.email ?? '', _user!.uid);

//         // Save username to SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('userName', _user!.displayName ?? 'No Name');

//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error during Google Sign-In: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     await _googleSignIn.signOut();
//     _user = null;
//     notifyListeners();
//   }
//   // Check if user is signed in
// //   Future<bool> checkUserSignedIn() async {
// //   final currentUser = _auth.currentUser;
// //   if (currentUser != null) {
// //     _user = currentUser;
// //     notifyListeners();
// //     return true;
// //   } else {
// //     return false;
// //   }
// // }
// Future<bool> checkUserSignedIn() async {
//   final currentUser = _auth.currentUser;
//   if (currentUser != null) {
//     _user = currentUser;

//     // Check if the user's document exists in Firestore
//     final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
//     if (!userDoc.exists) {
//       print('❌ User document does not exist in Firestore. Signing out...');
//       await signOut(); // Sign out the user
//       return false; // User is not signed in
//     }

//     print('✅ User is authenticated and document exists in Firestore.');
//     notifyListeners();
//     return true; // User is signed in and document exists
//   } else {
//     print('❌ User is not authenticated.');
//     return false; // User is not signed in
//   }
// }
// Future<void> _saveUserToFirebase(String name, String email, String uid) async {
//   try {
//     await FirebaseFirestore.instance.collection('users').doc(uid).set({
//       'userName': name,
//       'email': email,
//       'uid': uid,
//       'createdAt': FieldValue.serverTimestamp(),
//       'lastLogin': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true));
//   } catch (e) {
//     print('Error saving user data: $e');
//   }
// }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthProvider with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   User? _user;
//   User? get user => _user;

//   Future<void> googleSignIn(BuildContext context) async {
//     _setLoading(true);
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         _setLoading(false);
//         return; // User canceled the sign-in process
//       }

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential = await _auth.signInWithCredential(credential);

//       _user = userCredential.user;
//       if (_user != null) {
//         // Save to Firebase
//         await _saveUserToFirebase(_user!.displayName ?? 'No Name', _user!.email ?? '', _user!.uid);

//         // Save username to SharedPreferences
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('userName', _user!.displayName ?? 'No Name');
        
//         // Save initial activity timestamp
//         await prefs.setString('lastActivity', DateTime.now().toIso8601String());

//         Navigator.pushReplacementNamed(context, '/home');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error during Google Sign-In: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       _setLoading(false);
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     await _googleSignIn.signOut();
//     _user = null;
//     notifyListeners();
//   }

//   Future<bool> checkUserSignedIn() async {
//     final currentUser = _auth.currentUser;
//     if (currentUser != null) {
//       _user = currentUser;

//       // Check if the user's document exists in Firestore
//       final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
//       if (!userDoc.exists) {
//         print('❌ User document does not exist in Firestore. Signing out...');
//         await signOut(); // Sign out the user
//         return false; // User is not signed in
//       }

//       // Check if user has been inactive for more than 3 days
//       final prefs = await SharedPreferences.getInstance();
//       final lastActivityString = prefs.getString('lastActivity');
      
//       if (lastActivityString != null) {
//         final lastActivity = DateTime.parse(lastActivityString);
//         final now = DateTime.now();
//         final difference = now.difference(lastActivity);
        
//         // Log out if inactive for 3 days (259200 seconds)
//         if (difference.inSeconds > 259200) {
//           print('❌ User inactive for more than 3 days. Signing out...');
//           await signOut();
//           return false;
//         }
//       }

//       // Update last login timestamp in Firestore
//       await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
//         'lastLogin': FieldValue.serverTimestamp(),
//       });

//       print('✅ User is authenticated and document exists in Firestore.');
//       notifyListeners();
//       return true; // User is signed in and document exists
//     } else {
//       print('❌ User is not authenticated.');
//       return false; // User is not signed in
//     }
//   }

//   Future<void> _saveUserToFirebase(String name, String email, String uid) async {
//     try {
//       await FirebaseFirestore.instance.collection('users').doc(uid).set({
//         'userName': name,
//         'email': email,
//         'uid': uid,
//         'createdAt': FieldValue.serverTimestamp(),
//         'lastLogin': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     } catch (e) {
//       print('Error saving user data: $e');
//     }
//   }

//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }
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
        // Save basic info to Firebase
        await _saveUserToFirebase(_user!.displayName ?? 'No Name', _user!.email ?? '', _user!.uid);

        // Save username to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', _user!.displayName ?? 'No Name');
        //await prefs.setString('dp', _user!. ?? 'No Name');

        // Save initial activity timestamp
        await prefs.setString('lastActivity', DateTime.now().toIso8601String());

        // Check if user has completed profile details
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
        final bool detailsCompleted = userDoc.data()?['detailsCompleted'] ?? false;

        // Navigate to appropriate screen
        if (detailsCompleted) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(context, '/user_details');
        }
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

  Future<bool> checkUserSignedIn() async {

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _user = currentUser;

      // Check if the user's document exists in Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        print('❌ User document does not exist in Firestore. Signing out...');
        await signOut(); // Sign out the user
        return false; // User is not signed in
      }

      // Check if user has been inactive for more than 3 days
      final prefs = await SharedPreferences.getInstance();
      final lastActivityString = prefs.getString('lastActivity');
      
      if (lastActivityString != null) {
        final lastActivity = DateTime.parse(lastActivityString);
        final now = DateTime.now();
        final difference = now.difference(lastActivity);
        
        // Log out if inactive for 3 days (259200 seconds)
        if (difference.inSeconds > 259200) {
          print('❌ User inactive for more than 3 days. Signing out...');
          await signOut();
          return false;
        }
      }

      // Update last login timestamp in Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Check if user has completed profile details
      final bool detailsCompleted = userDoc.data()?['detailsCompleted'] ?? false;
      
      
      print('✅ User is authenticated and document exists in Firestore.');
      print('✅ User details completed: $detailsCompleted');

      notifyListeners();
      return true; // User is signed in and document exists
    } else {
      print('❌ User is not authenticated.');
      return false; // User is not signed in
    }
  }

  Future<Map<String, dynamic>?> getUserDetails() async {
    if (_user == null) return null;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      return userDoc.data();
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  Future<void> updateUserDetails({
    String? preferredLanguage,
    String? gender,
    int? age,
  }) async {
    if (_user == null) return;
    
    try {
      final updateData = <String, dynamic>{
        'detailsCompleted': true,
      };
      
      if (preferredLanguage != null) updateData['preferredLanguage'] = preferredLanguage;
      if (gender != null) updateData['gender'] = gender;
      if (age != null) updateData['age'] = age;
      
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update(updateData);
    } catch (e) {
      print('Error updating user details: $e');
      rethrow;
    }
  }

  Future<void> _saveUserToFirebase(String name, String email, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'userName': name,
        'email': email,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        //'detailsCompleted': false, // Add this field to track if user has completed profile
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