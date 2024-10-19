import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import this to use MultiProvider
import 'screens/user_input_screen.dart'; // Ensure this import is correct
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/image_processing_screen.dart';
import 'screens/audio_recording_screen.dart';
import 'screens/review_submit_screen.dart';
import 'screens/extracted_fields.dart';
import 'screens/FieldEditScreen.dart';
import 'screens/api_response_provider.dart'; // Import the provider class

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiResponseProvider()),
      ],
      child: MyApp(),
    ),
  );
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
      initialRoute: '/userInput', // Set UserInputScreen as the initial route
      routes: {
        '/userInput': (context) => UserInputScreen(),
        '/home': (context) => HomeScreen(),
        '/camera': (context) => CameraScreen(),
        '/image_processing': (context) => ImageProcessingScreen(),
        '/field_edit_screen': (context) => FieldEditScreen(),
        '/extracted_fields': (context) => ExtractedFieldsScreen(),
        '/audio_recording': (context) => AudioRecordingScreen(),
        '/review_submit': (context) => ReviewSubmitScreen(),
      },
    );
  }
}
