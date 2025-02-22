import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    setState(() {
      _boundingBoxUrlController.text = prefs.getString('bounding_box_url') ?? 'http://10.64.240.162:8002/cv/form-detection-with-box/';
      _ocrTextUrlController.text = prefs.getString('ocr_text_url') ?? 'http://192.168.62.227:8080/cv/ocr';
      _asrUrlController.text = prefs.getString('asr_url') ?? 'http://192.168.62.227:8001/upload-audio-zip/';
      _llmUrlController.text = prefs.getString('llm_url') ?? 'http://192.168.62.227:8021/get_llm_response';
       print("Loaded settings:");
      print("Bounding Box URL: ${_boundingBoxUrlController.text}");
      print("OCR Text URL: ${_ocrTextUrlController.text}");
      print("ASR URL: ${_asrUrlController.text}");
      print("LLM URL: ${_llmUrlController.text}");
    });
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
      await prefs.setString('urlupdated','true');
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
        backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
,
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
                    backgroundColor: Color.fromRGBO(0, 150, 136, 1.0)
,
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
