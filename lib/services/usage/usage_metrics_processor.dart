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

  // General apps are mixed-intent, so they contribute partially to productive behavior.
  static const double _generalProductiveWeight = 0.25; //bonus

  static const double _focusBaseline = 100.0;
  static const double _minimumFocusScore = 35.0;

  static const double _screenPenaltyWeight = 16.0;
  static const double _unlockPenaltyWeight = 24.0;
  static const double _lateNightPenaltyWeight = 30.0;
  
  static const double _productiveBonusWeight = 18.0; //bonus

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
    final entertainmentUsage = _sumCategory(daily.appUsage, _entertainmentApps);
    final generalUsage = (totalAppUsage - productiveUsage - entertainmentUsage).clamp(0, totalAppUsage);

    final weightedProductiveUsage = productiveUsage + (generalUsage * _generalProductiveWeight);
    final productiveRatio = totalAppUsage > 0 ? (weightedProductiveUsage / totalAppUsage).clamp(0.0, 1.0) : 0.0;

    final screenHours = daily.screenTimeMs / const Duration(hours: 1).inMilliseconds;
    final lateNightHours = daily.lateNightUsageMs / const Duration(hours: 1).inMilliseconds;

    // Allow more intentional usage before mild penalties kick in.
    final screenThresholdHours = 4.0 + (1.5 * productiveRatio);
    final screenOveruse = (screenHours - screenThresholdHours).clamp(0.0, double.infinity);

    // Frequent unlocks are a stronger distraction signal than total screen time.
    final expectedUnlocks = (12.0 + (screenHours * (12.0 - (2.0 * productiveRatio)))).clamp(20.0, 90.0);
    final unlockOveruse = (daily.unlockCount - expectedUnlocks).clamp(0.0, double.infinity);

    // Even modest late-night usage should matter more for focus quality.
    final lateNightThresholdHours = 0.25;
    final lateNightOveruse = (lateNightHours - lateNightThresholdHours).clamp(0.0, double.infinity);

    final screenPenalty = _softPenalty(screenOveruse, pivot: 2.0, maxPenalty: _screenPenaltyWeight);
    final unlockPenalty = _softPenalty(unlockOveruse, pivot: 35.0, maxPenalty: _unlockPenaltyWeight);
    final latePenalty = _softPenalty(lateNightOveruse, pivot: 1.2, maxPenalty: _lateNightPenaltyWeight);
    final productiveBoost = productiveRatio * _productiveBonusWeight;

    final focus = (_focusBaseline + productiveBoost - screenPenalty - unlockPenalty - latePenalty)
        .clamp(_minimumFocusScore, 100.0);

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

  static double _softPenalty(
    double overage, {
    required double pivot,
    required double maxPenalty,
  }) {
    if (overage <= 0) return 0.0;
    final scaled = overage / (overage + pivot);
    return scaled * maxPenalty;
  }
}
