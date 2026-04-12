import 'dart:math';

import '../models/daily_usage_stats.dart';
import 'usage/daily_usage_fetcher.dart';
import 'usage/daily_usage_local_storage.dart';

class DailyUsageService {
  static final DailyUsageFetcher _fetcher = DailyUsageFetcher();
  static final DailyUsageLocalStorage _storage = DailyUsageLocalStorage();

  static Future<bool> hasUsagePermission() async {
    return _fetcher.hasUsagePermission();
  }

  static Future<void> openUsageSettings() async {
    await _fetcher.openUsageSettings();
  }

  static Future<DailyUsageStats?> fetchAndStoreDailyStats({DateTime? day}) async {
    final now = DateTime.now();
    final selectedDay = DateTime(
      day?.year ?? now.year,
      day?.month ?? now.month,
      day?.day ?? now.day,
    );

    final hasPermission = await hasUsagePermission();
    if (!hasPermission) {
      return null;
    }

    final startTime = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    ).millisecondsSinceEpoch;
    final endOfDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;
    final endTime = min(DateTime.now().millisecondsSinceEpoch, endOfDay);
    if (endTime <= startTime) return null;

    final response = await _fetcher.getDailyUsageStats(
      startTime: startTime,
      endTime: endTime,
    );

    if (response == null) return null;

    final stats = DailyUsageStats.fromChannelMap(day: selectedDay, map: response);
    await _storage.upsert(stats);
    return stats;
  }

  static Future<DailyUsageStats?> getStoredDailyStats({DateTime? day}) async {
    final now = DateTime.now();
    final selectedDay = DateTime(
      day?.year ?? now.year,
      day?.month ?? now.month,
      day?.day ?? now.day,
    );
    return _storage.getByDay(selectedDay);
  }

  static Future<List<DailyUsageStats>> getStoredLastNDays({
    DateTime? endDay,
    int days = 7,
  }) async {
    final now = DateTime.now();
    final selectedEnd = DateTime(
      endDay?.year ?? now.year,
      endDay?.month ?? now.month,
      endDay?.day ?? now.day,
    );
    return _storage.getLastNDays(selectedEnd, days);
  }

  static String formatDurationMs(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }

  static String displayAppName(String packageName) {
    final parts = packageName.split('.').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return packageName;
    final last = parts.last.replaceAll(RegExp(r'[_-]+'), ' ');
    if (last.isEmpty) return packageName;
    return last
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((word) => word.length == 1
            ? word.toUpperCase()
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }
}
