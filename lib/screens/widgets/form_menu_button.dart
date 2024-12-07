// Assuming this is in a separate file like lib/widgets/form_menu_button.dart

import 'package:flutter/material.dart';

class FormMenuButton extends StatelessWidget {
  final Function onUpload;
  final Function onCapture;

  const FormMenuButton({
    Key? key,
    required this.onUpload,
    required this.onCapture,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: BorderSide.none,
          ),
          color: Colors.grey[200],
          elevation: 8.0,
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'upload':
              onUpload();
              break;
            case 'capture':
              onCapture();
              break;
            default:
              print("Unknown action");
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'upload',
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              dense: true,
              leading: Icon(Icons.cloud_upload, color: Colors.teal, size: 20),
              title: Text('Upload New Form', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'capture',
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              dense: true,
              leading: Icon(Icons.camera_alt, color: Colors.teal, size: 20),
              title: Text('Capture New Photo', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
        icon: Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }
}