import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/detected_text_target.dart';

class ARTextDetectionOverlay extends StatelessWidget {
  final List<DetectedTextTarget> targets;
  final DetectedTextTarget? selectedTarget;
  final Function(DetectedTextTarget) onTargetTap;
  final AnimationController pulseAnimation;

  const ARTextDetectionOverlay({
    super.key,
    required this.targets,
    required this.selectedTarget,
    required this.onTargetTap,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const imageWidth = 720.0;
    const imageHeight = 1280.0;

    final scaleX = size.width / imageWidth;
    final scaleY = size.height / imageHeight;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (_, __) {
          return Stack(
            children: targets.map((target) {
              final isSelected = selectedTarget?.id == target.id;
              final left = target.boundingBox.left * scaleX;
              final top = target.boundingBox.top * scaleY;
              final width = target.boundingBox.width * scaleX;
              final height = target.boundingBox.height * scaleY;

              Color accentColor;
              if (isSelected) {
                accentColor = const Color(0xFF1E40AF); // Maak blue
              } else if (target.isMatch) {
                accentColor = const Color(0xFF1D9E75); // Maak teal
              } else {
                accentColor = const Color(0xFF60A5FA); // light blue
              }

              final animValue = isSelected ? pulseAnimation.value : 0.0;
              // Brackets convergence: larger when not selected/pulsing
              final bracketOffset = isSelected ? (5.0 * (1.0 - animValue)) : 2.0;

              return Positioned(
                left: left - bracketOffset,
                top: top - bracketOffset,
                width: width + (bracketOffset * 2),
                height: height + (bracketOffset * 2),
                child: GestureDetector(
                  onTap: () => onTargetTap(target),
                  child: Stack(
                    children: [
                      // 1. Corner Brackets
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BracketPainter(
                            color: accentColor,
                            isSelected: isSelected,
                            opacity: isSelected 
                                ? 0.8 + (animValue * 0.2) 
                                : 0.4,
                          ),
                        ),
                      ),
                      
                      // 2. Glassmorphism Label
                      Positioned(
                        top: -22,
                        left: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.7),
                                border: Border.all(color: Colors.white24, width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (target.isMatch)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(Icons.radar, color: Colors.white, size: 10),
                                    ),
                                  Text(
                                    target.text.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${(target.confidence * 100).toInt()}%',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final bool isSelected;
  final double opacity;

  _BracketPainter({
    required this.color,
    required this.isSelected,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.2
      ..strokeCap = StrokeCap.square;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 6.0 : 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const len = 10.0;

    void drawBrackets(Paint p) {
      // Top Left
      canvas.drawLine(Offset.zero, const Offset(len, 0), p);
      canvas.drawLine(Offset.zero, const Offset(0, len), p);

      // Top Right
      canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), p);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), p);

      // Bottom Left
      canvas.drawLine(Offset(0, size.height), Offset(len, size.height), p);
      canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), p);

      // Bottom Right
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), p);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), p);
    }

    if (isSelected) drawBrackets(glowPaint);
    drawBrackets(paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => 
      old.isSelected != isSelected || old.opacity != opacity || old.color != color;
}

