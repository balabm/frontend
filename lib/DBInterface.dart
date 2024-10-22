import 'package:ass/screens/user_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:ass/helpers/database_helper.dart'; // Import the DatabaseHelper class
import 'package:ass/models/models.dart'; // Import your models

class UserInterface extends StatefulWidget {
  @override
  _UserInterfaceState createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _asrResponseController = TextEditingController();
  final TextEditingController _llmResponseController = TextEditingController();
  
  List<Map<String, dynamic>> _userInfoList = [];
  List<Map<String, dynamic>> _uploadedImagesList = [];
  List<Map<String, dynamic>> _asrResponsesList = [];
  List<Map<String, dynamic>> _llmResponsesList = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    var userInfo = await _databaseHelper.queryAllRows('user_info');
    var uploadedImages = await _databaseHelper.queryAllRows('uploaded_images');
    var asrResponses = await _databaseHelper.queryAllRows('asr_responses');
    var llmResponses = await _databaseHelper.queryAllRows('llm_responses');

    setState(() {
      _userInfoList = userInfo;
      _uploadedImagesList = uploadedImages;
      _asrResponsesList = asrResponses;
      _llmResponsesList = llmResponses;
    });
  }

  Future<void> _addUserInfo() async {
    if (_nameController.text.isNotEmpty) {
      await _databaseHelper.saveUserInfo(_nameController.text);
      _nameController.clear();
      _fetchData();
    }
  }

  Future<void> _addUploadedImage() async {
    if (_urlController.text.isNotEmpty) {
      await _databaseHelper.saveUploadedImage(_urlController.text);
      _urlController.clear();
      _fetchData();
    }
  }

  Future<void> _addAsrResponse() async {
    if (_asrResponseController.text.isNotEmpty) {
      await _databaseHelper.saveAsrResponse(_asrResponseController.text);
      _asrResponseController.clear();
      _fetchData();
    }
  }

  Future<void> _addLlmResponse() async {
    if (_llmResponseController.text.isNotEmpty) {
      await _databaseHelper.saveLlmResponse(_llmResponseController.text);
      _llmResponseController.clear();
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Interaction UI'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () { 
                                  Navigator.push( 
                                      context, 
                                      MaterialPageRoute( 
                                          builder: (context) => UserInputScreen())); 
                                }, 
                              
              child: Text("Home"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Enter Name'),
              ),
            ),
            ElevatedButton(
              onPressed: _addUserInfo,
              child: Text('Save User Info'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _urlController,
                decoration: InputDecoration(labelText: 'Enter Image URL'),
              ),
            ),
            ElevatedButton(
              onPressed: _addUploadedImage,
              child: Text('Upload Image'),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _asrResponseController,
                decoration: InputDecoration(labelText: 'Enter ASR Response'),
              ),
            ),
            ElevatedButton(
              onPressed: _addAsrResponse,
              child: Text('Save ASR Response'),
            ),
            Padding(
              padding: const EdgeInsets.all( 8.0),
              child: TextField(
                controller: _llmResponseController,
                decoration: InputDecoration(labelText: 'Enter LLM Response'),
              ),
            ),
            ElevatedButton(
              onPressed: _addLlmResponse,
              child: Text('Save LLM Response'),
            ),
            SizedBox(height: 20),
            Text('User  Info:'),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _userInfoList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_userInfoList[index]['name']),
                );
              },
            ),
            Text('Uploaded Images:'),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _uploadedImagesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_uploadedImagesList[index]['url']),
                );
              },
            ),
            Text('ASR Responses:'),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _asrResponsesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_asrResponsesList[index]['response']),
                );
              },
            ),
            Text('LLM Responses:'),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _llmResponsesList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_llmResponsesList[index]['response']),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}