import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ARNavigationService {
  double _compassHeading = 0.0;
  double _pitch = 0.0;
  double _roll = 0.0;

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;

  Function(double heading)? onHeadingChanged;
  Function(double pitch, double roll)? onOrientationChanged;

  double get compassHeading => _compassHeading;
  double get pitch => _pitch;
  double get roll => _roll;

  void startListening() {
    _compassSub = FlutterCompass.events?.listen((event) {
      _compassHeading = event.heading ?? 0.0;
      onHeadingChanged?.call(_compassHeading);
    });

    _accelerometerSub = accelerometerEventStream().listen((event) {
      _pitch = math.atan2(event.y, event.z) * 180 / math.pi;
      _roll = math.atan2(event.x, event.z) * 180 / math.pi;
      onOrientationChanged?.call(_pitch, _roll);
    });
  }

  double calculateArrowAngle({
    required double targetNormalizedX,
    required double targetNormalizedY,
  }) {
    const centerX = 0.5;
    const centerY = 0.5;
    final dx = targetNormalizedX - centerX;
    final dy = targetNormalizedY - centerY;
    final angle = math.atan2(dx, -dy) * 180 / math.pi;
    return angle;
  }

  bool isTargetInView({
    required double targetNormalizedX,
    required double targetNormalizedY,
    double margin = 0.05,
  }) {
    return targetNormalizedX >= margin &&
        targetNormalizedX <= (1 - margin) &&
        targetNormalizedY >= margin &&
        targetNormalizedY <= (1 - margin);
  }

  double distanceFromCenter({
    required double targetNormalizedX,
    required double targetNormalizedY,
  }) {
    final dx = targetNormalizedX - 0.5;
    final dy = targetNormalizedY - 0.5;
    return math.sqrt(dx * dx + dy * dy) * 2;
  }

  void dispose() {
    _compassSub?.cancel();
    _accelerometerSub?.cancel();
  }
}
