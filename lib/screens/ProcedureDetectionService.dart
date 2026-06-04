// lib/core/services/procedure_detection_service.dart

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class ProcedureDetectionService {
  static const _apiKey = 'YOUR_GEMINI_API_KEY';

  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _apiKey,
  );

  static const _procedures = [
    'lost_cin',
    'register_cnam',
    'birth_certificate',
    'passport',
    'driving_license',
    'cnss_registration',
    'marriage_certificate',
    'residence_certificate',
  ];

  static Future<Map<String, dynamic>?> detectProcedure(String userInput) async {
    final prompt = '''
You are an assistant for Tunisian administrative procedures.
The user said: "$userInput"

Available procedures: ${_procedures.join(', ')}

Respond ONLY with a valid JSON object like this (no markdown, no explanation):
{
  "matched_key": "lost_cin",
  "confidence": "high",
  "reason": "User mentioned losing their CIN card"
}

If nothing matches, return:
{
  "matched_key": null,
  "confidence": "none",
  "reason": "No matching procedure found"
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';

      // Strip markdown fences if present
      final cleaned = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}