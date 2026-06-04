// lib/screens/ai_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/providers/language_provider.dart';
import '../core/providers/accessibility_provider.dart';
import '../core/database/database_helper.dart';
import '../models/user_profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiFormScreen extends StatefulWidget {
  const AiFormScreen({super.key});

  @override
  State<AiFormScreen> createState() => _AiFormScreenState();
}

class _AiFormScreenState extends State<AiFormScreen> {
  XFile? _scannedImage;
  bool _isScanning = false;
  Map<String, String> _detectedFields = {};
  UserProfile? _profile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseHelper.instance.getProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _simulateScan() async {
    setState(() => _isScanning = true);

    // Simulate camera / gallery pick (demo)
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => _scannedImage = image);

      // Simulate OCR + AI field detection (realistic for demo)
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _detectedFields = {
          'Traitement en cours...': 'Analyse du document par l\'IA',
        };
      });
      // Send the image to the backend for processing and PDF generation
      _uploadForm(image);
    }
    setState(() => _isScanning = false);
  }

  Future<void> _uploadForm(XFile image) async {
    const storage = FlutterSecureStorage();
    final String? registeredId = await storage.read(key: 'registered_user_id');
    final String? token = await storage.read(key: 'jwt_auth_token');

    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';
    final userId = registeredId ?? '2';
    final uri = Uri.parse("$backendUrl/auto_fill_form/$userId");
    
    var request = http.MultipartRequest('POST', uri);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    var pic = http.MultipartFile.fromBytes(
      "file",
      await image.readAsBytes(),
      filename: image.name,
    );
    request.files.add(pic);

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        print("File uploaded successfully");

        var responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);

        setState(() {
          _detectedFields = {};
          if (jsonResponse.containsKey('name')) _detectedFields['Nom complet'] = jsonResponse['name'].toString();
          if (jsonResponse.containsKey('cin')) _detectedFields['CIN'] = jsonResponse['cin'].toString();
          if (jsonResponse.containsKey('address')) _detectedFields['Ville/Adresse'] = jsonResponse['address'].toString();
          if (jsonResponse.containsKey('dob')) _detectedFields['Date de naissance'] = jsonResponse['dob'].toString();
          if (jsonResponse.containsKey('phone')) _detectedFields['Téléphone'] = jsonResponse['phone'].toString();
          
          if (_detectedFields.isEmpty) {
             _detectedFields['Reconnaissance échouée'] = 'Aucun champ pertinent détecté.';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("PDF generated and ready for download!")));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Non autorisé. Veuillez recréer votre profil."), backgroundColor: Colors.red));
      } else {
        print("Failed to upload file: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to upload form: ${response.statusCode}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error uploading the form")));
    }
  }

  Future<void> _openPDF(String pdfUrl) async {
    if (await canLaunch(pdfUrl)) {
      await launch(pdfUrl);
    } else {
      throw 'Could not open the PDF';
    }
  }

  Future<String> _savePDF(Uint8List pdfBytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfPath = '${directory.path}/filled_form.pdf';
    final file = File(pdfPath);
    await file.writeAsBytes(pdfBytes);
    return pdfPath;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final accessibility = Provider.of<AccessibilityProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.t('ai_form'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scan button - large for accessibility
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isScanning ? null : _simulateScan,
                icon: const Icon(Icons.camera_alt, size: 32),
                label: Text(
                  _isScanning
                      ? 'Scan en cours...'
                      : '📸 Scanner un formulaire vierge',
                  style: const TextStyle(fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
              ),
            ),

            if (_scannedImage != null) ...[
              const SizedBox(height: 24),
              Text('Formulaire scanné',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: kIsWeb
                    ? Image.network(_scannedImage!.path, height: 220, fit: BoxFit.cover)
                    : Image.file(File(_scannedImage!.path), height: 220, fit: BoxFit.cover),
              ),
            ],

            if (_detectedFields.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('Champs détectés et auto-remplis',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              ..._detectedFields.entries.map((entry) => Card(
                    child: ListTile(
                      title: Text(entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(entry.value),
                      trailing:
                          const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  )),

              const SizedBox(height: 32),
              // Preview filled form (simulated realistic layout)
              Text('Aperçu du formulaire rempli (PDF prêt à imprimer)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _detectedFields.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                    width: 140,
                                    child: Text(e.key,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500))),
                                const Text(': '),
                                Expanded(
                                    child: Text(e.value,
                                        style: const TextStyle(fontSize: 16))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              '✅ Formulaire PDF généré et prêt à imprimer !')),
                    );
                  },
                  child: const Text('📄 Télécharger PDF imprimable',
                      style: TextStyle(fontSize: 18)),
                ),
              ),
            ],

            if (accessibility.voiceMode)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('🔊 Mode voix activé – tout sera lu à haute voix',
                    style: TextStyle(color: Colors.blue)),
              ),
          ],
        ),
      ),
    );
  }
}
