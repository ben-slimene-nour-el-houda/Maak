import 'dart:ui';

class DetectedTextTarget {
  final String id;
  final String text;
  final Rect boundingBox;
  final double centerX;
  final double centerY;
  final double confidence;
  final bool isMatch;
  final DateTime timestamp;

  DetectedTextTarget({
    required this.id,
    required this.text,
    required this.boundingBox,
    required this.centerX,
    required this.centerY,
    required this.confidence,
    required this.isMatch,
    required this.timestamp,
  });

  /// Position normalisée X (0 à 1) relative à l'image
  double normalizedX(double imageWidth) =>
      imageWidth > 0 ? centerX / imageWidth : 0.5;

  /// Position normalisée Y (0 à 1) relative à l'image
  double normalizedY(double imageHeight) =>
      imageHeight > 0 ? centerY / imageHeight : 0.5;

  /// Position du centre sur l'écran
  Offset screenPosition(double screenWidth, double screenHeight,
      double imageWidth, double imageHeight) {
    final scaleX = screenWidth / imageWidth;
    final scaleY = screenHeight / imageHeight;
    return Offset(centerX * scaleX, centerY * scaleY);
  }

  DetectedTextTarget copyWith({
    String? id,
    String? text,
    Rect? boundingBox,
    double? centerX,
    double? centerY,
    double? confidence,
    bool? isMatch,
    DateTime? timestamp,
  }) {
    return DetectedTextTarget(
      id: id ?? this.id,
      text: text ?? this.text,
      boundingBox: boundingBox ?? this.boundingBox,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      confidence: confidence ?? this.confidence,
      isMatch: isMatch ?? this.isMatch,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
