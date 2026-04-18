import 'package:flutter/material.dart';

import '../services/screen_time_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/top_nav.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

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

              final topApps = data.todayApps.take(3).toList();
              final keyInsight = _buildKeyInsight(data);
              final quickAction = _buildQuickAction(data);

              return ListView(
                padding: const EdgeInsets.only(
                  top: 100,
                  bottom: 120,
                  left: 20,
                  right: 20,
                ),
                children: [
                  _FocusScoreCard(score: data.focusScore.round()),
                  const SizedBox(height: 16),
                  _TodayStatsRow(
                    screenTimeToday: data.todayScreenTime,
                    unlockCountToday: data.todayUnlocks,
                    lateNightUsage: data.lateNightUsage,
                  ),
                  const SizedBox(height: 16),
                  _TopAppsCard(topApps: topApps),
                  const SizedBox(height: 16),
                  _MessageCard(
                    title: 'Key Insight',
                    text: keyInsight,
                    icon: Icons.lightbulb_outline_rounded,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 12),
                  _MessageCard(
                    title: 'Quick Action',
                    text: quickAction,
                    icon: Icons.bolt_rounded,
                    color: AppTheme.secondary,
                  ),
                ],
              );
            },
          ),
          const Positioned(top: 0, left: 0, right: 0, child: TopNavRoute()),
        ],
      ),
    );
  }

  static String _buildKeyInsight(ScreenTimeData data) {
    if (data.lateNightUsage.inMinutes > 30) {
      return 'High late-night usage is reducing your focus score.';
    }
    if (data.todayUnlocks > (data.weeklyUnlocks / 7.0) * 1.2) {
      return 'Frequent unlocks indicate increased distraction today.';
    }
    if (data.productiveRatio < 0.4) {
      return 'Entertainment usage is dominating your phone time today.';
    }
    return 'Your usage pattern is more balanced than your weekly average.';
  }

  static String _buildQuickAction(ScreenTimeData data) {
    final topEntertainment = data.todayApps.firstWhere(
      (a) => a.category == 'entertainment',
      orElse: () => AppUsageInfo(
        'unknown',
        Duration.zero,
        displayName: 'entertainment apps',
        category: 'entertainment',
      ),
    );

    if (data.lateNightUsage.inMinutes > 30) {
      return 'Set bedtime mode for 11 PM and avoid ${topEntertainment.name} after that.';
    }
    if (data.todayUnlocks > (data.weeklyUnlocks / 7.0) * 1.2) {
      return 'Turn off non-essential notifications for the next 2 hours.';
    }
    if (data.productiveRatio < 0.4) {
      return 'Start with one productive task before opening ${topEntertainment.name}.';
    }
    return 'Keep your current routine and repeat it tomorrow.';
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
              Text(
                'No real usage data available',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Grant usage access to view today\'s live metrics.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: ScreenTimeService.promptPermission,
                child: const Text('Open Usage Access Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusScoreCard extends StatelessWidget {
  final int score;

  const _FocusScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(score);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            'How Are You Doing Today?',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.95),
                width: 10,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$score',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'FOCUS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(int score) {
    if (score >= 70) return AppTheme.secondary;
    if (score >= 40) return const Color(0xFFFFCB4A);
    return AppTheme.error;
  }
}

class _TodayStatsRow extends StatelessWidget {
  final Duration screenTimeToday;
  final int unlockCountToday;
  final Duration lateNightUsage;

  const _TodayStatsRow({
    required this.screenTimeToday,
    required this.unlockCountToday,
    required this.lateNightUsage,
  });

  @override
  Widget build(BuildContext context) {
    final lateNightHigh = lateNightUsage.inMinutes > 30;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: 'Screen Time',
              value: _formatDuration(screenTimeToday),
              valueColor: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Unlocks',
              value: '$unlockCountToday',
              valueColor: AppTheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Late Night',
              value: _formatDuration(lateNightUsage),
              valueColor: lateNightHigh ? AppTheme.error : AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.outlineVariant),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TopAppsCard extends StatelessWidget {
  final List<AppUsageInfo> topApps;

  const _TopAppsCard({required this.topApps});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Apps Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (topApps.isEmpty)
            Text(
              'No app activity available.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
            )
          else
            ...topApps.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TopAppRow(app: app),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopAppRow extends StatelessWidget {
  final AppUsageInfo app;

  const _TopAppRow({required this.app});

  @override
  Widget build(BuildContext context) {
    final category = app.category == 'general' ? 'neutral' : app.category;
    final categoryColor = _categoryColor(category);

    return Row(
      children: [
        Expanded(
          child: Text(
            app.name,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _formatDuration(app.usage),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurface),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: categoryColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'productive':
        return AppTheme.secondary;
      case 'entertainment':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  const _MessageCard({
    required this.title,
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.outlineVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
