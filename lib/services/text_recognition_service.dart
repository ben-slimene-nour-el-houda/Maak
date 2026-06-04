import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/detected_text_target.dart';

class TextRecognitionService {
  late TextRecognizer _recognizer;

  TextRecognitionService() {
    _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  }

  /// Analyse une image et retourne les textes détectés avec leur position
  Future<List<DetectedTextTarget>> analyzeImage(
    String imagePath, {
    String keyword = '',
  }) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(inputImage);

      final List<DetectedTextTarget> targets = [];

      for (final block in recognized.blocks) {
        for (final line in block.lines) {
          if (line.text.trim().isEmpty) continue;

          final boundingBox = line.boundingBox;
          final isMatch = keyword.isNotEmpty &&
              line.text.toLowerCase().contains(keyword.toLowerCase());

          // Confidence score basé sur la confiance des éléments
          double confidence = 0.0;
          if (line.elements.isNotEmpty) {
            confidence = line.elements
                    .map((e) => e.confidence ?? 0.8)
                    .reduce((a, b) => a + b) /
                line.elements.length;
          }

          targets.add(DetectedTextTarget(
            id: '${block.text}_${line.text}_${boundingBox.left}',
            text: line.text.trim(),
            boundingBox: Rect.fromLTWH(
              boundingBox.left.toDouble(),
              boundingBox.top.toDouble(),
              boundingBox.width.toDouble(),
              boundingBox.height.toDouble(),
            ),
            centerX: (boundingBox.left + boundingBox.width / 2).toDouble(),
            centerY: (boundingBox.top + boundingBox.height / 2).toDouble(),
            confidence: confidence > 0 ? confidence : 0.85,
            isMatch: isMatch,
            timestamp: DateTime.now(),
          ));
        }
      }

      // Trier: les matches en premier, puis par confiance
      targets.sort((a, b) {
        if (a.isMatch && !b.isMatch) return -1;
        if (!a.isMatch && b.isMatch) return 1;
        return b.confidence.compareTo(a.confidence);
      });

      return targets;
    } catch (e) {
      return [];
    }
  }

  void dispose() {
    _recognizer.close();
  }
}
