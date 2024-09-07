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

  @override
  void initState() {
    super.initState();
    _loadSubmittedForms();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Form Capture App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Capture New Form'),
              onPressed: () {
                Navigator.pushNamed(context, '/camera');
              },
            ),
            SizedBox(height: 20),
            Text(
              'Previously Captured Forms:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _submittedForms.length,
                itemBuilder: (context, index) {
                  final form = _submittedForms[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Form ${index + 1}'),
                      subtitle: Text(
                          'Image: ${form['imagePath']}\nAudio: ${form['audioPath']}'),
                      onTap: () {
                        // Handle tapping on a previously captured form
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
        child: Icon(Icons.add),
        tooltip: 'Capture New Form',
      ),
    );
  }
}
