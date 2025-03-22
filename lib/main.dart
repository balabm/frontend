import 'package:flutter/material.dart';
import 'package:formbot/providers/authprovider.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:formbot/screens/settings_screen.dart';
import 'package:formbot/screens/widgets/camerascreen.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:provider/provider.dart'; // Import this to use MultiProvider
import 'screens/user_input_screen.dart'; // Ensure this import is correct
import 'screens/home_screen.dart';
import 'screens/image_processing_screen.dart';
import 'screens/FieldEditScreen.dart';
import 'screens/form_selection_screen.dart'; // Import FormSelectionScreen
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

 
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ApiResponseProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseProvider()),
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
      debugShowCheckedModeBanner: false,
      title: 'Form Capture App',
      theme: ThemeData(
        
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textSelectionTheme: TextSelectionThemeData(
    cursorColor: Colors.teal, // Set cursor color to teal
    selectionColor: Colors.teal.withOpacity(0.3), // Highlight selection color
    selectionHandleColor: Colors.teal, // Selection handle (drag handles) color
  ),
        
      ),
      home: const AuthWrapper(), // Use AuthWrapper as the initial screen

      //initialRoute: '/userInput', // Set UserInputScreen as the initial route
      routes: {
        '/userInput': (context) => UserInputScreen(),
        '/home': (context) => const HomeScreen(),
        '/image_processing': (context) => const ImageProcessingScreen(),
        '/field_edit_screen': (context) => const FieldEditScreen(),
        '/camera': (context) => const CameraScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/form_selection': (context) => const FormSelectionScreen(), // Add this line
        
      },
    );
  }
}
// class AuthWrapper extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final authProvider = Provider.of<AuthProvider>(context);

//     return FutureBuilder(
//       future: authProvider.checkUserSignedIn(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           print('🔄 Checking authentication state...');
//           return Scaffold(
//             body: Center(
//               child: CircularProgressIndicator(),
//             ),
//           );
//         } else {
//           if (snapshot.hasData && snapshot.data == true) {
//             print('✅ User is authenticated. Navigating to HomeScreen.');
//             return const HomeScreen(); // Navigate to HomeScreen if authenticated
//           } else {
//             print('❌ User is not authenticated. Showing UserInputScreen.');
//             return UserInputScreen(); // Navigate to UserInputScreen if not authenticated
//           }
//         }
//       },
//     );
//   }
// }
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<bool> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    // Cache the Future in initState
    _authCheckFuture = Provider.of<AuthProvider>(context, listen: false).checkUserSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authCheckFuture, // Use the cached Future
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('🔄 Checking authentication state...');
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasData && snapshot.data == true) {
          print('✅ User is authenticated. Navigating to HomeScreen.');
          return const HomeScreen(); // Navigate to HomeScreen if authenticated
        } else {
          print('❌ User is not authenticated. Showing UserInputScreen.');
          return UserInputScreen(); // Navigate to UserInputScreen if not authenticated
        }
      },
    );
  }
}