import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter/material.dart';

class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();

  /// Listen and return recognized text
  static Future<String> listen({String? preferredLocale}) async {
    String recognizedText = '';

    // Initialize
    bool available = await _speech.initialize(
      onStatus: (val) => debugPrint('Voice status: $val'),
      onError: (val) => debugPrint('Voice error: $val'),
    );

    if (!available) {
      debugPrint('Speech recognition not available on this device');
      return '';
    }

    // Try best locales for Tunisia (in order of preference)
    final locales = await _speech.locales();
    String localeId = 'fr_FR'; // default fallback

    // Priority: French > Arabic > English
    if (preferredLocale != null) {
      localeId = preferredLocale;
    } else if (locales.any((l) => l.localeId.startsWith('ar'))) {
      localeId = 'ar';                    // Modern Standard Arabic
    } else if (locales.any((l) => l.localeId.startsWith('fr'))) {
      localeId = 'fr_FR';
    }

    debugPrint('Using speech locale: $localeId');

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        recognizedText = result.recognizedWords;
      },
      localeId: localeId,
      partialResults: true,
      listenFor: const Duration(seconds: 8),   // you can increase if needed
    );

    // Wait for user to finish speaking
    await Future.delayed(const Duration(seconds: 6));
    await _speech.stop();

    return recognizedText.trim();
  }
}