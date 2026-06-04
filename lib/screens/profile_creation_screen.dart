import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_strings.dart';
import '../core/providers/language_provider.dart';
import '../core/database/database_helper.dart';
import '../models/user_profile.dart';
import 'home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final storage = const FlutterSecureStorage();

  // Controllers
  final fullNameController = TextEditingController();
  final cinController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  int currentStep = 0;
  bool _showVoiceInstructions = false;

  // Voice
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _spokenText = '';

  // Gemini AI
  late GenerativeModel _geminiModel;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initGemini();
    _initDatabaseKey();
    _initTTS();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('ar');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _initGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _geminiModel =
        GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: apiKey);
  }

  Future<void> _initDatabaseKey() async {
    String? key = await storage.read(key: 'db_encryption_key');
    if (key == null) {
      key = _generateSecureKey();
      await storage.write(key: 'db_encryption_key', value: key);
    }
  }

  String _generateSecureKey() => '32characterstrongrandomkey12345678';

  // ==================== Voice Instructions ====================
  void _showVoiceInstructionsDialog(LanguageProvider lang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(lang.t('voice_instructions')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionStep(
                number: 1,
                title: lang.t('step_listen'),
                description: lang.t('listen_prompt_instruction'),
                icon: Icons.hearing,
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                number: 2,
                title: lang.t('step_speak'),
                description: lang.t('speak_clearly_instruction'),
                icon: Icons.mic,
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                number: 3,
                title: lang.t('step_confirm'),
                description: lang.t('confirm_data_instruction'),
                icon: Icons.check_circle,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.t('voice_tips'),
                        style: TextStyle(
                            fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('close')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startVoiceInput();
            },
            child: Text(lang.t('start_voice')),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2A6E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Icon(icon, color: const Color(0xFF0A2A6E), size: 24),
      ],
    );
  }

  // ==================== Voice AI ====================
  Future<void> _speakInstruction(String message) async {
    setState(() => _isSpeaking = true);
    try {
      await _tts.speak(message);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      setState(() => _isSpeaking = false);
    }
  }

  String _getVoicePrompt(LanguageProvider lang) {
    switch (currentStep) {
      case 0:
        return lang.t('voice_prompt_step1') ??
            'Please say your full name and national ID number';
      case 1:
        return lang.t('voice_prompt_step2') ??
            'Please say your date of birth and phone number';
      case 2:
        return lang.t('voice_prompt_step3') ?? 'Please say your home address';
      default:
        return 'Please provide the required information';
    }
  }

  Future<void> _startVoiceInput() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Speak the instruction first
    await _speakInstruction(_getVoicePrompt(lang));

    bool available = await _speech.initialize(
      onStatus: (val) {
        debugPrint('Speech status: $val');
        if (val == 'done' || val == 'notListening') {
          if (_spokenText.trim().isNotEmpty) {
            _stopListeningAndProcess();
          }
        }
      },
      onError: (val) {
        debugPrint('Speech error: $val');
        _showError(lang.t('voice_error') ?? 'Voice input error: $val');
        setState(() => _isListening = false);
      },
    );

    if (!available) {
      _showError(
        lang.t('speech_not_available') ?? 'Speech recognition not available',
      );
      return;
    }

    setState(() => _isListening = true);

    // Use the new SpeechListenOptions instead of deprecated partialResults
    await _speech.listen(
      onResult: (result) {
        setState(() => _spokenText = result.recognizedWords);
      },
      localeId: 'fr', // or 'fr', 'ar-TN'
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 2),
      // All options are now inside SpeechListenOptions
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _stopListeningAndProcess() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    if (_spokenText.trim().isEmpty) {
      _showError('No speech detected. Please try again.');
      return;
    }

    setState(() => _isProcessing = true);
    await _processWithGemini(_spokenText);
    setState(() => _isProcessing = false);
  }

  Future<void> _processWithGemini(String transcript) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final prompt = '''
Extract the personal information from the following spoken text (Tunisian Arabic, French, or mixed) for step ${currentStep + 1}.
Return **only** a valid JSON object with these keys:

{
  "full_name": "string",
  "cin": "8 digits string",
  "date_of_birth": "DD/MM/YYYY",
  "phone_number": "+216 XX XXX XXX",
  "home_address": "string"
}

Spoken text: "$transcript"
''';

    try {
      final response =
          await _geminiModel.generateContent([Content.text(prompt)]);
      String jsonStr = response.text ?? '';
      jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();

      final Map<String, dynamic>? extracted = jsonDecode(jsonStr);
      if (extracted != null && extracted.isNotEmpty) {
        _fillFormFromVoice(extracted);
        await _speakInstruction(lang.t('data_extracted') ??
            'Data has been extracted successfully. Please review and confirm.');
        _showVoiceConfirmationDialog(extracted, lang);
      }
    } catch (e) {
      _showError('${lang.t('gemini_error') ?? 'AI processing error'}: $e');
      await _speakInstruction(
          lang.t('error_try_again') ?? 'There was an error. Please try again.');
    }
  }

  void _fillFormFromVoice(Map<String, dynamic> data) {
    setState(() {
      if (currentStep == 0) {
        fullNameController.text = data['full_name']?.toString() ?? '';
        cinController.text = data['cin']?.toString() ?? '';
      } else if (currentStep == 1) {
        birthDateController.text = data['date_of_birth']?.toString() ?? '';
        phoneController.text = data['phone_number']?.toString() ?? '';
      } else if (currentStep == 2) {
        addressController.text = data['home_address']?.toString() ?? '';
      }
    });
  }

  void _showVoiceConfirmationDialog(
      Map<String, dynamic> data, LanguageProvider lang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(lang.t('confirm_information')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationField(
                lang.t('full_name'),
                data['full_name']?.toString() ?? 'N/A',
              ),
              _buildConfirmationField(
                lang.t('cin_number'),
                data['cin']?.toString() ?? 'N/A',
              ),
              _buildConfirmationField(
                lang.t('date_of_birth'),
                data['date_of_birth']?.toString() ?? 'N/A',
              ),
              _buildConfirmationField(
                lang.t('phone_number'),
                data['phone_number']?.toString() ?? 'N/A',
              ),
              _buildConfirmationField(
                lang.t('home_address'),
                data['home_address']?.toString() ?? 'N/A',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _spokenText = '');
            },
            child: Text(lang.t('redo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              nextStep();
            },
            child: Text(lang.t('confirm')),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  // ==================== Step Navigation ====================
  void nextStep() {
    if (_formKey.currentState!.validate()) {
      if (currentStep < 2) {
        setState(() => currentStep += 1);
      } else {
        _saveProfile();
      }
    }
  }

  void previousStep() {
    if (currentStep > 0) setState(() => currentStep -= 1);
  }

  Widget stepContent(LanguageProvider lang) {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            _buildTextField(lang.t('full_name'), fullNameController),
            const SizedBox(height: 20),
            _buildTextField(lang.t('cin_number'), cinController),
          ],
        );
      case 1:
        return Column(
          children: [
            _buildTextField(lang.t('date_of_birth'), birthDateController),
            const SizedBox(height: 20),
            _buildTextField(lang.t('phone_number'), phoneController),
          ],
        );
      case 2:
        return Column(
          children: [
            _buildTextField(lang.t('home_address'), addressController,
                maxLines: 2),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Future<void> _saveProfile() async {
    // 1. Save to the Python backend first
    int? registeredId;
    String? jwtToken;

    try {
      final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';
      final uri = Uri.parse("$backendUrl/register_user/");
      
      // Formatting date from DD/MM/YYYY to YYYY-MM-DD for Python Pydantic
      String formattedDob = birthDateController.text;
      if (formattedDob.contains('/')) {
        final parts = formattedDob.split('/');
        if (parts.length == 3) {
          formattedDob = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullNameController.text,
          "cin": cinController.text,
          "dob": formattedDob.isNotEmpty ? formattedDob : "2000-01-01", 
          "phone": phoneController.text,
          "address": addressController.text,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        _showError("Erreur serveur backend: ${response.body}");
        return;
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      registeredId = responseData['id'] as int?;
      jwtToken = responseData['token'] as String?;
    } catch (e) {
      _showError("Erreur réseau backend: $e");
      return;
    }

    // 2. Save securely to Local DB (consolidated maak.db via DatabaseHelper)
    try {
      // Save credentials to secure storage
      if (jwtToken != null) {
        await storage.write(key: 'jwt_auth_token', value: jwtToken);
      }
      if (registeredId != null) {
        await storage.write(key: 'registered_user_id', value: registeredId.toString());
      }

      final userProfile = UserProfile(
        id: registeredId,
        fullName: fullNameController.text,
        cin: cinController.text,
        address: addressController.text,
        dob: birthDateController.text,
        phone: phoneController.text,
      );

      await DatabaseHelper.instance.saveProfile(userProfile);
    } catch (e) {
      _showError("Erreur de base de données locale: $e");
      return;
    }

    // 3. Mark hasAccount = true in SharedPreferences to remember session
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasAccount', true);
    } catch (e) {
      debugPrint("Error saving SharedPreferences: $e");
    }

    if (mounted) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      await _speakInstruction(lang.t('profile_saved') ??
          'Your profile has been saved successfully.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${lang.t('step')} ${currentStep + 1} ${lang.t('of')} 3'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showVoiceInstructionsDialog(lang),
            tooltip: lang.t('voice_help'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isListening)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('listening'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _spokenText.isEmpty
                                  ? lang.t('waiting_for_speech')
                                  : _spokenText,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isListening) const SizedBox(height: 20),
              stepContent(lang),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : (_isListening
                        ? _stopListeningAndProcess
                        : () => _showVoiceInstructionsDialog(lang)),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(_isListening ? Icons.stop : Icons.mic),
                label: Text(
                  _isListening
                      ? lang.t('stop')
                      : (_isProcessing
                          ? lang.t('processing')
                          : lang.t('voice_input')),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentStep > 0)
                    ElevatedButton(
                      onPressed: previousStep,
                      child: Text(lang.t('back')),
                    ),
                  ElevatedButton(
                    onPressed: nextStep,
                    child: Text(
                        currentStep < 2 ? lang.t('next') : lang.t('finish')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
