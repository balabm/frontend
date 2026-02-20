import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ec2_ip_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _boundingBoxUrlController;
  late TextEditingController _ocrTextUrlController;
  late TextEditingController _asrUrlController;
  late TextEditingController _llmUrlController;
  bool _isSaving = false;
  bool _isFetchingIp = false;
  String? _lastFetchedIp;
  DateTime? _lastFetchTime;

  @override
  void initState() {
    super.initState();
    _boundingBoxUrlController = TextEditingController();
    _ocrTextUrlController = TextEditingController();
    _asrUrlController = TextEditingController();
    _llmUrlController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _lastFetchedIp = await EC2IpService.getLastFetchedIp();
    _lastFetchTime = await EC2IpService.getLastFetchTime();

    setState(() {
      _boundingBoxUrlController.text = prefs.getString('bounding_box_url') ??
          'http://15.206.206.190:8001/cv/form-detection-with-box/';
      _ocrTextUrlController.text = prefs.getString('ocr_text_url') ??
          'http://15.206.206.190:8002/cv/ocr';
      _asrUrlController.text = prefs.getString('asr_url') ??
          'http://15.206.206.190:8003/upload-audio-zip/';
      _llmUrlController.text = prefs.getString('llm_url') ??
          'http://15.206.206.190:8004/get_llm_response_schemes';
      print("Loaded settings:");
      print("Bounding Box URL: ${_boundingBoxUrlController.text}");
      print("OCR Text URL: ${_ocrTextUrlController.text}");
      print("ASR URL: ${_asrUrlController.text}");
      print("LLM URL: ${_llmUrlController.text}");
    });
  }

  Future<void> _fetchEC2Ip() async {
    setState(() => _isFetchingIp = true);
    try {
      print('🔄 Starting EC2 IP fetch...');
      final urls = await EC2IpService.fetchAndUpdateUrls();

      if (urls != null && mounted) {
        // Update the text controllers with the new URLs
        setState(() {
          _boundingBoxUrlController.text = urls['bounding_box_url']!;
          _ocrTextUrlController.text = urls['ocr_text_url']!;
          _asrUrlController.text = urls['asr_url']!;
          _llmUrlController.text = urls['llm_url']!;
          _lastFetchedIp =
              urls['bounding_box_url']!.split(':')[1].replaceAll('//', '');
          _lastFetchTime = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ URLs updated! IP: $_lastFetchedIp'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        // Show detailed error dialog instead of just a snackbar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Connection Failed'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Failed to fetch EC2 IP from Lambda function.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Possible Causes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('No internet connection on device'),
                  _buildBulletPoint('VPN or firewall blocking AWS services'),
                  _buildBulletPoint('Lambda function URL is incorrect'),
                  _buildBulletPoint('EC2 instance is not running'),
                  _buildBulletPoint('Corporate network blocking AWS'),
                  const SizedBox(height: 16),
                  const Text(
                    'Try These Solutions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint('Check your internet connection'),
                  _buildBulletPoint('Try using mobile data instead of WiFi'),
                  _buildBulletPoint('Disable VPN if enabled'),
                  _buildBulletPoint('Manually enter the EC2 IP below'),
                  _buildBulletPoint('Check AWS Console for EC2 status'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.grey[200],
                    child: const Text(
                      'Note: If this persists, you can manually enter the URLs below.',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Exception in _fetchEC2Ip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingIp = false);
    }
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bounding_box_url', _boundingBoxUrlController.text);
      await prefs.setString('ocr_text_url', _ocrTextUrlController.text);
      await prefs.setString('asr_url', _asrUrlController.text);
      await prefs.setString('llm_url', _llmUrlController.text);
      await prefs.setString('urlupdated', 'true');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Color.fromRGBO(0, 150, 136, 1.0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card showing last fetched IP
                if (_lastFetchedIp != null)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ' Last Fetched EC2 IP: $_lastFetchedIp',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_lastFetchTime != null)
                            Text(
                              'Updated: ${_lastFetchTime!.toString().substring(0, 19)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                // Auto-fetch button
                ElevatedButton.icon(
                  onPressed: _isFetchingIp ? null : _fetchEC2Ip,
                  icon: _isFetchingIp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_download),
                  label: Text(_isFetchingIp
                      ? 'Fetching...'
                      : 'Auto-Fetch URLs from EC2'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 171, 179, 178),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 2),
                const SizedBox(height: 10),
                
                const Text(
                  'Manually Enter URLs:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _boundingBoxUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Bounding Box URL',
                    hintText: 'Enter the Bounding Box URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        final uri = Uri.parse(value);
                        if (!uri.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ocrTextUrlController,
                  decoration: const InputDecoration(
                    labelText: 'OCR Text URL',
                    hintText: 'Enter the OCR Text URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        final uri = Uri.parse(value);
                        if (!uri.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _asrUrlController,
                  decoration: const InputDecoration(
                    labelText: 'ASR URL',
                    hintText: 'Enter the ASR URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        final uri = Uri.parse(value);
                        if (!uri.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _llmUrlController,
                  decoration: const InputDecoration(
                    labelText: 'LLM URL',
                    hintText: 'Enter the LLM URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      try {
                        final uri = Uri.parse(value);
                        if (!uri.isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                      } catch (e) {
                        return 'Please enter a valid URL';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(0, 150, 136, 1.0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Settings',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _boundingBoxUrlController.dispose();
    _ocrTextUrlController.dispose();
    _asrUrlController.dispose();
    _llmUrlController.dispose();
    super.dispose();
  }
}
