import 'package:flutter/material.dart';
import 'package:formbot/providers/authprovider.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:formbot/screens/settings_screen.dart';
import 'package:formbot/screens/widgets/camerascreen.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:formbot/services/ec2_ip_service.dart'; // Import EC2IpService
import 'package:provider/provider.dart'; // Import this to use MultiProvider
import 'screens/user_input_screen.dart'; // Ensure this import is correct
import 'screens/home_screen.dart';
import 'screens/image_processing_screen.dart';
import 'screens/FieldEditScreen.dart';
import 'screens/userDetailsScreen.dart'; // Import UserDetailsScreen

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF009688),
          surface: const Color(0xFFFAFAFA),
          background: const Color(0xFFF5F5F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF009688),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF009688), width: 2),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF009688),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        dividerTheme: DividerThemeData(
          thickness: 1,
          color: Colors.grey.shade200,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF009688),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFF009688),
          selectionColor: const Color(0xFF009688).withOpacity(0.3),
          selectionHandleColor: const Color(0xFF009688),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
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
        '/user_details': (context) => const UserDetailsScreen(), // Add this line
        //'/profile_edit': (context) => const UserDetailsScreen(),
        '/profile_edit': (context) => const UserDetailsScreen(isEditMode: true),



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
    
    // Auto-fetch EC2 IP URLs on app startup
    _autoFetchEC2Urls();
  }

  Future<void> _autoFetchEC2Urls() async {
    try {
      print('🚀 Auto-fetching EC2 IP URLs on app startup...');
      final urls = await EC2IpService.fetchAndUpdateUrls();
      
      if (urls != null) {
        print('✅ EC2 URLs auto-fetched successfully!');
        print('   Bounding Box: ${urls['bounding_box_url']}');
        print('   OCR: ${urls['ocr_text_url']}');
        print('   ASR: ${urls['asr_url']}');
        print('   LLM: ${urls['llm_url']}');
      } else {
        print('⚠️ Auto-fetch failed - using existing URLs from settings');
      }
    } catch (e) {
      print('⚠️ Auto-fetch error (will use existing URLs): $e');
      // Silently fail - app will use existing URLs from SharedPreferences
    }
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