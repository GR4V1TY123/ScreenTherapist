import 'package:flutter/material.dart';

import '../services/screen_time_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/top_nav.dart';

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          FutureBuilder<ScreenTimeData?>(
            future: ScreenTimeService.getMetrics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data;
              if (data == null) {
                return const _UnavailableState();
              }

              final categoryBreakdown = _buildCategoryPercent(data.todayCategoryUsage);
              final lateNightInsight = _buildLateNightInsight(data.lateNightUsage);

              return ListView(
                padding: const EdgeInsets.only(top: 100, bottom: 120, left: 20, right: 20),
                children: [
                  Text('Analytics', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'What are my usage patterns?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Weekly Screen Time Trend'),
                  const SizedBox(height: 10),
                  _WeeklyScreenTimeCard(values: data.weeklyTrends),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Focus Score Trend'),
                  const SizedBox(height: 10),
                  _FocusIndicatorCard(currentFocus: data.focusScore),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Usage Breakdown'),
                  const SizedBox(height: 10),
                  _UsageBreakdownCard(breakdown: categoryBreakdown),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Top Apps (Weekly)'),
                  const SizedBox(height: 10),
                  _TopAppsWeeklyCard(apps: data.weeklyApps),
                  const SizedBox(height: 16),
                  const _SectionTitle(title: 'Late Night Pattern Insight'),
                  const SizedBox(height: 10),
                  _InsightCard(text: lateNightInsight),
                ],
              );
            },
          ),
          const Positioned(top: 0, left: 0, right: 0, child: TopNavRoute()),
        ],
      ),
    );
  }

  static Map<String, double> _buildCategoryPercent(Map<String, Duration> usage) {
    final productive = usage['productive']?.inMinutes.toDouble() ?? 0;
    final entertainment = usage['entertainment']?.inMinutes.toDouble() ?? 0;
    final general = usage['general']?.inMinutes.toDouble() ?? 0;
    final total = productive + entertainment + general;

    if (total <= 0) {
      return {
        'productive': 0,
        'entertainment': 0,
        'neutral': 0,
      };
    }

    return {
      'productive': (productive / total) * 100,
      'entertainment': (entertainment / total) * 100,
      'neutral': (general / total) * 100,
    };
  }

  static String _buildLateNightInsight(Duration lateNightUsage) {
    if (lateNightUsage.inMinutes == 0) {
      return 'No late-night usage detected today.';
    }
    if (lateNightUsage.inMinutes >= 60) {
      return 'High usage during late-night hours suggests sleep-disrupting behavior.';
    }
    return 'Some late-night usage detected; reducing it may improve next-day focus.';
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 42),
              const SizedBox(height: 10),
              Text('No real analytics data available', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Grant usage access to view live analytics patterns.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: ScreenTimeService.promptPermission,
                child: const Text('Open Usage Access Settings'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _WeeklyScreenTimeCard extends StatelessWidget {
  final List<double> values;

  const _WeeklyScreenTimeCard({required this.values});

  @override
  Widget build(BuildContext context) {
    final safe = _safeSeven(values);
    final start = safe.first;
    final end = safe.last;
    final isUp = end > start;
    final delta = (end - start).abs() * 100;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last 7 days', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant)),
              Text(
                '${isUp ? '↑' : '↓'} ${delta.toStringAsFixed(0)}% relative',
                style: TextStyle(color: isUp ? AppTheme.error : AppTheme.secondary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final maxVal = safe.reduce((a, b) => a > b ? a : b);
                final normalized = maxVal > 0 ? safe[index] / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      height: 24 + (normalized * 88),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusIndicatorCard extends StatelessWidget {
  final double currentFocus;

  const _FocusIndicatorCard({required this.currentFocus});

  @override
  Widget build(BuildContext context) {
    final value = currentFocus.clamp(0, 100).toDouble();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Focus Score', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant)),
              Text('${value.toStringAsFixed(0)}/100', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: value / 100,
            minHeight: 8,
            color: AppTheme.secondary,
            backgroundColor: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(99),
          )
        ],
      ),
    );
  }
}

class _UsageBreakdownCard extends StatelessWidget {
  final Map<String, double> breakdown;

  const _UsageBreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final productive = (breakdown['productive'] ?? 0).clamp(0, 100).toDouble();
    final entertainment = (breakdown['entertainment'] ?? 0).clamp(0, 100).toDouble();
    final neutral = (breakdown['neutral'] ?? 0).clamp(0, 100).toDouble();

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          _RatioRow(label: 'Productive', value: productive, color: AppTheme.secondary),
          const SizedBox(height: 10),
          _RatioRow(label: 'Entertainment', value: entertainment, color: AppTheme.error),
          const SizedBox(height: 10),
          _RatioRow(label: 'Neutral', value: neutral, color: AppTheme.primary),
        ],
      ),
    );
  }
}

class _RatioRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _RatioRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final widthFactor = (value / 100).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${value.toStringAsFixed(0)}%')],
        ),
        const SizedBox(height: 6),
        Container(
          height: 8,
          decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(99)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFactor,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopAppsWeeklyCard extends StatelessWidget {
  final List<AppUsageInfo> apps;

  const _TopAppsWeeklyCard({required this.apps});

  @override
  Widget build(BuildContext context) {
    final sorted = [...apps]..sort((a, b) => b.usage.compareTo(a.usage));
    final totalMinutes = sorted.fold<double>(0, (sum, app) => sum + app.usage.inMinutes);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (sorted.isEmpty)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('No weekly app usage available.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant)),
            )
          else
            ...sorted.take(8).map((app) {
              final pct = totalMinutes > 0 ? (app.usage.inMinutes / totalMinutes) * 100 : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TopAppWeeklyRow(
                  name: app.name,
                  usage: _formatDuration(app.usage),
                  percentage: pct,
                ),
              );
            }),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}m';
  }
}

class _TopAppWeeklyRow extends StatelessWidget {
  final String name;
  final String usage;
  final double percentage;

  const _TopAppWeeklyRow({required this.name, required this.usage, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 10),
        Text(usage),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: TextStyle(color: AppTheme.outlineVariant),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;

  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.nightlight_round, color: AppTheme.error, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

List<double> _safeSeven(List<double> values) {
  if (values.isEmpty) return List<double>.filled(7, 0.0);
  if (values.length >= 7) return values.take(7).toList();
  return [...values, ...List<double>.filled(7 - values.length, 0.0)];
}
