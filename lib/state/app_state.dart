import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class AppState extends ChangeNotifier {
  // Navigation
  int _currentTab = 0;
  int get currentTab => _currentTab;

  // Backend Analysis State
  AnalysisResponse? _analysisData;
  bool _isLoadingAnalysis = false;
  String? _analysisError;

  AnalysisResponse? get analysisData => _analysisData;
  bool get isLoadingAnalysis => _isLoadingAnalysis;
  String? get analysisError => _analysisError;

  void fetchAnalysisData() async {
    _isLoadingAnalysis = true;
    _analysisError = null;
    notifyListeners();

    try {
      print('Fetching analysis data from backend using local db...');
      final data = await BackendService.fetchAnalysis();
      if (data != null) {
        print(
          'Successfully fetched analysis data: ${data.dataPoints.length} points',
        );
        _analysisData = data;
      } else {
        print('Failed to load data from backend.');
        _analysisError =
            "Could not fetch data. The local database might be empty, or the backend is unreachable.";
      }
    } catch (e) {
      print('Error fetching analysis data: $e');
      _analysisError = e.toString();
    } finally {
      _isLoadingAnalysis = false;
      notifyListeners();
    }
  }

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
