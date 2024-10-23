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
    _showSlideToDeleteMessage();
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

  void _showSlideToDeleteMessage() {
    Future.delayed(Duration.zero, () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slide to delete an image'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const  Color(0xFF00A699),
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
                        return Dismissible(
                          key: Key(imagePath),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteImage(imagePath);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Image deleted'),
                              ),
                            );
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width*1.4,
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
                        );
                      },
                    )
                  : Center(child: Text('No captured images yet.')),
            ),
            SizedBox(height: 10), // Add some space before the message
            Text(
              'Swipe to delete an image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: 130, // Adjust the width here
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
              icon: Icon(Icons.upload_file,
                  color: Colors.white), // Add the upload icon here
              label: Text(
                'Upload',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const  Color(0xFF00A699),
            ),
          ),
        ),
      ),
    );
  }
}
