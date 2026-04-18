import 'package:flutter/services.dart';

class DailyUsageFetcher {
  static const MethodChannel _channel = MethodChannel(
    'com.example.screen_therapist/daily_usage',
  );

  Future<bool> hasUsagePermission() async {
    final value = await _channel.invokeMethod<bool>('hasUsagePermission');
    return value ?? false;
  }

  Future<void> openUsageSettings() async {
    await _channel.invokeMethod('openUsageSettings');
  }

  Future<Map<dynamic, dynamic>?> getDailyUsageStats({
    required int startTime,
    required int endTime,
  }) async {
    return _channel.invokeMethod<Map<dynamic, dynamic>>(
      'getDailyUsageStats',
      <String, dynamic>{'startTime': startTime, 'endTime': endTime},
    );
  }
}
