import 'dart:convert';
import 'package:http/http.dart' as http;

import 'daily_usage_service.dart';
import 'usage/usage_metrics_processor.dart';

class BackendService {
  static const String baseUrl = 'http://10.86.166.33:8000/api/v1';

  static Future<AnalysisResponse?> fetchAnalysis() async {
    try {
      // Very Important: For new phones, forcefully fetch today's stats before checking local db
      await DailyUsageService.fetchAndStoreDailyStats();

      var records = await DailyUsageService.getStoredLastNDays(days: 14);
      if (records.isEmpty) {
        print('No local data available yet to analyze.');
        throw Exception(
          'No local usage data collected yet. Please use your phone normally to collect data first.',
        );
      }

      final List<Map<String, dynamic>> payload = records.map((record) {
        final metrics = UsageMetricsProcessor.derive(record);
        return {
          'day': record.day.day,
          'date':
              "${record.day.year}-${record.day.month.toString().padLeft(2, '0')}-${record.day.day.toString().padLeft(2, '0')}",
          'screen_time_min': record.screenTimeMs / 60000,
          'focus_score': metrics.focusScore,
          'addiction_score': metrics.addictionScore,
          'productive_ratio': metrics.productiveRatio,
          'unlock_count': record.unlockCount,
        };
      }).toList();

      final body = jsonEncode({
        'user_id': 'local_device',
        'data_points': payload,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/analysis/generate'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        return AnalysisResponse.fromJson(jsonDecode(response.body));
      } else {
        print(
          'Failed to analyze (HTTP ${response.statusCode}): ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error fetching analysis: $e');
      return null;
    }
  }
}

class AnalysisResponse {
  final List<DataPoint> dataPoints;
  final List<RegressionInfo> regression;
  final Personalization personalization;
  final String summary;

  AnalysisResponse({
    required this.dataPoints,
    required this.regression,
    required this.personalization,
    required this.summary,
  });

  factory AnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisResponse(
      dataPoints: (json['trends'] as List)
          .map((item) => DataPoint.fromJson(item))
          .toList(),
      regression: (json['regression'] as List)
          .map((item) => RegressionInfo.fromJson(item))
          .toList(),
      personalization: Personalization.fromJson(json['personalization']),
      summary: json['summary'] ?? '',
    );
  }
}

class DataPoint {
  final int day;
  final String date;
  final int screenTimeMin;
  final int focusScore;
  final int addictionScore;
  final double productiveRatio;
  final int unlockCount;

  DataPoint({
    required this.day,
    required this.date,
    required this.screenTimeMin,
    required this.focusScore,
    required this.addictionScore,
    required this.productiveRatio,
    required this.unlockCount,
  });

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      day: (json['day'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      screenTimeMin: (json['screen_time_min'] as num?)?.toInt() ?? 0,
      focusScore: (json['focus_score'] as num?)?.toInt() ?? 0,
      addictionScore: (json['addiction_score'] as num?)?.toInt() ?? 0,
      productiveRatio: (json['productive_ratio'] as num?)?.toDouble() ?? 0.0,
      unlockCount: (json['unlock_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class RegressionInfo {
  final String metric;
  final double slope;
  final double rSquared;
  final double predictedNext;
  final String direction;
  final String interpretation;

  RegressionInfo({
    required this.metric,
    required this.slope,
    required this.rSquared,
    required this.predictedNext,
    required this.direction,
    required this.interpretation,
  });

  factory RegressionInfo.fromJson(Map<String, dynamic> json) {
    return RegressionInfo(
      metric: json['metric']?.toString() ?? '',
      slope: (json['slope'] as num?)?.toDouble() ?? 0.0,
      rSquared: (json['r_squared'] as num?)?.toDouble() ?? 0.0,
      predictedNext: (json['predicted_next'] as num?)?.toDouble() ?? 0.0,
      direction: json['direction']?.toString() ?? '',
      interpretation: json['interpretation']?.toString() ?? '',
    );
  }
}

class Personalization {
  final String baselinePeriod;
  final double personalAvgScreenTime;
  final double personalAvgAddiction;
  final double personalAvgFocus;
  final String peakUsageDay;
  final String bestDay;
  final String worstDay;
  final List<String> improvementAreas;
  final List<String> strengths;

  Personalization({
    required this.baselinePeriod,
    required this.personalAvgScreenTime,
    required this.personalAvgAddiction,
    required this.personalAvgFocus,
    required this.peakUsageDay,
    required this.bestDay,
    required this.worstDay,
    required this.improvementAreas,
    required this.strengths,
  });

  factory Personalization.fromJson(Map<String, dynamic> json) {
    return Personalization(
      baselinePeriod: json['baseline_period']?.toString() ?? '',
      personalAvgScreenTime:
          (json['personal_avg_screen_time'] as num?)?.toDouble() ?? 0.0,
      personalAvgAddiction:
          (json['personal_avg_addiction'] as num?)?.toDouble() ?? 0.0,
      personalAvgFocus: (json['personal_avg_focus'] as num?)?.toDouble() ?? 0.0,
      peakUsageDay: json['peak_usage_day']?.toString() ?? '',
      bestDay: json['best_day']?.toString() ?? '',
      worstDay: json['worst_day']?.toString() ?? '',
      improvementAreas: List<String>.from(json['improvement_areas'] ?? []),
      strengths: List<String>.from(json['strengths'] ?? []),
    );
  }
}
