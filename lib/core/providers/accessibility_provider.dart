import 'package:flutter/material.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool voiceMode = false;     // Visual mode → voice reading
  bool simpleMode = false;    // Simple mode → simplified text
  bool mobilityMode = false;  // Mobility mode → focus on time + navigation

  void toggleVoiceMode(bool value) {
    voiceMode = value;
    notifyListeners();
  }

  void toggleSimpleMode(bool value) {
    simpleMode = value;
    notifyListeners();
  }

  void toggleMobilityMode(bool value) {
    mobilityMode = value;
    notifyListeners();
  }
}