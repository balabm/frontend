import 'dart:io';
import 'package:flutter/material.dart';
import 'FieldEditPopup.dart'; // Import the FieldEditPopup class

class FieldEditScreen extends StatefulWidget {
  @override
  _FieldEditScreenState createState() => _FieldEditScreenState();
}

class _FieldEditScreenState extends State<FieldEditScreen> {
  String? imagePath;
  Map<String, dynamic>? fieldData; // To store field coordinates and other data from CV model

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    imagePath = arguments['imagePath'] as String?;
    // You might want to fetch actual field data here if available
    _fetchFieldData();
  }

  Future<void> _fetchFieldData() async {
    // Mock call to CV model that returns field coordinates
    await Future.delayed(Duration(seconds: 2)); // Simulate delay
    // Mock field coordinates returned by the model
    setState(() {
  fieldData = {
    "Aadhaar Number": {"x": 100, "y": 150, "width": 200, "height": 50},
  
    //"Name": {"x": 100, "y": 250, "width": 200, "height": 50},
    //"Enrollment Type": {"x": 100, "y": 550, "width": 200, "height": 50},
    //"Verification Type": {"x": 100, "y": 850, "width": 200, "height": 50},
    //"Document Details": {"x": 100, "y": 950, "width": 200, "height": 50},
    //"Family Member Details": {"x": 100, "y": 1050, "width": 200, "height": 50},
    "CombinedField": {
      "x": 100, // Starting x-coordinate for the combined field
      "y": 1150, // Starting y-coordinate for the combined field
      "width": 400, // Width of the combined field (adjust as needed)
      "height": 50, // Height of the combined field (adjust as needed)
      "value1": "First Value",
      "value2": "Second Value"
    }
  };
});
  }

  Future<void> _editField(String fieldName) async {
    // Function to handle field editing and opening the popup
    String result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return FieldEditPopup(fieldName: fieldName);
      },
    );

    if (result.isNotEmpty) {
      print('Updated field $fieldName: $result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        backgroundColor: Color(0xFF0b3c66),
        iconTheme: IconThemeData(color: Colors.white),
        
      ),
      body: Stack(
        children: [
          // Display the captured form image
          if (imagePath != null)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.file(File(imagePath!)),
                ),
              ),
            ),
          // Overlay editable fields based on the coordinates from the CV model
          if (fieldData != null)
            ...fieldData!.entries.map((entry) {
              final field = entry.value;
              return Positioned(
                left: field["x"].toDouble(),
                top: field["y"].toDouble(),
                width: field["width"].toDouble(),
                height: field["height"].toDouble(),
                child: GestureDetector(
                  onTap: () => _editField(entry.key),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Center(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
