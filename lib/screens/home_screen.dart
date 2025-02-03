import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:formbot/helpers/firebase_handler.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:formbot/providers/authprovider.dart'; // Import AuthProvider
import 'package:formbot/screens/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  List<Map<String, dynamic>> _submittedForms = [];
  List<String> _capturedImages = [];
  String _userName = '';
  bool _isLoading = true;

  final _boxDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  final _textStyle = const TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _loadData() async {
    try {
      await Future.wait([
        _loadSubmittedForms(),
        _loadUserName(),
        _loadCapturedImages(),
        _loadApiUrls(), // Add this line
      ]);
      _animationController.forward();
    } catch (e) {
      Common.showMessage(context, 'Error loading data: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSubmittedForms() async {
    final firebaseProvider = Provider.of<FirebaseProvider>(context, listen: false);
    final forms = await firebaseProvider.getSubmittedForms();
    if (mounted) {
      setState(() => _submittedForms = forms);
    }
  }

  Future<void> _loadCapturedImages() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(
          () => _capturedImages = prefs.getStringList('capturedImages') ?? []);
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _userName = prefs.getString('userName') ?? 'User');
  }

  Future<void> _loadApiUrls() async {
    final prefs = await SharedPreferences.getInstance();
    final boundingBoxUrl = prefs.getString('S') ?? 'http://150.230.166.29/abc_test//cv/form-detection-with-box/';
    final ocrTextUrl = prefs.getString('ocr_text_url') ?? 'http://150.230.166.29/abc_test/ocr/cv/ocr';
    final asrUrl = prefs.getString('asr_url') ?? 'http://150.230.166.29/abc_test/asr/upload-audio-zip/';
    final llmUrl = prefs.getString('llm_url') ?? 'http://150.230.166.29/abc_test/llm/get_llm_response';
    // Use the URLs as needed
  }

  Future<void> _deleteForm(String formId) async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }
      final firebaseHandler = FirebaseHandler(); // Create an instance of FirebaseHandler
      await firebaseHandler.deleteForm(uid, formId); // Delete form from Firebase
      setState(() => _submittedForms.removeWhere((form) => form['formId'] == formId));
      Common.showMessage(context, 'Form deleted successfully');
    } catch (e) {
      Common.showMessage(context, 'Error deleting form: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() => Container(
        decoration: _boxDecoration,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search forms...',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (query) => setState(() {
            final lowercaseQuery = query.toLowerCase();
            _submittedForms = _submittedForms
                .where((form) => form['formName']
                    .toLowerCase()
                    .contains(lowercaseQuery))
                .toList();
          }),
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No captured images yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Tap the button below to start capturing',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildFormTile(Map<String, dynamic> form) {
    final formName = form['formName'] ?? 'Unnamed Form';
    final formId = form['formId'];
    final imageBase64 = form['imageBase64'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _boxDecoration,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              base64Decode(imageBase64),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            formName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteForm(formId);
              }
            },
            icon: Icon(Icons.more_vert, color: Colors.teal),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.black)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                  horizontalTitleGap: 16.0, 
                ),
              ),
            ],
            color: Colors.white,
          ),
          onTap: () {
            // Save base64 image to temporary file and get path
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/$formId.png');
            tempFile.writeAsBytesSync(base64Decode(imageBase64));
            
            Navigator.pushNamed(
              context,
              '/field_edit_screen',
              arguments: {
                'imagePath': tempFile.path,
                'formId': formId,
                // Additional arguments will be loaded from Firebase
              },
            );
          },
        ),
      ),
    );
  }

  // Widget _buildFormList() => _submittedForms.isNotEmpty
  //     ? AnimatedSwitcher(
  //         duration: const Duration(milliseconds: 300),
  //         child: ListView.builder(
  //           key: ValueKey(_submittedForms.length),
  //           itemCount: _submittedForms.length,
  //           itemBuilder: (_, index) => _buildFormTile(_submittedForms[index]),
  //         ),
  //       )
  //     : _buildEmptyState();

  Widget _buildFormList() => _submittedForms.isNotEmpty
    ? AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Scrollbar(
          thumbVisibility: true, // Ensures the scrollbar is always visible when scrolling
          child: ListView.builder(
            key: ValueKey(_submittedForms.length),
            itemCount: _submittedForms.length,
            itemBuilder: (_, index) => _buildFormTile(_submittedForms[index]),
          ),
        ),
      )
    : _buildEmptyState();


  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.teal,
          title: Row(
            children: [
              // Hero(
              //   tag: 'profile_icon',
              //   child: Container(
              //     padding: const EdgeInsets.all(8),
              //     decoration: BoxDecoration(
              //       color: Colors.white.withOpacity(0.2),
              //       shape: BoxShape.circle,
              //     ),
              //     child:
              //         const Icon(Icons.person, color: Colors.white, size: 24),
              //   ),
              // ),
              const SizedBox(width: 12),
              Text('Hi ${_userName.toUpperCase()}', style: _textStyle),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(11, 60, 102, 1)),
                ),
              )
            : ScaleTransition(
                scale: _scaleAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: Colors.teal,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 20),
                        Expanded(child: _buildFormList()),
                      ],
                    ),
                  ),
                ),
              ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, '/camera'),
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text('New Capture',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: Colors.teal,
          ),
        ),
      );
}