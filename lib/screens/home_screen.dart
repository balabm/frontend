import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:formbot/helpers/firebase_handler.dart';
import 'package:formbot/providers/firebaseprovider.dart';
import 'package:formbot/providers/authprovider.dart';
import 'package:formbot/screens/widgets/common.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const Color _kTeal = Color(0xFF009688);
const Color _kTealLight = Color(0xFFB2DFDB);
const Color _kTealDark = Color(0xFF00695C);

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
  List<Map<String, dynamic>> _filteredForms = [];
  List<String> _capturedImages = [];
  String _userName = '';
  String _profileImageBase64 = '';
  String _userEmail = '';
  bool _isLoading = true;
  DateTime? _lastActivity;
  bool _isMultiSelectMode = false;
  Set<String> _selectedFormIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadData();
    _checkUserActivity();
  }

  Future<void> _checkUserActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityString = prefs.getString('lastActivity');

    if (lastActivityString != null) {
      _lastActivity = DateTime.parse(lastActivityString);
      final now = DateTime.now();
      final difference = now.difference(_lastActivity!);

      if (difference.inSeconds > 259200) {
        if (mounted) {
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.signOut();
          Navigator.of(context).pushReplacementNamed('/userInput');
          Common.showMessage(
              context, 'You have been logged out due to inactivity');
        }
      }
    }
    _updateLastActivity();
  }

  Future<void> _updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('lastActivity', now.toIso8601String());
    _lastActivity = now;
  }

  Future<void> _loadData() async {
    try {
      _updateLastActivity();
      await Future.wait([
        _loadSubmittedForms(),
        _loadUserInfo(),
        _loadCapturedImages(),
      ]);
      _animationController.forward();
    } catch (e) {
      Common.showMessage(context, 'Error loading data: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubmittedForms() async {
    try {
      final firebaseProvider =
          Provider.of<FirebaseProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;
      if (userId == null) throw Exception('No authenticated user found');

      final forms = await firebaseProvider.getSubmittedForms(userId: userId);
      if (mounted) {
        setState(() {
          _submittedForms =
              forms.where((form) => form['userId'] == userId).toList();
          _filteredForms = List.from(_submittedForms);
        });
      }
    } catch (e) {
      if (mounted) {
        Common.showMessage(
            context, 'Error loading forms: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Map<String, dynamic>? userDetails = await authProvider.getUserDetails();

    if (mounted) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'User';
        _userEmail = authProvider.user?.email ?? 'No email';
        String? imageData = userDetails?['profileImageUrl'];
        if (imageData != null && imageData.contains(',')) {
          _profileImageBase64 = imageData.split(',').last;
        } else {
          _profileImageBase64 = imageData ?? '';
        }
      });
    }
  }

  Future<void> _logout() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
      if (mounted) Navigator.of(context).pushReplacementNamed('/userInput');
    } catch (e) {
      Common.showMessage(context, 'Error logging out: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCapturedImages() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _capturedImages = prefs.getStringList('capturedImages') ?? []);
    }
  }

  Future<void> _deleteForm(String formId) async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;
      if (uid == null) throw Exception('User not logged in');
      final firebaseHandler = FirebaseHandler();
      await firebaseHandler.deleteForm(uid, formId);
      setState(() {
        _submittedForms.removeWhere((form) => form['formId'] == formId);
        _filteredForms.removeWhere((form) => form['formId'] == formId);
      });
      Common.showMessage(context, 'Form deleted successfully');
    } catch (e) {
      Common.showMessage(context, 'Error deleting form: ${e.toString()}',
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _filterForms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredForms = List.from(_submittedForms);
      } else {
        final q = query.toLowerCase();
        _filteredForms = _submittedForms
            .where((form) =>
                (form['formName'] ?? '').toLowerCase().contains(q))
            .toList();
      }
    });
  }

  // ─── UI Builders ──────────────────────────────────────────────

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        height: 46,
        color: Colors.white,
        child: TextField(
          controller: _searchController,
          onChanged: _filterForms,
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
            ),
            contentPadding:
                const EdgeInsets.only(left: 20, right: 10, top: 10, bottom: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _kTealLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 56,
                color: _kTeal.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No forms yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the camera button below to scan\nyour first form',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTile(Map<String, dynamic> form, int index) {
    final formName = form['formName'] ?? 'Unnamed Form';
    final formId = form['formId'];
    final imageBase64 = form['imageBase64'] ?? '';
    final isSelected = _selectedFormIds.contains(formId);
    final timestamp = form['timestamp'];

    String dateText = '';
    if (timestamp != null) {
      try {
        final dt = timestamp is DateTime
            ? timestamp
            : timestamp is String
                ? DateTime.parse(timestamp)
                : DateTime.now();
        dateText = DateFormat('MMM d, yyyy').format(dt);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onLongPress: () {
          setState(() {
            _isMultiSelectMode = true;
            _selectedFormIds.add(formId);
          });
        },
        onTap: () {
          if (_isMultiSelectMode) {
            setState(() {
              if (isSelected) {
                _selectedFormIds.remove(formId);
              } else {
                _selectedFormIds.add(formId);
              }
            });
          } else {
            if (imageBase64.isEmpty) return;
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/$formId');
            tempFile.writeAsBytesSync(base64Decode(imageBase64));
            Navigator.pushNamed(
              context,
              '/field_edit_screen',
              arguments: {
                'imagePath': tempFile.path,
                'formId': formId,
              },
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? _kTeal.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _kTeal : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageBase64.isNotEmpty
                      ? Image.memory(
                          base64Decode(imageBase64),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade200,
                          child: Icon(Icons.image, color: Colors.grey.shade400),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dateText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (_isMultiSelectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedFormIds.add(formId);
                        } else {
                          _selectedFormIds.remove(formId);
                        }
                      });
                    },
                    activeColor: _kTeal,
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirm(formId, formName);
                      } else if (value == 'rename') {
                        _renameForm(formId, formName);
                      }
                    },
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, color: _kTeal, size: 20),
                            const SizedBox(width: 12),
                            const Text('Rename'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            const Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(String formId, String formName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Form?'),
        content: Text(
            'Are you sure you want to delete "$formName"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteForm(formId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormList() {
    if (_filteredForms.isEmpty) return _buildEmptyState();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Scrollbar(
        thumbVisibility: false,
        child: ListView.builder(
          key: ValueKey(_filteredForms.length),
          padding: const EdgeInsets.only(top: 4, bottom: 80),
          itemCount: _filteredForms.length,
          itemBuilder: (_, index) =>
              _buildFormTile(_filteredForms[index], index),
        ),
      ),
    );
  }

  Future<void> _renameForm(String formId, String currentName) async {
    final nameController = TextEditingController(text: currentName);
    bool isNameValid = currentName.isNotEmpty;
    bool isProcessing = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Rename Form',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  enabled: !isProcessing,
                  autofocus: true,
                  cursorColor: _kTeal,
                  decoration: InputDecoration(
                    hintText: 'Enter new form name',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: _kTeal, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => isNameValid = value.trim().isNotEmpty);
                  },
                ),
                if (isProcessing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(_kTeal)),
                        ),
                        const SizedBox(width: 12),
                        Text('Renaming...',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (isNameValid && !isProcessing)
                    ? () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) return;
                        setState(() => isProcessing = true);
                        try {
                          await _updateFormName(formId, newName);
                          if (context.mounted) Navigator.pop(context);
                          Common.showMessage(context, 'Form renamed');
                        } catch (e) {
                          setState(() => isProcessing = false);
                          Common.showMessage(context, 'Error: ${e.toString()}',
                              isError: true);
                        }
                      }
                    : null,
                child: const Text('Rename'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateFormName(String formId, String newName) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uid = authProvider.user?.uid;
    if (uid == null) throw Exception('User not logged in');
    final firebaseProvider =
        Provider.of<FirebaseProvider>(context, listen: false);
    await firebaseProvider.updateFormName(uid, formId, newName);
    setState(() {
      final index =
          _submittedForms.indexWhere((f) => f['formId'] == formId);
      if (index != -1) {
        _submittedForms[index]['formName'] = newName;
      }
      final filteredIndex =
          _filteredForms.indexWhere((f) => f['formId'] == formId);
      if (filteredIndex != -1) {
        _filteredForms[filteredIndex]['formName'] = newName;
      }
    });
  }

  Future<void> _deleteSelectedForms() async {
    try {
      setState(() => _isLoading = true);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.user?.uid;
      if (uid == null) throw Exception('User not logged in');
      final firebaseHandler = FirebaseHandler();
      for (final formId in _selectedFormIds) {
        await firebaseHandler.deleteForm(uid, formId);
      }
      setState(() {
        _submittedForms
            .removeWhere((f) => _selectedFormIds.contains(f['formId']));
        _filteredForms
            .removeWhere((f) => _selectedFormIds.contains(f['formId']));
        _selectedFormIds.clear();
        _isMultiSelectMode = false;
      });
      Common.showMessage(context, 'Selected forms deleted');
    } catch (e) {
      Common.showMessage(context, 'Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Drawer ───────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile_edit');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_kTeal, _kTealDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _profileImageBase64.isNotEmpty
                            ? CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                backgroundImage: MemoryImage(
                                    base64Decode(_profileImageBase64)),
                              )
                            : CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _userName.isNotEmpty
                                      ? _userName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _kTeal),
                                ),
                              ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child:
                                const Icon(Icons.edit, size: 14, color: _kTeal),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                    if (_lastActivity != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last active: ${DateFormat('MMM d, yyyy').format(_lastActivity!)}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildDrawerItem(
                    Icons.home_outlined, 'Home', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.settings_outlined, 'Settings', () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                }),
                Divider(
                    thickness: 1,
                    height: 1,
                    color: Colors.grey.shade200),
                _buildDrawerItem(Icons.logout_rounded, 'Logout', () async {
                  Navigator.pop(context);
                  await _logout();
                }, isLogout: true),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'You will be automatically logged out after 3 days of inactivity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    final color = isLogout ? Colors.red : _kTeal;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isLogout ? Colors.red : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    SystemNavigator.pop();
    return false;
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: _kTeal,
          elevation: 0,
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleSpacing: 0,
          title: Text(
            _isMultiSelectMode
                ? '${_selectedFormIds.length} Selected'
                : 'Hi ${_userName.toUpperCase()}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600),
          ),
          actions: [
            if (_isMultiSelectMode) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _selectedFormIds.isNotEmpty
                    ? _deleteSelectedForms
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedFormIds.clear();
                  });
                },
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadData,
              ),
            ],
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kTeal))
              : ScaleTransition(
                  scale: _scaleAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kTeal,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          Expanded(child: _buildFormList()),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FloatingActionButton.extended(
            onPressed: () {
              _updateLastActivity();
              Navigator.pushNamed(context, '/form_selection');
            },
            icon: const Icon(Icons.add_a_photo, color: Colors.white),
            label: const Text(
              'New Form',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            backgroundColor: _kTeal,
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
