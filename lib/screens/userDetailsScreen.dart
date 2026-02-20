import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:formbot/helpers/firebase_handler.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:path/path.dart' as path;
import 'dart:convert';

class UserDetailsScreen extends StatefulWidget {
  final bool isEditMode;

  const UserDetailsScreen({
    Key? key,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _stateController = TextEditingController(); // New controller for state
  final _nationController =
      TextEditingController(); // New controller for nation
  String _selectedGender = 'Prefer not to say';
  String _selectedLanguage = 'English';
  String _selectedState = ''; // New variable for dropdown state

  bool _isLoading = false;
  File? _profileImage;
  String? _currentProfileImageUrl;
  bool _isUploadingImage = false;

  // Language options
  final List<String> _languages = [
    // 'English',
    // 'French',
    // 'Hindi',
    // 'Kannada'
    'Assamese',
    'Bengali',
    'Bodo',
    'Dogri',
    'Gujarati',
    'Hindi',
    'Kannada',
    'Kashmiri',
    'Konkani',
    'Maithili',
    'Malayalam',
    'Manipuri (Meitei)',
    'Marathi',
    'Nepali',
    'Odia',
    'Punjabi',
    'Sanskrit',
    'Santali',
    'Sindhi',
    'Tamil',
    'Telugu',
    'Urdu'
  ];

  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal'
  ];

  // Gender options
  final List<String> _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _ageController.dispose();
    //_stateController.dispose(); // Dispose new controller
    _nationController.dispose(); // Dispose new controller
    super.dispose();
  }

  // Future<void> _loadUserData() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;

  //   setState(() => _isLoading = true);

  //   try {
  //     final userDoc = await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(user.uid)
  //         .get();

  //     if (userDoc.exists && userDoc.data() != null) {
  //       final userData = userDoc.data()!;

  //       setState(() {
  //         _selectedLanguage = userData['preferredLanguage'] ?? 'English';
  //         _selectedGender = userData['gender'] ?? 'Prefer not to say';
  //         _ageController.text = userData['age']?.toString() ?? '';
  //         _stateController.text = userData['state'] ?? ''; // Load state
  //         _nationController.text = userData['nation'] ?? ''; // Load nation
  //         _currentProfileImageUrl = userData['profileImageUrl'];
  //       });
  //     }
  //   } catch (e) {
  //     Common.showMessage(
  //         context, 'Error loading user data: ${e.toString()}', isError: true);
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;

        setState(() {
          _selectedLanguage = userData['preferredLanguage'] ?? 'Hindi';
          _selectedGender = userData['gender'] ?? 'Prefer not to say';
          _ageController.text = userData['age']?.toString() ?? '';
          _selectedState = userData['state'] ?? ''; // Load selected state
          _nationController.text =
              userData['nation'] ?? ''; // Keep loading nation
          _currentProfileImageUrl = userData['profileImageUrl'];
        });
      }
    } catch (e) {
      Common.showMessage(context, 'Error loading user data: ${e.toString()}',
          isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 1024, // Reduced resolution to keep file size small
        maxHeight: 1024,
        imageQuality: 60, // Reduced quality to stay under Firestore's 1MB limit
      );

      if (pickedImage != null) {
        // Send to cropping screen
        final croppedFile = await _cropImage(File(pickedImage.path));

        if (croppedFile != null) {
          setState(() {
            _profileImage = croppedFile;
          });
        }
      }
    } catch (e) {
      Common.showMessage(context, 'Error picking image: ${e.toString()}',
          isError: true);
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(
            ratioX: 1, ratioY: 1), // Square aspect ratio for profile pictures
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: const Color(0xFF00BFA5),
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: const Color(0xFF00BFA5),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            showCropGrid: true,
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
          ),
          WebUiSettings(
            context: context,
            // presentStyle: 'dialog',  // String value instead of enum
            // boundary: const CroppieBoundary(width: 400, height: 400),
            // viewPort: const CroppieViewPort(width: 300, height: 300, type: 'circle'),
            // enableExif: true,
            // enableZoom: true,
            // showZoomer: true,
          ),
        ],
      );

      if (croppedFile != null) {
        return File(croppedFile.path);
      }
      return null;
    } catch (e) {
      print('Error cropping image: $e');
      // Don't block the flow if cropping fails, use original image
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error during image cropping. Using original image.'),
          backgroundColor: Colors.orange,
        ),
      );
      return imageFile; // Return original image on error
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Text(
                //   'Select and crop your profile picture',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: Colors.grey.shade600,
                //   ),
                //   textAlign: TextAlign.center,
                // ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _imageSourceOption(
                      icon: Icons.camera_alt,
                      title: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _imageSourceOption(
                      icon: Icons.photo_library,
                      title: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (_profileImage != null ||
                        _currentProfileImageUrl != null)
                      _imageSourceOption(
                        icon: Icons.delete,
                        title: 'Remove',
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _profileImage = null;
                            _currentProfileImageUrl = null;
                          });
                        },
                        color: Colors.red.shade300,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _imageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color ?? Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 30,
              color: color != null ? Colors.white : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color != null ? color : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadProfileImage() async {
    if (_profileImage == null) {
      print('No profile image selected, returning current URL');
      return _currentProfileImageUrl;
    }

    setState(() => _isUploadingImage = true);
    String? downloadUrl;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(_profileImage!.path);
      final cleanExtension =
          extension.startsWith('.') ? extension.substring(1) : extension;

      final fileName = 'profile_images/${user.uid}_$timestamp.$cleanExtension';
      final storageRef = FirebaseStorage.instance.ref(fileName);

      print('Uploading to: ${storageRef.fullPath}');

      if (!await _profileImage!.exists()) {
        throw Exception('Image file not found or not readable');
      }

      final metadata = SettableMetadata(contentType: 'image/$cleanExtension');
      final uploadTask = storageRef.putFile(_profileImage!, metadata);

      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        },
        onError: (e) => print('Upload error: $e'),
      );

      final taskSnapshot = await uploadTask;
      if (taskSnapshot.state == TaskState.success) {
        downloadUrl = await storageRef.getDownloadURL();
        print('Upload successful. URL: $downloadUrl');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profileImageUrl': downloadUrl});
      } else {
        throw Exception('Upload failed with state: ${taskSnapshot.state}');
      }
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }

    return downloadUrl;
  }

// Separate function to clean up old images
  void _scheduleOldImageCleanup(String? oldImageUrl) {
    if (oldImageUrl == null || oldImageUrl.isEmpty) return;

    // Fire and forget - don't wait or handle errors here
    Future.delayed(Duration(seconds: 5), () {
      try {
        if (oldImageUrl.contains('firebasestorage')) {
          print('Attempting to clean up old image: $oldImageUrl');
          FirebaseStorage.instance
              .refFromURL(oldImageUrl)
              .delete()
              .then((_) => print('Old image deleted successfully'))
              .catchError((e) => print('Old image deletion failed: $e'));
        }
      } catch (e) {
        print('Cleanup error (non-critical): $e');
      }
    });
  }

  Future<String?> _convertImageToBase64() async {
    if (_profileImage == null) {
      print('No profile image selected, returning current URL');
      return _currentProfileImageUrl;
    }

    setState(() => _isUploadingImage = true);
    String? base64Image;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Read file as bytes
      final imageBytes = await _profileImage!.readAsBytes();

      // Convert bytes to base64
      base64Image =
          'data:image/${path.extension(_profileImage!.path).replaceAll('.', '')};base64,${base64Encode(imageBytes)}';

      print('Image converted to base64 (length: ${base64Image.length})');

      // Update the profileImageUrl field in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': base64Image});

      return base64Image;
    } catch (e) {
      print('Base64 conversion error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image conversion failed: $e')),
      );
      return null;
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveUserDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // ENHANCED LOGIC: Better handling of image URL
      String? profileImageUrl = _currentProfileImageUrl;

      // Only try to upload if there's a new image
      if (_profileImage != null) {
        try {
          final newImageData = await _convertImageToBase64();
          if (newImageData != null) {
            // Only update if we got a valid base64 string
            profileImageUrl = newImageData;
            print('Using new base64 image data');
          } else {
            print('Conversion failed, keeping current image URL/data');
            // Show warning but continue with profile update
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Could not update profile picture. Other details were saved.'),
                backgroundColor: Colors.orange,
              ));
            }
          }
        } catch (e) {
          print('Image handling error: $e');
          // Keep current URL and show warning
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Profile picture update failed. Your other details were saved.'),
              backgroundColor: Colors.orange,
            ));
          }
        }
      }

      // Parse age as integer
      int? age;
      try {
        if (_ageController.text.trim().isNotEmpty) {
          age = int.parse(_ageController.text.trim());
        }
      } catch (e) {
        age = null;
      }

      // Update user data in Firestore - SIMPLIFIED WITHOUT TRANSACTION
      // Update user document
      // await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      //   'preferredLanguage': _selectedLanguage,
      //   'gender': _selectedGender,
      //   'age': age,
      //   'state': _stateController.text.trim(), // Save state
      //   'nation': _nationController.text.trim(), // Save nation
      //   'profileImageUrl': profileImageUrl,
      //   'detailsCompleted': true,
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });

      // // Save to forms collection
      // final FirebaseHandler firebaseHandler = FirebaseHandler();
      // await firebaseHandler.getOrCreateFormDoc(
      //   user.uid,
      //   user.displayName ?? 'Unknown User',
      //   user.email ?? 'No email',
      //   language: _selectedLanguage,
      //   gender: _selectedGender,
      //   age: age,
      //   state: _stateController.text.trim(), // Pass state
      //   nation: _nationController.text.trim(), // Pass nation
      //   profileImageUrl: profileImageUrl,
      // );

// In the _saveUserDetails method, update the Firestore write:
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'preferredLanguage': _selectedLanguage,
        'gender': _selectedGender,
        'age': age,
        'state': _selectedState, // Save selected state value
        'nation': 'INDIA', // Always save as INDIA

        // 'nation': _nationController.text.trim(), // Keep saving nation as text
        'profileImageUrl': profileImageUrl,
        'detailsCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final FirebaseHandler firebaseHandler = FirebaseHandler();
// Also update the FirebaseHandler call:
      await firebaseHandler.getOrCreateFormDoc(
        user.uid,
        user.displayName ?? 'Unknown User',
        user.email ?? 'No email',
        language: _selectedLanguage,
        gender: _selectedGender,
        age: age,
        state: _selectedState, // Pass selected state value
        nation: 'INDIA', // Always pass INDIA

        // nation: _nationController.text.trim(), // Keep passing nation as text
        profileImageUrl: profileImageUrl,
      );

      // Show success message
      if (mounted) {
        Common.showMessage(
          context,
          'Profile updated successfully!',
          isError: false,
        );

        if (widget.isEditMode) {
          Navigator.pop(context); // Just go back if editing
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        Common.showMessage(
            context, 'Error saving user details: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Change this from Colors.grey.shade50 to white

      appBar: AppBar(
        title:
            Text(widget.isEditMode ? 'Edit Profile' : 'Complete Your Profile',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                )),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: widget.isEditMode,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF00BFA5)),
            onPressed: () {
              Common.showMessage(
                context,
                widget.isEditMode
                    ? 'Update your profile details to personalize your experience.'
                    : 'Complete your profile to enable FormBot to assist you better with accurate and personalized form-filling support.',
                isError: false,
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile picture with upload functionality
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _showImageSourceDialog,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.3),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    image: _profileImage != null
                                        ? DecorationImage(
                                            image: FileImage(_profileImage!),
                                            fit: BoxFit.cover,
                                          )
                                        : _currentProfileImageUrl != null
                                            ? DecorationImage(
                                                image: _currentProfileImageUrl!
                                                        .startsWith(
                                                            'data:image')
                                                    ? MemoryImage(base64Decode(
                                                        _currentProfileImageUrl!
                                                            .split(',')[1]))
                                                    : NetworkImage(
                                                            _currentProfileImageUrl!)
                                                        as ImageProvider,
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                  ),
                                  child: (_profileImage == null &&
                                          _currentProfileImageUrl == null)
                                      ? const Icon(
                                          Icons.person_outline,
                                          size: 60,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: GestureDetector(
                                  onTap: _showImageSourceDialog,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00BFA5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                        ),
                                      ],
                                    ),
                                    child: _isUploadingImage
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Center(
                        //   child: TextButton(
                        //     onPressed: _showImageSourceDialog,
                        //     child: const Text(
                        //       'Change Profile Picture (with cropping)',
                        //       style: TextStyle(
                        //         color: Color(0xFF00BFA5),
                        //         fontWeight: FontWeight.w500,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 24),

                        // _buildSectionTitle('Personal Information'),
                        // const SizedBox(height: 16),

                        // Language field
                        _buildFieldLabel('Preferred Language'),
                        const SizedBox(height: 8),
                        _buildDropdownField(
                          icon: Icons.language,
                          value: _selectedLanguage,
                          items: _languages,
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Gender field
                        _buildFieldLabel('Gender'),
                        const SizedBox(height: 8),
                        _buildDropdownField(
                          icon: Icons.person,
                          value: _selectedGender,
                          items: _genders,
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // Age field
                        _buildFieldLabel('Age'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _ageController,
                          icon: Icons.calendar_today,
                          hintText: 'Enter your age',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              try {
                                int age = int.parse(value);
                                if (age <= 0 || age > 120) {
                                  return 'Please enter a valid age (1-120)';
                                }
                              } catch (e) {
                                return 'Please enter a valid number';
                              }
                            }
                            return null; // Age is optional
                          },
                        ),
                        const SizedBox(height: 20),

                        // State field
                        // _buildFieldLabel('State of Residence'),
                        // const SizedBox(height: 8),
                        // _buildTextField(
                        //   controller: _stateController,
                        //   icon: Icons.location_city,
                        //   hintText: 'Enter your state',
                        //   keyboardType: TextInputType.text,
                        //   validator: null, // Optional field
                        // ),
                        // const SizedBox(height: 20),
                        _buildFieldLabel('State of Residence'),
                        const SizedBox(height: 8),
                        _buildDropdownField(
                          icon: Icons.location_city,
                          value: _selectedState.isEmpty
                              ? _indianStates[0]
                              : _indianStates.contains(_selectedState)
                                  ? _selectedState
                                  : _indianStates[0],
                          items: _indianStates,
                          onChanged: (value) {
                            setState(() {
                              _selectedState = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        // // Nation field
                        // _buildFieldLabel('Country'),
                        // const SizedBox(height: 8),
                        // _buildTextField(
                        //   controller: _nationController,
                        //   icon: Icons.public,
                        //   hintText: 'Enter your country',
                        //   keyboardType: TextInputType.text,
                        //   validator: null, // Optional field
                        // ),
                        // const SizedBox(height: 40),
                        // Nation field - replace the current TextField with non-editable display
                        _buildFieldLabel('Country'),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Icon(Icons.public, color: Colors.grey.shade600),
                              const SizedBox(width: 16),
                              const Text(
                                'INDIA',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Update Profile button
                        // Update Profile button
                        _buildActionButton(
                          text: widget.isEditMode
                              ? 'Save Changes'
                              : 'Update Profile',
                          isLoading: _isLoading,
                          onPressed: _saveUserDetails,
                        ),
                        const SizedBox(height: 16),

// Cancel button - only show when in edit mode
                        if (widget.isEditMode) _buildCancelButton(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00BFA5),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        dropdownColor: Colors.white,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
        ),
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BFA5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: const Text(
        'Cancel',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),
    );
  }
}
