import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

enum AppLanguage { arabic, french, darija }

class AppStrings {
  static final Map<AppLanguage, Map<String, String>> translations = {
    // 🇸🇦 ARABIC
    AppLanguage.arabic: {
      'app_title': 'معاك',
      'smart_admin_assistant': 'مساعدك الإداري الذكي',
      'get_started': 'ابدأ الآن',
      'choose_language': 'اختر لغتك',
      'step_1_of_3': 'الخطوة 1 من 3',
      'step_2_of_3': 'الخطوة 2 من 3',
      'personal_identity': 'الهوية الشخصية',
      'create_profile': 'إنشاء ملفك الشخصي',
      'stored_securely': 'يتم تخزينه محليًا وبأمان على جهازك',
      'need_help_speak': 'هل تحتاج مساعدة؟ تحدث لملء الحقول',
      'full_name': 'الاسم الكامل',
      'cin_number': 'رقم بطاقة التعريف',
      'date_of_birth': 'تاريخ الميلاد',
      'phone_number': 'رقم الهاتف',
      'home_address': 'العنوان السكني',
      'next': 'التالي',
      'login': 'تسجيل الدخول',

      // Account Choice Screen
      'welcome': 'أهلاً بك في معاك',
      'do_you_have_account': 'هل لديك حساب بالفعل؟',
      'yes_i_have_account': 'نعم، لدي حساب بالفعل',
      'no_create_new': 'لا، أنشئ حساب جديد',
      'login_to_your_account': 'تسجيل الدخول إلى حسابك',

      // Voice related
      'voice_input': 'الإدخال الصوتي متاح',
      'voice_desc': 'جميع اللغات تدعم الأوامر الصوتية',
      'speak_to_fill': 'تحدث لملء النموذج',
      'stop_and_fill': 'إيقاف ومعالجة',
      'processing': 'جاري المعالجة...',
      'save_and_continue': 'حفظ ومتابعة',

      // HomeScreen
      'notification_title': 'مرحبا بعودتك!',
      'notification_subtitle': 'كيف يمكننا مساعدتك اليوم؟',
      'search_hint': 'ابحث عن الخدمات...',
      'quick_actions': 'الإجراءات السريعة',
      'ai_form': 'نموذج ذكي',
      'ai_form_desc': 'املأ الوثائق بذكاء',
      'procedures': 'الإجراءات',
      'procedures_desc': 'إجراءات حكومية',
      'office_finder': 'البحث عن المكاتب',
      'office_finder_desc': 'أقرب المكاتب الحكومية',
      'visit_optimizer': 'تحسين الزيارات',
      'visit_optimizer_desc': 'خطط زياراتك بذكاء',
      'recent_activity': 'النشاط الأخير',
      'see_all': 'عرض الكل',
      'activity_1': 'تجديد بطاقة التعريف',
      'activity_1_time': 'اليوم',
      'activity_2': 'تحديث العنوان',
      'activity_2_time': 'أمس',
      'saved': 'تم الحفظ',
      'offline': 'غير متصل',
      'home': 'الرئيسية',
      'assistant': 'المساعد',
      'offices': 'المكاتب',
      'profile': 'الملف الشخصي',

      // Procedure Assistant Screen
      'procedure_assistant': 'مساعد الإجراءات',
      'how_can_we_help': 'كيف يمكننا مساعدتك اليوم؟',
      'search_procedures_desc': 'ابحث عن الإجراءات الإدارية أو الوثائق بكلمات بسيطة',
      'search_hint_procedure': 'فقدت بطاقة تعريفي...',
      'common_procedures': 'الإجراءات الشائعة',
      'lost_cin': 'فقدت بطاقة التعريف',
      'lost_cin_desc': 'دليل الاستبدال والإبلاغ',
      'register_cnam': 'التسجيل في الكنام',
      'register_cnam_desc': 'التسجيل في التأمين الاجتماعي',
      'birth_certificate': 'شهادة الولادة',
      'birth_certificate_desc': 'طلب رقمي فوري',
      'opening_procedure': 'جاري فتح الإجراء:',

      // Procedure Detail Screen
      'procedure_details': 'تفاصيل الإجراء',
      'steps': 'الخطوات',
      'required_documents': 'الوثائق المطلوبة',
      'cost': 'التكلفة',
      'time_required': 'المدة الزمنية',
      'where_to_go': 'أين تذهب',
      'important_notes': 'ملاحظات هامة',
      'start_procedure': 'ابدأ الإجراء',
      'back': 'رجوع',
      'no_details_found': 'لم يتم العثور على تفاصيل هذا الإجراء',

      // Lost CIN Details
      'lost_cin_steps': 'الإبلاغ الفوري عن الفقدان في أقرب مركز شرطة أو حرس وطني||ملء الاستمارة الإدارية وتوقيعها||تقديم شهادة التصريح بالفقدان||إحضار 3 صور شمسية حديثة (مقاس 3/4 سم)||دفع الرسوم (25 دينار)||إيداع الملف في مركز الشرطة أو الحرس الوطني||استلام البطاقة الجديدة بعد المعالجة',
      'lost_cin_documents': 'استمارة الطلب الإدارية موقعة||شهادة التصريح بالفقدان||3 صور شمسية حديثة||وصل دفع الرسوم (25 دينار)||أي وثيقة إثبات هوية أخرى إن أمكن',
      'lost_cin_notes': 'يجب الإبلاغ عن الفقدان فوراً (خلال 30 يوم كحد أقصى). تجنب استخدام البطاقة القديمة بعد الفقدان.',
      'lost_cin_location': 'أقرب مركز شرطة أو حرس وطني في مكان إقامتك',

      // CNAM Registration Details
      'register_cnam_steps': 'التأكد من التسجيل في الصندوق الوطني للضمان الاجتماعي (CNSS)||تقديم طلب التسجيل في الكنام||إحضار الوثائق المطلوبة||انتظار الموافقة واستلام البطاقة',
      'register_cnam_documents': 'بطاقة التعريف الوطنية||شهادة التسجيل في CNSS||إثبات الدخل أو الوظيفة||صور شمسية',
      'register_cnam_notes': 'يجب أن تكون مسجلاً في الضمان الاجتماعي أولاً.',
      'register_cnam_location': 'مكاتب الكنام أو عبر التطبيق/الموقع الرسمي',

      // Birth Certificate Details
      'birth_certificate_steps': 'التوجه إلى المكتب البلدي لمكان الولادة||ملء استمارة الطلب||تقديم الوثائق المطلوبة||دفع الرسوم إن وجدت||استلام الشهادة',
      'birth_certificate_documents': 'بطاقة التعريف الوطنية للطالب||معلومات الوالدين||صورة من شهادة الولادة القديمة إن وجدت',
      'birth_certificate_notes': 'يمكن طلبها إلكترونياً عبر بعض المنصات الحكومية.',
      'birth_certificate_location': 'البلدية (المكتب البلدي) لمكان الولادة',
    },

    // 🇫🇷 FRENCH
    AppLanguage.french: {
      'app_title': 'Maak',
      'smart_admin_assistant': 'Votre assistant administratif intelligent',
      'get_started': 'Commencer',
      'choose_language': 'Choisir votre langue',
      'step_1_of_3': 'Étape 1 sur 3',
      'step_2_of_3': 'Étape 2 sur 3',
      'personal_identity': 'Identité personnelle',
      'create_profile': 'Créer votre profil',
      'stored_securely': 'Stocké localement et en sécurité sur votre appareil',
      'need_help_speak': 'Besoin d\'aide ? Parlez pour remplir les champs',
      'full_name': 'NOM COMPLET',
      'cin_number': 'NUMÉRO CIN',
      'date_of_birth': 'DATE DE NAISSANCE',
      'phone_number': 'NUMÉRO DE TÉLÉPHONE',
      'home_address': 'ADRESSE DOMICILE',
      'next': 'Suivant',
      'login': 'Connexion',

      // Account Choice Screen
      'welcome': 'Bienvenue sur Maak',
      'do_you_have_account': 'Avez-vous déjà un compte ?',
      'yes_i_have_account': 'Oui, j’ai déjà un compte',
      'no_create_new': 'Non, créer un nouveau compte',
      'login_to_your_account': 'Connectez-vous à votre compte',

      // Voice related
      'voice_input': 'Entrée vocale disponible',
      'voice_desc': 'Toutes les langues supportent les commandes vocales',
      'speak_to_fill': 'Parlez pour remplir le formulaire',
      'stop_and_fill': 'Arrêter et traiter',
      'processing': 'Traitement en cours...',
      'save_and_continue': 'Enregistrer et continuer',

      // HomeScreen
      'notification_title': 'Bienvenue de retour !',
      'notification_subtitle': 'Comment pouvons-nous vous aider aujourd’hui ?',
      'search_hint': 'Rechercher des services...',
      'quick_actions': 'Actions rapides',
      'ai_form': 'Formulaire intelligent',
      'ai_form_desc': 'Remplissez les documents intelligemment',
      'procedures': 'Procédures',
      'procedures_desc': 'Procédures gouvernementales',
      'office_finder': 'Trouver des bureaux',
      'office_finder_desc': 'Bureaux gouvernementaux les plus proches',
      'visit_optimizer': 'Optimiser les visites',
      'visit_optimizer_desc': 'Planifiez vos visites intelligemment',
      'recent_activity': 'Activité récente',
      'see_all': 'Voir tout',
      'activity_1': 'Renouvellement de la carte d\'identité',
      'activity_1_time': 'Aujourd’hui',
      'activity_2': 'Mise à jour de l\'adresse',
      'activity_2_time': 'Hier',
      'saved': 'Enregistré',
      'offline': 'Hors ligne',
      'home': 'Accueil',
      'assistant': 'Assistant',
      'offices': 'Bureaux',
      'profile': 'Profil',

      // Procedure Assistant Screen
      'procedure_assistant': 'Assistant Procédures',
      'how_can_we_help': 'Comment pouvons-nous vous aider aujourd’hui ?',
      'search_procedures_desc': 'Recherchez des procédures administratives ou des documents en termes simples.',
      'search_hint_procedure': 'J\'ai perdu ma CIN...',
      'common_procedures': 'Procédures courantes',
      'lost_cin': 'J\'ai perdu ma CIN',
      'lost_cin_desc': 'Guide de remplacement et déclaration',
      'register_cnam': 'S\'inscrire à la CNAM',
      'register_cnam_desc': 'Inscription à la sécurité sociale',
      'birth_certificate': 'Acte de naissance',
      'birth_certificate_desc': 'Demande numérique instantanée',
      'opening_procedure': 'Ouverture de la procédure :',

      // Procedure Detail Screen
      'procedure_details': 'Détails de la procédure',
      'steps': 'Étapes',
      'required_documents': 'Documents requis',
      'cost': 'Coût',
      'time_required': 'Durée estimée',
      'where_to_go': 'Où aller',
      'important_notes': 'Notes importantes',
      'start_procedure': 'Commencer la procédure',
      'back': 'Retour',
      'no_details_found': 'Aucun détail trouvé pour cette procédure',

      // Lost CIN Details
      'lost_cin_steps': 'Déclarer immédiatement la perte au poste de police ou de la Garde Nationale le plus proche||Remplir et signer le formulaire administratif||Fournir l\'attestation de déclaration de perte||Fournir 3 photos d\'identité récentes (format 3/4 cm)||Payer les droits (25 dinars)||Déposer le dossier au poste de police ou Garde Nationale||Récupérer la nouvelle carte après traitement',
      'lost_cin_documents': 'Formulaire administratif rempli et signé||Attestation de déclaration de perte||3 photos d\'identité récentes||Quittance de paiement (25 dinars)||Tout autre document prouvant votre identité',
      'lost_cin_notes': 'Déclarez la perte immédiatement (dans un délai max de 30 jours). Évitez d\'utiliser l\'ancienne carte après la perte.',
      'lost_cin_location': 'Poste de police ou Garde Nationale le plus proche de votre résidence',

      // CNAM Details
      'register_cnam_steps': 'Vérifier votre affiliation à la CNSS||Déposer une demande d\'inscription à la CNAM||Fournir les documents requis||Attendre l\'approbation et recevoir la carte',
      'register_cnam_documents': 'Carte d\'identité nationale||Attestation d\'affiliation CNSS||Preuve de revenus ou emploi||Photos d\'identité',
      'register_cnam_notes': 'Vous devez d\'abord être affilié à la sécurité sociale (CNSS).',
      'register_cnam_location': 'Agences CNAM ou via le site/application officiel',

      // Birth Certificate Details
      'birth_certificate_steps': 'Se rendre à la municipalité du lieu de naissance||Remplir le formulaire de demande||Fournir les documents requis||Payer les frais si applicable||Récupérer l\'extrait',
      'birth_certificate_documents': 'Carte d\'identité du demandeur||Informations des parents||Copie de l\'ancien acte si disponible',
      'birth_certificate_notes': 'Il est parfois possible de la demander en ligne via les plateformes gouvernementales.',
      'birth_certificate_location': 'Municipalité du lieu de naissance',
    },

    // 🇹🇳 DARIJA
    AppLanguage.darija: {
      'app_title': 'معاك',
      'smart_admin_assistant': 'مساعدك الإداري الذكي',
      'get_started': 'نبداو',
      'choose_language': 'اختر لغتك',
      'step_1_of_3': 'خطوة 1 من 3',
      'step_2_of_3': 'خطوة 2 من 3',
      'personal_identity': 'الهوية الشخصية',
      'create_profile': 'عمل بروفيلك',
      'stored_securely': 'يتخزن محليا وبأمان على جهازك',
      'need_help_speak': 'تحتاج مساعدة؟ احكي باش تعمّر الحقول',
      'full_name': 'الاسم الكامل',
      'cin_number': 'رقم البطاقة',
      'date_of_birth': 'تاريخ الولادة',
      'phone_number': 'رقم التليفون',
      'home_address': 'العنوان',
      'next': 'اللي بعدو',
      'login': 'دخول',

      // Account Choice Screen
      'welcome': 'مرحبا بيك في معاك',
      'do_you_have_account': 'عندك حساب ولا لا؟',
      'yes_i_have_account': 'آه عندي حساب',
      'no_create_new': 'لا، ننشأ حساب جديد',
      'login_to_your_account': 'دخل لحسابك',

      // Voice related
      'voice_input': 'الإدخال بالصوت متوفر',
      'voice_desc': 'اللغات الكل تدعم الأوامر الصوتية',
      'speak_to_fill': 'احكي باش تعمر الفورم',
      'stop_and_fill': 'وقف ومعالجة',
      'processing': 'جاري المعالجة...',
      'save_and_continue': 'حفظ ونكملو',

      // HomeScreen
      'notification_title': 'مرحبا بعودتك!',
      'notification_subtitle': 'كيفاش نقدروا نساعدوك اليوم؟',
      'search_hint': 'ابحث على الخدمات...',
      'quick_actions': 'الإجراءات السريعة',
      'ai_form': 'فورم ذكي',
      'ai_form_desc': 'عمر الوثائق بالذكاء',
      'procedures': 'الإجراءات',
      'procedures_desc': 'إجراءات حكومية',
      'office_finder': 'البحث على المكاتب',
      'office_finder_desc': 'أقرب المكاتب الحكومية',
      'visit_optimizer': 'تحسين الزيارات',
      'visit_optimizer_desc': 'خطط زياراتك بذكاء',
      'recent_activity': 'النشاط الأخير',
      'see_all': 'شوف الكل',
      'activity_1': 'تجديد بطاقة التعريف',
      'activity_1_time': 'اليوم',
      'activity_2': 'تحديث العنوان',
      'activity_2_time': 'أمس',
      'saved': 'تم الحفظ',
      'offline': 'غير متصل',
      'home': 'الرئيسية',
      'assistant': 'المساعد',
      'offices': 'المكاتب',
      'profile': 'البروفيل',

      // Procedure Assistant Screen
      'procedure_assistant': 'مساعد الإجراءات',
      'how_can_we_help': 'كيفاش نقدرو نساعدوك اليوم؟',
      'search_procedures_desc': 'ابحث على الإجراءات الإدارية أو الوثائق بكلمات بسيطة',
      'search_hint_procedure': 'ضيعت بطاقة التعريف...',
      'common_procedures': 'الإجراءات الشائعة',
      'lost_cin': 'ضيعت بطاقتي',
      'lost_cin_desc': 'دليل الاستبدال والتبليغ',
      'register_cnam': 'تسجل في الكنام',
      'register_cnam_desc': 'التسجيل في التأمين الاجتماعي',
      'birth_certificate': 'شهادة الميلاد',
      'birth_certificate_desc': 'طلب رقمي فوري',
      'opening_procedure': 'فتح الإجراء:',

      // Procedure Detail Screen
      'procedure_details': 'تفاصيل الإجراء',
      'steps': 'الخطوات',
      'required_documents': 'الوثائق اللازمة',
      'cost': 'التكلفة',
      'time_required': 'المدة',
      'where_to_go': 'وين تمشي',
      'important_notes': 'ملاحظات مهمة',
      'start_procedure': 'نبداو الإجراء',
      'back': 'رجوع',
      'no_details_found': 'ما لقيناش تفاصيل هذا الإجراء',

      // Lost CIN Details
      'lost_cin_steps': 'بلغ فورا على الضياع في أقرب مركز شرطة أو حرس||عمّر الاستمارة الإدارية ووقّعها||جيب شهادة التصريح بالضياع||جيب 3 صور شمسية جديدة (مقاس 3/4)||ادفع 25 دينار||سلم الملف في الشرطة أو الحرس||خذ البطاقة الجديدة بعد 15 يوم',
      'lost_cin_documents': 'استمارة إدارية معمّرة وموقّعة||شهادة التبليغ بالضياع||3 صور شمسية جديدة||وصل الدفع 25 دينار||أي وثيقة أخرى تثبت هويتك',
      'lost_cin_notes': 'بلغ على الضياع فورا (ماشي أكثر من 30 يوم). متستعملش البطاقة القديمة بعد الضياع.',
      'lost_cin_location': 'أقرب مركز شرطة أو حرس في منطقتك',

      // CNAM Details
      'register_cnam_steps': 'تأكد أنك مسجل في الـ CNSS||قدم طلب التسجيل في الكنام||جيب الوثائق اللازمة||استنى الموافقة وخذ الكارت',
      'register_cnam_documents': 'بطاقة التعريف||شهادة تسجيل في الـ CNSS||إثبات الراتب أو الشغل||صور شمسية',
      'register_cnam_notes': 'لازم تكون مسجل في الـ CNSS قبل الكنام.',
      'register_cnam_location': 'مكاتب الكنام أو عبر الإنترنت',

      // Birth Certificate Details
      'birth_certificate_steps': 'روح للبلدية متاع مكان الولادة||عمّر الاستمارة||جيب الوثائق||ادفع إذا لازم||خذ الشهادة',
      'birth_certificate_documents': 'بطاقة التعريف||معلومات الأب والأم||نسخة من الشهادة القديمة إذا موجودة',
      'birth_certificate_notes': 'ممكن تطلبها أونلاين من بعض المواقع الحكومية.',
      'birth_certificate_location': 'البلدية متاع مكان الولادة',
    },
  };

  static String get(BuildContext context, String key) {
    final provider = Provider.of<LanguageProvider>(context, listen: false);
    return translations[provider.currentLanguage]?[key] ?? key;
  }
}