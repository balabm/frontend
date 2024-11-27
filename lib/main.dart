import 'package:flutter/material.dart';
import 'package:formbot/screens/widgets/camerascreen.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:provider/provider.dart'; // Import this to use MultiProvider
import 'screens/user_input_screen.dart'; // Ensure this import is correct
import 'screens/home_screen.dart';
import 'screens/image_processing_screen.dart';
import 'screens/FieldEditScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiResponseProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/userInput': (context) => const UserInputScreen(),
        '/home': (context) => const HomeScreen(),
        '/image_processing': (context) => const ImageProcessingScreen(),
        '/field_edit_screen': (context) => const FieldEditScreen(),
        '/camera': (context) => const CameraScreen(),
      },
    );
  }
}
