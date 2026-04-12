import 'package:flutter/foundation.dart';

import '../models/daily_usage_stats.dart';
import 'daily_usage_service.dart';
import 'usage/usage_metrics_processor.dart';

class ScreenTimeData {
  final Duration todayScreenTime;
  final Duration weeklyScreenTime;
  final int weeklyUnlocks;
  final int todayUnlocks;
  final Duration lateNightUsage;
  final double productiveRatio;
  final String mostAddictiveApp;
  final List<AppUsageInfo> todayApps;
  final List<AppUsageInfo> weeklyApps;
  final double focusScore;
  final double addictionScore;
  final List<double> weeklyTrends;
  final String updatedAtIndiaLabel;
  final String trackingStartedIndiaLabel;

  ScreenTimeData({
    required this.todayScreenTime,
    required this.weeklyScreenTime,
    required this.weeklyUnlocks,
    required this.todayUnlocks,
    required this.lateNightUsage,
    required this.productiveRatio,
    required this.mostAddictiveApp,
    required this.todayApps,
    required this.weeklyApps,
    required this.focusScore,
    required this.addictionScore,
    required this.weeklyTrends,
    required this.updatedAtIndiaLabel,
    required this.trackingStartedIndiaLabel,
  });
}

class ScreenTimeService {
  static const Duration _indiaOffset = Duration(hours: 5, minutes: 30);
  static final DateTime _sessionOpenedUtc = DateTime.now().toUtc();

  static const Map<String, String> _knownAppNames = {
    'com.instagram.android': 'Instagram',
    'com.whatsapp': 'WhatsApp',
    'com.google.android.youtube': 'YouTube',
    'com.google.android.apps.youtube.music': 'YouTube Music',
    'com.android.chrome': 'Chrome',
    'com.google.android.googlequicksearchbox': 'Google',
    'com.facebook.katana': 'Facebook',
    'com.facebook.orca': 'Messenger',
    'com.twitter.android': 'X',
    'com.linkedin.android': 'LinkedIn',
    'com.snapchat.android': 'Snapchat',
    'org.telegram.messenger': 'Telegram',
    'in.startv.hotstar': 'Disney+ Hotstar',
    'com.netflix.mediaclient': 'Netflix',
    'com.spotify.music': 'Spotify',
    'com.amazon.mShop.android.shopping': 'Amazon',
    'com.flipkart.android': 'Flipkart',
    'com.zhiliaoapp.musically': 'TikTok',
    'com.reddit.frontpage': 'Reddit',
    'com.google.android.gm': 'Gmail',
    'com.google.android.apps.maps': 'Google Maps',
  };

  static DateTime _nowUtc() => DateTime.now().toUtc();

  static DateTime _toIndiaTime(DateTime dateTime) {
    return dateTime.toUtc().add(_indiaOffset);
  }

  static String _formatIndiaTime(DateTime dateTime) {
    final india = _toIndiaTime(dateTime);
    final hour12 = india.hour % 12 == 0 ? 12 : india.hour % 12;
    final minute = india.minute.toString().padLeft(2, '0');
    final meridiem = india.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $meridiem IST';
  }

  static String humanReadableAppName(String packageName) {
    final normalized = packageName.trim().toLowerCase();
    if (_knownAppNames.containsKey(normalized)) {
      return _knownAppNames[normalized]!;
    }

    final ignoredTokens = <String>{
      'com', 'org', 'net', 'in', 'co', 'io', 'android', 'apps', 'app', 'mobile', 'lite'
    };

    final rawParts = packageName.split('.').where((p) => p.isNotEmpty).toList();
    final candidateParts = rawParts.where((p) => !ignoredTokens.contains(p.toLowerCase())).toList();
    final picked = (candidateParts.isNotEmpty ? candidateParts.last : rawParts.isNotEmpty ? rawParts.last : packageName)
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\d+'), ' ')
        .trim();

    if (picked.isEmpty) return packageName;

    return picked
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  static Future<bool> isPermissionGranted() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    return DailyUsageService.hasUsagePermission();
  }

  static Future<void> promptPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await DailyUsageService.openUsageSettings();
  }

  static Future<ScreenTimeData?> getMetrics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _getMockData();
    }

    final hasPermission = await DailyUsageService.hasUsagePermission();
    if (!hasPermission) return null;

    final today = DateTime.now();

    final todayRaw = await DailyUsageService.fetchAndStoreDailyStats(day: today) ??
        await DailyUsageService.getStoredDailyStats(day: today);
    if (todayRaw == null) return null;

    final weekData = <DailyUsageStats>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
      final raw = await DailyUsageService.getStoredDailyStats(day: day) ??
          await DailyUsageService.fetchAndStoreDailyStats(day: day);
      if (raw != null) {
        weekData.add(raw);
      }
    }

    final weeklyScreenTimeMs = weekData.fold<int>(0, (sum, d) => sum + d.screenTimeMs);
    final weeklyUnlocks = weekData.fold<int>(0, (sum, d) => sum + d.unlockCount);

    final weeklyAppUsage = <String, int>{};
    for (final day in weekData) {
      day.appUsage.forEach((pkg, ms) {
        weeklyAppUsage[pkg] = (weeklyAppUsage[pkg] ?? 0) + ms;
      });
    }

    final metrics = UsageMetricsProcessor.derive(todayRaw);
    final trends = _buildWeeklyTrends(weekData);

    final todayApps = _toAppUsageInfoList(todayRaw.appUsage).take(10).toList();
    final weeklyApps = _toAppUsageInfoList(weeklyAppUsage).take(10).toList();

    return ScreenTimeData(
      todayScreenTime: Duration(milliseconds: todayRaw.screenTimeMs),
      weeklyScreenTime: Duration(milliseconds: weeklyScreenTimeMs),
      weeklyUnlocks: weeklyUnlocks,
      todayUnlocks: todayRaw.unlockCount,
      lateNightUsage: Duration(milliseconds: todayRaw.lateNightUsageMs),
      productiveRatio: metrics.productiveRatio,
      mostAddictiveApp: humanReadableAppName(metrics.mostAddictiveAppPackage),
      todayApps: todayApps,
      weeklyApps: weeklyApps,
      focusScore: metrics.focusScore,
      addictionScore: metrics.addictionScore,
      weeklyTrends: trends,
      updatedAtIndiaLabel: _formatIndiaTime(_nowUtc()),
      trackingStartedIndiaLabel: _formatIndiaTime(_sessionOpenedUtc),
    );
  }

  static List<double> _buildWeeklyTrends(List<DailyUsageStats> weekData) {
    final values = weekData.map((e) => e.screenTimeMs.toDouble()).toList();
    if (values.isEmpty) return List<double>.filled(7, 0.0);

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return List<double>.filled(7, 0.0);

    final normalized = values.map((v) => (v / maxValue).clamp(0.0, 1.0)).toList();
    if (normalized.length == 7) return normalized;

    final padded = List<double>.filled(7 - normalized.length, 0.0)..addAll(normalized);
    return padded;
  }

  static List<AppUsageInfo> _toAppUsageInfoList(Map<String, int> usageMap) {
    final list = usageMap.entries
        .map((entry) => AppUsageInfo(
              entry.key,
              Duration(milliseconds: entry.value),
              displayName: humanReadableAppName(entry.key),
              category: UsageMetricsProcessor.categorizeApp(entry.key),
            ))
        .toList();
    list.sort((a, b) => b.usage.compareTo(a.usage));
    return list;
  }

  static ScreenTimeData _getMockData() {
    return ScreenTimeData(
      todayScreenTime: const Duration(hours: 4, minutes: 20),
      weeklyScreenTime: const Duration(hours: 32, minutes: 15),
      weeklyUnlocks: 342,
      todayUnlocks: 48,
      lateNightUsage: const Duration(minutes: 54),
      productiveRatio: 0.42,
      mostAddictiveApp: 'Instagram',
      todayApps: [
        AppUsageInfo('com.instagram.android', const Duration(hours: 2), category: 'entertainment'),
        AppUsageInfo('com.android.chrome', const Duration(minutes: 45), category: 'productive'),
        AppUsageInfo('com.google.android.youtube', const Duration(hours: 1, minutes: 35), category: 'entertainment'),
      ],
      weeklyApps: [],
      focusScore: 68.0,
      addictionScore: 45.0,
      weeklyTrends: [0.3, 0.6, 0.4, 0.8, 1.0, 0.5, 0.7],
      updatedAtIndiaLabel: _formatIndiaTime(_nowUtc()),
      trackingStartedIndiaLabel: _formatIndiaTime(_sessionOpenedUtc),
    );
  }
}

class AppUsageInfo {
  final String packageName;
  final Duration usage;
  final String displayName;
  final String category;

  AppUsageInfo(
    this.packageName,
    this.usage, {
    String? displayName,
    this.category = 'neutral',
  }) : displayName = displayName ?? ScreenTimeService.humanReadableAppName(packageName);

  String get name => displayName;
}
