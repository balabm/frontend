import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> _submittedForms = [];
  List<String> _capturedImages = [];
  TextEditingController _searchController = TextEditingController();
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSubmittedForms();
    _loadUserName();
    _loadCapturedImages();
  }

  Future<void> _loadSubmittedForms() async {
    final prefs = await SharedPreferences.getInstance();
    final forms = prefs.getStringList('submittedForms') ?? [];
    setState(() {
      _submittedForms = forms
          .map((form) => Map<String, String>.from(jsonDecode(form)))
          .toList();
    });
  }

  Future<void> _loadCapturedImages() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _capturedImages = prefs.getStringList('capturedImages') ?? [];
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
    });
  }

  Future<void> _deleteImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();

    // Delete the image from the file system
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Update the list of captured images
    setState(() {
      _capturedImages.remove(imagePath);
    });

    // Save the updated list in SharedPreferences
    prefs.setStringList('capturedImages', _capturedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF0b3c66),
        leading: IconButton(
          icon: Icon(Icons.home, color: Colors.white),
          onPressed: () {
            // Handle home button press
          },
        ),
        title: Text('Hi $_userName', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Previously Captured Forms:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search forms...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  setState(() {
                    _capturedImages = _capturedImages.where((image) {
                      final fileName = image.split('/').last.toLowerCase();
                      return fileName.contains(query.toLowerCase());
                    }).toList();
                  });
                },

              ),
            ),
            SizedBox(height: 20),

            Expanded(
              child: _capturedImages.isNotEmpty
                  ? ListView.builder(
                      itemCount: _capturedImages.length,
                      itemBuilder: (context, index) {
                        final imagePath = _capturedImages[index];
                        final fileName = imagePath.split('/').last; // Extract file name
                        return ListTile(
                          leading: Container(
                            width: 60, 
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(fileName), // Display the file name or title
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteImage(imagePath);
                            },
                          ),
                          onTap: () {
                            // Handle tapping on an image
                            Navigator.pushNamed(
                              context, '/image_processing',
                              arguments: imagePath,
                            );
                          },
                        );
                      },
                    )
                  : Center(child: Text('No captured images yet.')),
            ),

          ],
        ),
      ),
      floatingActionButton: Padding(
  padding: const EdgeInsets.only(bottom: 20.0),
  child: Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: 200, // Adjust the width here
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
        icon: Icon(Icons.upload_file, color: Colors.white), // Add the upload icon here
        label: Text(
          'Upload New Form', 
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF0b3c66),
      ),
    ),
  ),
),

    );
  }
}