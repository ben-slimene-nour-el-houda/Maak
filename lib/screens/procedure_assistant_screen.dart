import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import '../core/utils/voice_service.dart';
import '../core/constants/app_strings.dart';
import '../models/procedure.dart';
import 'procedure_detail_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ---------------------------------------------------------------------------
// Gemini-powered procedure detection service (Strong Darija Support)
// ---------------------------------------------------------------------------
class _ProcedureDetectionService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.2,
    ),
  );

  static const _procedureKeys = [
    'lost_cin',
    'register_cnam',
    'birth_certificate',
    'passport',
    'driving_license',
    'cnss_registration',
    'marriage_certificate',
    'residence_certificate',
    'death_certificate',
    'family_record_book',
  ];

  static Future<String?> detect(String userInput) async {
    if (userInput.trim().isEmpty) return null;

    final prompt = '''
You are a helpful Tunisian assistant for administrative procedures.

User input (French, English or Tunisian Darija): "$userInput"

Available procedures:
- lost_cin              → ضيعت بطاقتي، بطاقة التعريف ضاعت، j'ai perdu mon CIN، carte perdue
- register_cnam         → نسجل في الCNAM، inscription CNAM، التأمين الصحي
- birth_certificate     → شهادة الميلاد، acte de naissance، استخراج شهادة ولادة
- passport              → باسبور، جواز سفر، نعمل باسبور جديد
- driving_license       → رخصة السياقة، permis de conduire، البرمي
- cnss_registration     → CNSS، الضمان الاجتماعي، نسجل في الCNSS
- marriage_certificate  → شهادة الزواج، acte de mariage
- residence_certificate → شهادة الإقامة، certificat de résidence

Respond **ONLY** with this JSON (no extra text):

{
  "matched_key": "lost_cin",
  "confidence": "high"
}

If nothing matches:
{
  "matched_key": null,
  "confidence": "none"
}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final raw =
          (response.text ?? '').replaceAll(RegExp(r'```json|```'), '').trim();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final key = json['matched_key'];
      return (key is String && _procedureKeys.contains(key)) ? key : null;
    } catch (e) {
      debugPrint('Detection error: $e');
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------
class ProcedureAssistantScreen extends StatefulWidget {
  const ProcedureAssistantScreen({super.key});

  @override
  State<ProcedureAssistantScreen> createState() =>
      _ProcedureAssistantScreenState();
}

class _ProcedureAssistantScreenState extends State<ProcedureAssistantScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isListening = false;
  bool _isDetecting = false;
  bool _isSpeaking = false;
  late FlutterTts _tts;

  List<Procedure> _filteredProcedures = [];

  final List<Procedure> _allProcedures = [
    Procedure(
      key: 'lost_cin',
      title: 'Lost CIN',
      description:
          'Report a lost CIN (Carte d\'Identité Nationale) and request a replacement',
      steps: [
        'File a loss declaration at the police station',
        'Collect required documents',
        'Visit Civil Affairs office',
        'Submit documents',
        'Receive new CIN in 3 days'
      ],
      requiredDocuments: ['Police declaration', '2 photos', 'Proof of address'],
      cost: 'Free',
      timeRequired: '3 working days',
      whereToGo: 'Civil Affairs Office',
      importantNotes: 'Bring originals and photocopies.',
      icon: Icons.credit_card_outlined,
    ),
    Procedure(
      key: 'register_cnam',
      title: 'Register with CNAM',
      description: 'Enrol in the national health insurance',
      steps: ['Fill the form', 'Attach documents', 'Submit at CNAM office'],
      requiredDocuments: ['CIN', 'Birth certificate', 'Work contract'],
      cost: 'Free',
      timeRequired: '1 week',
      whereToGo: 'CNAM regional office',
      importantNotes: 'Documents must be valid.',
      icon: Icons.health_and_safety_outlined,
    ),
    Procedure(
      key: 'birth_certificate',
      title: 'Birth Certificate',
      description: 'Obtain an official copy of birth certificate',
      steps: ['Go to Civil Affairs office', 'Present ID', 'Pay stamp fee'],
      requiredDocuments: ['National ID'],
      cost: '5 TND',
      timeRequired: '1-2 days',
      whereToGo: 'Civil Affairs Office of birth municipality',
      importantNotes: 'Bring photocopies.',
      icon: Icons.child_care_outlined,
    ),
    Procedure(
      key: 'passport',
      title: 'Passport Application',
      description: 'Apply for a new Tunisian passport',
      steps: ['Fill form', 'Prepare documents', 'Submit at Interior Ministry'],
      requiredDocuments: ['CIN', 'Birth certificate', '4 photos'],
      cost: '60 TND',
      timeRequired: '2-4 weeks',
      whereToGo: 'Interior Ministry regional office',
      importantNotes: 'Biometric photos required.',
      icon: Icons.book_outlined,
    ),
    Procedure(
      key: 'driving_license',
      title: 'Driving Licence',
      description: 'Apply for or renew driving licence',
      steps: ['Enrol in driving school', 'Pass tests'],
      requiredDocuments: ['CIN', 'Medical certificate', 'Photos'],
      cost: 'Variable',
      timeRequired: '1-3 months',
      whereToGo: 'Regional Transport Office',
      importantNotes: 'Medical certificate must be recent.',
      icon: Icons.directions_car_outlined,
    ),
    Procedure(
      key: 'cnss_registration',
      title: 'CNSS Registration',
      description: 'Register for social security',
      steps: ['Get form', 'Fill details', 'Submit at CNSS'],
      requiredDocuments: ['CIN', 'Employment contract'],
      cost: 'Free',
      timeRequired: '1 week',
      whereToGo: 'CNSS regional office',
      importantNotes: 'Employer must also register.',
      icon: Icons.security_outlined,
    ),
    Procedure(
      key: 'marriage_certificate',
      title: 'Marriage Certificate',
      description: 'Get a copy of marriage certificate',
      steps: ['Visit Civil Affairs office', 'Present ID'],
      requiredDocuments: ['CIN of spouse'],
      cost: '3 TND',
      timeRequired: 'Same day',
      whereToGo: 'Civil Affairs Office',
      importantNotes: 'Can request via proxy.',
      icon: Icons.favorite_outline,
    ),
    Procedure(
      key: 'residence_certificate',
      title: 'Residence Certificate',
      description: 'Obtain proof of residence',
      steps: ['Visit municipality', 'Fill form', 'Present address proof'],
      requiredDocuments: ['CIN', 'Utility bill or rental contract'],
      cost: '1 TND',
      timeRequired: 'Same day',
      whereToGo: 'Local municipality',
      importantNotes: 'Valid for 3 months.',
      icon: Icons.home_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredProcedures = List.from(_allProcedures);
    _tts = FlutterTts();
    _initTTS();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakWelcomeMessage());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTTS() async {
    await _tts.setLanguage('ar_TN');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;
    setState(() => _isSpeaking = true);
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  Future<void> _speakWelcomeMessage() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    await _speakText(
      lang.t('welcome_procedure') ?? 'مرحبا! قلي شنوة الإجراء اللي تحتاجو.',
    );
  }

  // Local filtering with Darija support
  void _filterLocally(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredProcedures = q.isEmpty
          ? List.from(_allProcedures)
          : _allProcedures.where((p) {
              final title = p.title.toLowerCase();
              final desc = p.description.toLowerCase();
              final key = p.key.toLowerCase();

              return title.contains(q) ||
                  desc.contains(q) ||
                  key.contains(q) ||
                  (q.contains('perdu') ||
                          q.contains('ضيعت') ||
                          q.contains('بطاقة')) &&
                      key.contains('lost_cin') ||
                  (q.contains('باسبور') || q.contains('passeport')) &&
                      key.contains('passport') ||
                  (q.contains('cnam') || q.contains('تأمين')) &&
                      key.contains('register_cnam') ||
                  (q.contains('cnss') || q.contains('ضمان')) &&
                      key.contains('cnss_registration') ||
                  (q.contains('ميلاد') || q.contains('naissance')) &&
                      key.contains('birth_certificate');
            }).toList();
    });
  }

  Future<void> _detectAndNavigate(String input) async {
    if (input.trim().isEmpty) return;

    _filterLocally(input);
    setState(() => _isDetecting = true);
    await _speakText('نبحث على الإجراء...');

    final matchedKey = await _ProcedureDetectionService.detect(input);

    if (!mounted) return;
    setState(() => _isDetecting = false);

    if (matchedKey == null) {
      await _speakText('ما لقيتش تطابق واضح. نشوفو النتائج القريبة.');
      return;
    }

    final matched = _allProcedures.firstWhere(
      (p) => p.key == matchedKey,
      orElse: () => _allProcedures.first,
    );

    await _speakText('لقيناه: ${matched.title}');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProcedureDetailScreen(procedureKey: matched.key),
      ),
    );
  }

  Future<void> _startVoiceInput() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    await _speakText(
      lang.t('say_procedure_name') ?? 'قولي شنوة الإجراء اللي تحتاجو (بالدارجة أو الفرنسية)',
    );

    setState(() => _isListening = true);

    try {
      // You can pass 'ar' or 'fr_FR' depending on user language
      final text = await VoiceService.listen(preferredLocale: 'ar');
      
      if (text.isNotEmpty) {
        _searchController.text = text;
        await _detectAndNavigate(text);
      } else {
        await _speakText('ما سمعتش شيء واضح. حاول مرة أخرى.');
      }
    } catch (e) {
      debugPrint('Voice error: $e');
      await _speakText('فشل التعرف على الصوت. جرب الكتابة يدوياً.');
    } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _showVoiceInstructions(LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.mic, color: Color(0xFF1E3A8A), size: 28),
              const SizedBox(width: 12),
              Text(
                  lang.t('voice_search_instructions') ??
                      'كيفية استخدام البحث الصوتي',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 24),
            _buildStep(1, 'قول الإجراء', 'مثلاً: "ضيعت بطاقتي" أو "نبي باسبور"',
                Icons.record_voice_over),
            const SizedBox(height: 16),
            _buildStep(2, 'انتظر الذكاء الاصطناعي', 'يحاول يفهم طلبك',
                Icons.psychology_outlined),
            const SizedBox(height: 16),
            _buildStep(
                3, 'شوف النتيجة', 'يفتح لك الإجراء مباشرة', Icons.checklist),
            const SizedBox(height: 20),
            _buildTips(lang),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startVoiceInput();
                },
                icon: const Icon(Icons.mic),
                label:
                    Text(lang.t('start_voice_search') ?? 'ابدأ البحث الصوتي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int n, String title, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
              child: Text('$n',
                  style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text(desc,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTips(LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFF59E0B), size: 20), // Fixed color
              const SizedBox(width: 8),
              Text(
                lang.t('helpful_tips') ?? 'نصائح',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF59E0B),   // Fixed - using direct color instead of shade
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• تكلم ببطء ووضوح\n'
            '• استخدم لهجة تونسية طبيعية\n'
            '• مثلاً: "ضيعت بطاقتي" أو "نبي باسبور"',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFF59E0B),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _onProcedureTap(Procedure p, LanguageProvider lang) {
    _speakText('${lang.t('selected') ?? 'تم اختيار'}: ${p.title}');
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ProcedureDetailScreen(procedureKey: p.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isRtl = lang.currentLanguage == AppLanguage.arabic ||
        lang.currentLanguage == AppLanguage.darija;

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context)),
          title: Text(
              AppStrings.get(context, 'procedure_assistant') ??
                  'مساعد الإجراءات',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white)),
          actions: [
            IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () => _showVoiceInstructions(lang)),
          ],
        ),
        body: Column(
          children: [
            // Header + Search
            Container(
              color: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      AppStrings.get(context, 'how_can_we_help') ??
                          'كيف نقدر نساعدوك؟',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                      AppStrings.get(context, 'search_procedures_desc') ??
                          'اكتب أو تكلم بالفرنسية أو الدارجة',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _searchController,
                      textDirection:
                          isRtl ? TextDirection.rtl : TextDirection.ltr,
                      onChanged: _filterLocally,
                      onSubmitted: _detectAndNavigate,
                      decoration: InputDecoration(
                        hintText: 'مثلاً: ضيعت بطاقتي ...',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.grey, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterLocally('');
                                  }),
                            IconButton(
                              icon: Icon(
                                  _isListening ? Icons.stop_circle : Icons.mic,
                                  color: _isListening
                                      ? Colors.red
                                      : const Color(0xFF1E3A8A),
                                  size: 26),
                              onPressed: _isListening
                                  ? null
                                  : () => _showVoiceInstructions(lang),
                            ),
                          ],
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isListening) _buildBanner(Colors.red, Icons.mic, 'يستمع...'),
            if (_isDetecting)
              _buildBanner(const Color(0xFF1E3A8A), Icons.psychology_outlined,
                  'الذكاء الاصطناعي يبحث...'),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'الإجراءات الشائعة'
                          : '${_filteredProcedures.length} نتيجة',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty && !_isDetecting)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _detectAndNavigate(_searchController.text),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('ابحث بالذكاء الاصطناعي'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1E3A8A),
                            side: const BorderSide(color: Color(0xFF1E3A8A))),
                      ),
                    ),
                  if (_filteredProcedures.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredProcedures
                        .map((p) => _buildProcedureCard(p, lang)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assistant), label: 'المساعد'),
            BottomNavigationBarItem(
                icon: Icon(Icons.location_on), label: 'المكاتب'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'الحساب'),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildBanner(Color color, IconData icon, String message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color)),
          const SizedBox(width: 12),
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(message,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProcedureCard(Procedure procedure, LanguageProvider lang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ]),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(procedure.icon ?? Icons.description,
              color: const Color(0xFF1E3A8A), size: 26),
        ),
        title: Text(procedure.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(procedure.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(spacing: 6, children: [
                _infoPill(Icons.schedule, procedure.timeRequired),
                _infoPill(Icons.attach_money, procedure.cost)
              ]),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        isThreeLine: true,
        onTap: () => _onProcedureTap(procedure, lang),
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFF1E3A8A).withOpacity(0.06),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: const Color(0xFF1E3A8A)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)))
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: const [
            Icon(Icons.search_off, size: 56, color: Colors.grey),
            SizedBox(height: 16),
            Text(
                'ما لقينا شي إجراء.\nجرب كلمات أخرى أو استخدم البحث بالذكاء الاصطناعي.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
