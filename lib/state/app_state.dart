import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  // Navigation
  int _currentTab = 0;
  int get currentTab => _currentTab;

  void setTab(int index) {
    _currentTab = index;
    notifyListeners();
  }

  // Focus Mode
  bool _isFocusModeActive = false;
  bool get isFocusModeActive => _isFocusModeActive;

  void toggleFocusMode() {
    _isFocusModeActive = !_isFocusModeActive;
    notifyListeners();
  }

  // Recommendations
  final Set<String> _dismissedRecommendations = {};

  bool isDismissed(String id) {
    return _dismissedRecommendations.contains(id);
  }

  void dismissRecommendation(String id) {
    _dismissedRecommendations.add(id);
    notifyListeners();
  }
}
