import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:formbot/screens/widgets/common.dart';
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

  List<Map<String, String>> _submittedForms = [];
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
    final prefs = await SharedPreferences.getInstance();
    final forms = prefs.getStringList('submittedForms') ?? [];
    if (mounted) {
      setState(() => _submittedForms = forms
          .map((form) => Map<String, String>.from(jsonDecode(form)))
          .toList());
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

  Future<void> _deleteImage(String imagePath) async {
    try {
      setState(() => _isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final file = File(imagePath);
      if (await file.exists()) await file.delete();

      setState(() => _capturedImages.remove(imagePath));
      await prefs.setStringList('capturedImages', _capturedImages);
      Common.showMessage(context, 'Image deleted successfully');
    } catch (e) {
      Common.showMessage(context, 'Error deleting image: ${e.toString()}',
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
            _capturedImages = _capturedImages
                .where((image) => image
                    .split('/')
                    .last
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

  Widget _buildImageTile(String imagePath) {
    final fileName = imagePath.split('/').last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _boxDecoration,
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Hero(
            tag: imagePath,
            child: _buildImageThumbnail(imagePath),
          ),
          title: Text(
            fileName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteImage(imagePath),
          ),
          onTap: () => Navigator.pushNamed(
            context,
            '/image_processing',
            arguments: imagePath,
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String imagePath) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(imagePath), fit: BoxFit.cover),
        ),
      );

  Widget _buildImageList() => _capturedImages.isNotEmpty
      ? AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: ListView.builder(
            key: ValueKey(_capturedImages.length),
            itemCount: _capturedImages.length,
            itemBuilder: (_, index) => _buildImageTile(_capturedImages[index]),
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
              Hero(
                tag: 'profile_icon',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Text('Hi ${_userName.toUpperCase()}', style: _textStyle),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
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
                        Expanded(child: _buildImageList()),
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
