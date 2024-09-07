import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/image_processing_screen.dart';
import 'screens/audio_recording_screen.dart';
import 'screens/review_submit_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Capture App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/camera': (context) => CameraScreen(),
        '/image_processing': (context) => ImageProcessingScreen(),
        '/audio_recording': (context) => AudioRecordingScreen(),
        '/review_submit': (context) => ReviewSubmitScreen(),
      },
    );
  }
}
