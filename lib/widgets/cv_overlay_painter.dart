import 'package:flutter/material.dart';

class DetectedSign {
  final String text;
  final Rect boundingBox; // in screen coordinates
  final bool isTarget;    // true = this is what the user needs

  DetectedSign({
    required this.text,
    required this.boundingBox,
    required this.isTarget,
  });
}

class CVOverlayPainter extends CustomPainter {
  final List<DetectedSign> signs;
  final double pulseValue; // 0.0–1.0, driven by AnimationController

  CVOverlayPainter({required this.signs, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final sign in signs) {
      if (sign.isTarget) {
        // Green pulsing border for the target sign
        final paint = Paint()
          ..color = const Color(0xFF4CAF50).withOpacity(0.5 + pulseValue * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(sign.boundingBox, const Radius.circular(8)),
          paint,
        );

        // Filled teal label bubble above the box
        final bubbleRect = Rect.fromLTWH(
          sign.boundingBox.left,
          sign.boundingBox.top - 30,
          sign.boundingBox.width,
          26,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bubbleRect, const Radius.circular(6)),
          Paint()..color = const Color(0xFF1D9E75),
        );

        // Label text
        final tp = TextPainter(
          text: TextSpan(
            text: '→ Votre guichet',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: sign.boundingBox.width - 8);
        tp.paint(canvas, Offset(
          sign.boundingBox.left + 8,
          sign.boundingBox.top - 26,
        ));

        // Pulsing arrow pointing down toward the box
        _drawArrow(canvas, sign.boundingBox, pulseValue);

      } else {
        // Gray border for irrelevant signs
        canvas.drawRRect(
          RRect.fromRectAndRadius(sign.boundingBox, const Radius.circular(6)),
          Paint()
            ..color = Colors.white.withOpacity(0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawArrow(Canvas canvas, Rect box, double pulse) {
    final cx = box.center.dx;
    final top = box.top - 36 - pulse * 8; // bounces up/down

    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(cx, top)
      ..lineTo(cx, top + 18)
      ..moveTo(cx - 8, top + 10)
      ..lineTo(cx, top + 18)
      ..lineTo(cx + 8, top + 10);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CVOverlayPainter old) =>
    old.signs != signs || old.pulseValue != pulseValue;
}
