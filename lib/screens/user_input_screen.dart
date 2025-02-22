// import 'package:flutter/material.dart';
// import 'package:formbot/providers/authprovider.dart';
// import 'package:formbot/screens/widgets/googlesigninbutton.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class UserInputScreen extends StatefulWidget {
//   @override
//   _UserInputScreenState createState() => _UserInputScreenState();
// }

// class _UserInputScreenState extends State<UserInputScreen> with SingleTickerProviderStateMixin {
//   bool _isLoading = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   late AuthProvider _authProvider;

//   Future<void> setPrefs() async {
//     final _prefs = await SharedPreferences.getInstance();
//      _prefs.setString('bounding_box_url', 'http://192.168.62.227:8000/cv/form-detection-with-box/');
//     _prefs.setString('ocr_text_url', 'http://192.168.62.227:8080/cv/ocr');
//     _prefs.setString('asr_url', 'http://192.168.62.227:8001/upload-audio-zip/');
//     _prefs.setString('llm_url', 'http://192.168.62.227:8021/get_llm_response'); //update the URL
   
//     }
  
//   @override
//   void initState() {
//     super.initState();
//     setPrefs();
//     _authProvider = Provider.of<AuthProvider>(context, listen: false);
//     _animationController = AnimationController(
//       vsync: this,
//       duration: Duration(milliseconds: 1000),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: Offset(0, 0.5),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color.fromRGBO(0, 150, 136, 1.0)
//.shade700, Color.fromRGBO(0, 150, 136, 1.0)
//.shade900],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     FadeTransition(
//                       opacity: _fadeAnimation,
//                       child: SlideTransition(
//                         position: _slideAnimation,
//                         child: Column(
//                           children: [
//                             Icon(
//                               Icons.document_scanner_rounded,
//                               size: 80,
//                               color: Colors.white,
//                             ),
//                             SizedBox(height: 24),
//                             Text(
//                               'Welcome to FormBot',
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               'Your AI-powered form processing assistant',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.white.withOpacity(0.9),
//                               ),
//                             ),
//                             SizedBox(height: 48),
//                             _buildGoogleSignInButton(),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

// Widget _buildGoogleSignInButton() {
//   return GoogleSignInButton(
//     isLoading: _isLoading,
//     onPressed: () async {
//       setState(() => _isLoading = true);
//       try {
//         await _authProvider.googleSignIn(context);
//       } finally {
//         if (mounted) setState(() => _isLoading = false);
//       }
//     },
//   );
// }
// }
import 'package:flutter/material.dart';
import 'package:formbot/providers/authprovider.dart';
import 'package:formbot/screens/widgets/googlesigninbutton.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInputScreen extends StatefulWidget {
  @override
  _UserInputScreenState createState() => _UserInputScreenState();
}

class _UserInputScreenState extends State<UserInputScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AuthProvider _authProvider;

  Future<void> setPrefs() async {
    final _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey('bounding_box_url')) {
      _prefs.setString('bounding_box_url', 'http://10.64.26.89:8002/cv/form-detection-with-box/');
    }
    if (!_prefs.containsKey('ocr_text_url')) {
      _prefs.setString('ocr_text_url', 'http://10.64.26.89:8001/cv/ocr');
    }
    if (!_prefs.containsKey('asr_url')) {
      _prefs.setString('asr_url', 'http://10.64.26.83:8002/upload-audio-zip/');
    }
    if (!_prefs.containsKey('llm_url')) {
      _prefs.setString('llm_url', 'http://10.64.26.89:8036/get_llm_response_schemes');
    }
  }

  @override
  void initState() {
    super.initState();
    setPrefs();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
        Color.fromRGBO(0, 150, 136, 1.0), // First color
        Color.fromRGBO(0, 120, 110, 1.0), // Second color (added)
      ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            Icon(
                              Icons.document_scanner_rounded,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Welcome to FormBot',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Your AI-powered form processing assistant',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            SizedBox(height: 48),
                            _buildGoogleSignInButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return GoogleSignInButton(
      isLoading: _isLoading,
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await _authProvider.googleSignIn(context);
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }
}