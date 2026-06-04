import '../core/constants/app_strings.dart';
import '../models/chat_action.dart';

class LocalAssistantResponse {
  final String text;
  final List<ChatAction> actions;

  const LocalAssistantResponse({
    required this.text,
    this.actions = const [],
  });
}

class LocalAssistantService {
  static Future<LocalAssistantResponse> handleOfflineQuery(
    String query,
    AppLanguage lang,
  ) async {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('temps') ||
        lowerQuery.contains('affluence') ||
        lowerQuery.contains('visite') ||
        lowerQuery.contains('zham')) {
      return LocalAssistantResponse(
        text: lang == AppLanguage.french
            ? 'Utilisez l\'Optimizer pour voir les heures les plus calmes.'
            : 'استعمل Optimizer باش تشوف أوقات الزحمة.',
        actions: [
          ChatAction(
            label: lang == AppLanguage.french
                ? 'Ouvrir Optimizer'
                : 'Ouvrir Optimizer',
            route: '/optimizer',
          ),
        ],
      );
    }

    if (lowerQuery.contains('direction') ||
        lowerQuery.contains('navigation') ||
        lowerQuery.contains('guichet') ||
        lowerQuery.contains('camera')) {
      return LocalAssistantResponse(
        text: lang == AppLanguage.french
            ? 'La navigation AR peut vous guider jusqu\'au guichet.'
            : 'الملاحة بالواقع المعزز تنجم توصلك للشباك.',
        actions: [
          ChatAction(
            label: lang == AppLanguage.french ? 'Lancer AR' : 'Lancer AR',
            route: '/cv',
          ),
        ],
      );
    }

    if (lowerQuery.contains('formulaire') ||
        lowerQuery.contains('remplir') ||
        lowerQuery.contains('document')) {
      return LocalAssistantResponse(
        text: lang == AppLanguage.french
            ? 'L\'assistant de formulaires peut pre-remplir vos documents.'
            : 'مساعد الاستمارات ينجم يعمرلك الوثائق.',
        actions: [
          ChatAction(
            label: lang == AppLanguage.french
                ? 'Ouvrir Formulaire'
                : 'Ouvrir Formulaire',
            route: '/ai_form',
          ),
        ],
      );
    }

    return LocalAssistantResponse(
      text: lang == AppLanguage.french
          ? 'Mode local actif. Posez une question sur une procedure, un document ou la navigation.'
          : 'الوضع المحلي مفعل. اسأل على إجراء أو وثيقة أو تنقل.',
    );
  }
}
