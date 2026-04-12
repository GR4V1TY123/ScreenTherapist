import 'dart:convert';

class DailyUsageStats {
  final DateTime day;
  final int screenTimeMs;
  final int unlockCount;
  final int lateNightUsageMs;
  final Map<String, int> appUsage;

  DailyUsageStats({
    required this.day,
    required this.screenTimeMs,
    required this.unlockCount,
    required this.lateNightUsageMs,
    required this.appUsage,
  });

  factory DailyUsageStats.fromChannelMap({
    required DateTime day,
    required Map<dynamic, dynamic> map,
  }) {
    final rawAppUsage = (map['appUsage'] as Map?) ?? const {};
    final appUsage = <String, int>{};

    rawAppUsage.forEach((key, value) {
      appUsage[key.toString()] = _asInt(value);
    });

    return DailyUsageStats(
      day: DateTime(day.year, day.month, day.day),
      screenTimeMs: _asInt(map['screenTime']),
      unlockCount: _asInt(map['unlockCount']),
      lateNightUsageMs: _asInt(map['lateNightUsage']),
      appUsage: appUsage,
    );
  }

  factory DailyUsageStats.fromDbMap(Map<String, Object?> map) {
    final appUsage = <String, int>{};
    final raw = (map['app_usage_json'] as String?) ?? '';
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((key, value) {
            appUsage[key] = _asInt(value);
          });
        }
      } catch (_) {
        // Backward compatibility for earlier delimiter format.
        for (final pair in raw.split('||')) {
          if (pair.isEmpty || !pair.contains('::')) continue;
          final parts = pair.split('::');
          if (parts.length != 2) continue;
          appUsage[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
    }

    final dayKey = (map['day_key'] as String?) ?? '1970-01-01';
    final parts = dayKey.split('-');
    final parsedDay = parts.length == 3
        ? DateTime(
            int.tryParse(parts[0]) ?? 1970,
            int.tryParse(parts[1]) ?? 1,
            int.tryParse(parts[2]) ?? 1,
          )
        : DateTime(1970, 1, 1);

    return DailyUsageStats(
      day: parsedDay,
      screenTimeMs: (map['screen_time_ms'] as int?) ?? 0,
      unlockCount: (map['unlock_count'] as int?) ?? 0,
      lateNightUsageMs: (map['late_night_usage_ms'] as int?) ?? 0,
      appUsage: appUsage,
    );
  }

  Map<String, Object?> toDbMap() {
    final encoded = jsonEncode(appUsage);
    return {
      'day_key': dayKey,
      'screen_time_ms': screenTimeMs,
      'unlock_count': unlockCount,
      'late_night_usage_ms': lateNightUsageMs,
      'app_usage_json': encoded,
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
  }

  String get dayKey {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<MapEntry<String, int>> get topAppsSorted {
    final list = appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  int get totalAppUsageMs {
    var total = 0;
    for (final value in appUsage.values) {
      total += value;
    }
    return total;
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
