import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/constants/app_strings.dart';
import '../core/database/database_helper.dart';
import '../models/chat_action.dart';
import '../models/procedure.dart';
import 'local_assistant_service.dart';

class ChatBotResponse {
  final String text;
  final List<ChatAction> actions;
  final Procedure? procedure;

  const ChatBotResponse({
    required this.text,
    this.actions = const [],
    this.procedure,
  });
}

class ChatbotService {
  static Future<ChatBotResponse> getBotReply(
    String userText,
    AppLanguage lang,
  ) async {
    final procedures = await DatabaseHelper.instance.getAllProcedures();
    final matches = DatabaseHelper.rankProcedures(procedures, userText);
    if (matches.isNotEmpty && matches.first.score >= 4) {
      return _buildProcedureReply(matches.first.procedure, lang);
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'your_real_api_key_here') {
      final local = await LocalAssistantService.handleOfflineQuery(userText, lang);
      return ChatBotResponse(text: local.text, actions: local.actions);
    }

    var userInfo = 'Aucune information personnelle disponible.';
    try {
      final profile = await DatabaseHelper.instance.getProfile();
      if (profile != null) {
        userInfo =
            'Nom: ${profile.fullName}, CIN: ${profile.cin}, Adresse: ${profile.address}';
      }
    } catch (_) {}

    final proceduresInfo = procedures.map((procedure) {
      return [
        procedure.title,
        'Documents: ${procedure.requiredDocuments.join(', ')}',
        'Cout: ${procedure.cost}',
        'Lieu: ${procedure.whereToGo}',
        'Etapes: ${procedure.steps.join(' | ')}',
      ].join('\n');
    }).join('\n\n');

    final langInstruction = switch (lang) {
      AppLanguage.french =>
        'Reponds en francais. Sois tres concis. Maximum 4 lignes. Priorite aux faits et aux prochaines actions.',
      AppLanguage.darija =>
        'Reponds en darija. Koun mokhtasar barcha. 4 sotor maximum. Atini facts w action directe.',
      AppLanguage.arabic =>
        'أجب بالعربية. كن موجزاً جداً في 4 أسطر كحد أقصى. أعط الحقائق والخطوة التالية فقط.',
    };

    final prompt = '''
Tu es MaakBot.
Role principal:
- Minimum interaction
- Reponses courtes
- Extraire les faits depuis la base de connaissances
- Proposer l'ecran utile quand c'est pertinent

$langInstruction

PROCEDURES:
$proceduresInfo

USER_PROFILE:
$userInfo

Si la question porte sur une procedure, reponds avec:
1. documents
2. cout
3. delai
4. lieu
Pas de bavardage.

Question utilisateur: $userText
''';

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 8));

      if (response.text == null || response.text!.trim().isEmpty) {
        throw Exception('Empty response');
      }

      return ChatBotResponse(text: response.text!.trim());
    } catch (_) {
      final local = await LocalAssistantService.handleOfflineQuery(userText, lang);
      return ChatBotResponse(
        text: lang == AppLanguage.french
            ? 'Assistant local en relais. ${local.text}'
            : 'Assistant local en relais. ${local.text}',
        actions: local.actions,
      );
    }
  }

  static ChatBotResponse _buildProcedureReply(
    Procedure procedure,
    AppLanguage lang,
  ) {
    final text = switch (lang) {
      AppLanguage.french =>
        'Procedure trouvee: ${procedure.title}. Consultez les documents, etapes et navigation ci-dessous.',
      AppLanguage.darija =>
        'لقينا الإجراء: ${procedure.title}. شوف الوثائق والخطوات والتنقل لتحت.',
      AppLanguage.arabic =>
        'تم العثور على الإجراء: ${procedure.title}. راجع الوثائق والخطوات والتنقل بالأسفل.',
    };

    return ChatBotResponse(
      text: text,
      procedure: procedure,
      actions: [
        ChatAction(
          label: lang == AppLanguage.french ? 'Voir details' : 'Voir details',
          route: '/procedure_detail',
          payload: procedure.key,
        ),
        ChatAction(
          label: lang == AppLanguage.french
              ? 'Trouver un bureau accessible'
              : 'Trouver un bureau accessible',
          route: '/office_finder',
        ),
      ],
    );
  }
}
