import '../../models/daily_usage_stats.dart';

class UsageDerivedMetrics {
  final double focusScore;
  final double addictionScore;
  final String mostAddictiveAppPackage;
  final double productiveRatio;

  UsageDerivedMetrics({
    required this.focusScore,
    required this.addictionScore,
    required this.mostAddictiveAppPackage,
    required this.productiveRatio,
  });
}

class UsageMetricsProcessor {
  static const String productiveCategory = 'productive';
  static const String entertainmentCategory = 'entertainment';
  static const String generalCategory = 'general';

  static const Set<String> _productiveApps = {
    'com.android.chrome',
    'com.google.android.gm',
    'com.google.android.apps.docs',
    'com.google.android.apps.docs.editors.docs',
    'com.google.android.apps.docs.editors.sheets',
    'com.google.android.apps.docs.editors.slides',
    'com.microsoft.office.word',
    'com.microsoft.office.excel',
    'com.microsoft.office.powerpoint',
    'com.linkedin.android',
  };

  static const Set<String> _entertainmentApps = {
    'com.instagram.android',
    'com.google.android.youtube',
    'com.netflix.mediaclient',
    'com.zhiliaoapp.musically',
    'com.snapchat.android',
    'com.facebook.katana',
    'com.spotify.music',
    'com.reddit.frontpage',
  };

  static UsageDerivedMetrics derive(DailyUsageStats daily) {
    final totalAppUsage = _sumMap(daily.appUsage);
    final productiveUsage = _sumCategory(daily.appUsage, _productiveApps);
    final productiveRatio = totalAppUsage > 0 ? productiveUsage / totalAppUsage : 0.0;

    final screenHours = daily.screenTimeMs / const Duration(hours: 1).inMilliseconds;
    final lateNightHours = daily.lateNightUsageMs / const Duration(hours: 1).inMilliseconds;

    final unlockPenalty = (daily.unlockCount / 120.0).clamp(0.0, 1.0) * 22.0;
    final latePenalty = (lateNightHours / 2.5).clamp(0.0, 1.0) * 28.0;
    final screenPenalty = (screenHours / 10.0).clamp(0.0, 1.0) * 16.0;
    final productiveBoost = productiveRatio * 34.0;
    final focus = (58.0 + productiveBoost - unlockPenalty - latePenalty - screenPenalty).clamp(0.0, 100.0);

    final dominant = _dominantUsage(daily.appUsage);
    final dominantRatio = totalAppUsage > 0 ? dominant.value / totalAppUsage : 0.0;
    final addiction = (100.0 * (
            0.35 * (screenHours / 10.0).clamp(0.0, 1.0) +
            0.25 * (daily.unlockCount / 180.0).clamp(0.0, 1.0) +
            0.25 * dominantRatio.clamp(0.0, 1.0) +
            0.15 * (lateNightHours / 3.0).clamp(0.0, 1.0)))
        .clamp(0.0, 100.0);

    return UsageDerivedMetrics(
      focusScore: focus,
      addictionScore: addiction,
      mostAddictiveAppPackage: dominant.key,
      productiveRatio: productiveRatio,
    );
  }

  static String categorizeApp(String packageName) {
    if (_productiveApps.contains(packageName)) return productiveCategory;
    if (_entertainmentApps.contains(packageName)) return entertainmentCategory;
    return generalCategory;
  }

  static int _sumMap(Map<String, int> map) {
    var total = 0;
    for (final value in map.values) {
      total += value;
    }
    return total;
  }

  static int _sumCategory(Map<String, int> map, Set<String> category) {
    var total = 0;
    map.forEach((pkg, ms) {
      if (category.contains(pkg)) {
        total += ms;
      }
    });
    return total;
  }

  static MapEntry<String, int> _dominantUsage(Map<String, int> map) {
    var top = const MapEntry<String, int>('unknown.app', 0);
    for (final entry in map.entries) {
      if (entry.value > top.value) {
        top = entry;
      }
    }
    return top;
  }
}
