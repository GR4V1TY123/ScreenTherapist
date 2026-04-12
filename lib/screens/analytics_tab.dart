import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/top_nav.dart';
import '../widgets/glass_card.dart';
import '../services/screen_time_service.dart';

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
               if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("Missing Access Permissions. Return to Home to grant."));
               }

               final data = snapshot.data!;
               return ListView(
                padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
                children: [
                  const Text('Deep Analytics', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Analyzing your neural habit data.', style: TextStyle(color: AppTheme.outlineVariant)),
                    const SizedBox(height: 4),
                    Text(
                      'Updated ${data.updatedAtIndiaLabel} | Tracking since ${data.trackingStartedIndiaLabel}',
                      style: TextStyle(color: AppTheme.outlineVariant, fontSize: 12),
                    ),
                  const SizedBox(height: 32),
                  
                  // Scores Row
                  Row(
                    children: [
                       Expanded(child: _ScoreCard(title: 'Focus Score', score: data.focusScore, color: AppTheme.secondary)),
                       const SizedBox(width: 16),
                       Expanded(child: _ScoreCard(title: 'Addiction Risk', score: data.addictionScore, color: AppTheme.error)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Weekly Stats Box
                  GlassCard(
                    child: Column(
                      children: [
                         _StatRow(label: 'Weekly Screen Time', val: '${data.weeklyScreenTime.inHours}h ${data.weeklyScreenTime.inMinutes % 60}m'),
                         const Divider(color: Colors.white10, height: 32),
                         _StatRow(label: 'Weekly Phone Unlocks', val: '${data.weeklyUnlocks}x'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text('Weekly Trend', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _WeeklyChart(data: data.weeklyTrends),
                  const SizedBox(height: 40),

                  Text('App Usage Today', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _AppBreakdownList(apps: data.todayApps),
                ],
              );
            }
          ),
          const Positioned(top: 0, left: 0, right: 0, child: TopNavRoute()),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final Color color;

  const _ScoreCard({required this.title, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
     return GlassCard(
       padding: const EdgeInsets.all(20),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.outlineVariant)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${score.toInt()}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('/100', style: TextStyle(fontSize: 12, color: Colors.white54)),
                )
              ],
            )
         ],
       )
     );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String val;

  const _StatRow({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(val, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> data;
  const _WeeklyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return GlassCard(
      child: SizedBox(
        height: 150,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            double val = index < data.length ? data[index] : 0.5;
            final isHigh = val > 0.7; 
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 16,
                  height: 150 * val,
                  decoration: BoxDecoration(
                    color: isHigh ? AppTheme.error.withValues(alpha: 0.8) : AppTheme.secondary.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                        BoxShadow(
                          color: (isHigh ? AppTheme.error : AppTheme.secondary).withValues(alpha: 0.2),
                          blurRadius: 10,
                        )
                    ]
                  ),
                ),
                const SizedBox(height: 12),
                Text(labels[index], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.outlineVariant)),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _AppBreakdownList extends StatelessWidget {
  final List<AppUsageInfo> apps;
  const _AppBreakdownList({required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
        return const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text("No apps recorded today yet.")
        ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: apps.map((app) {
         final maxMins = apps.first.usage.inMinutes.toDouble();
         final percentage = maxMins > 0 ? (app.usage.inMinutes / maxMins).clamp(0.0, 1.0) : 0.0;
         
         return Padding(
           padding: const EdgeInsets.only(bottom: 16),
           child: _AppUsageItem(
             name: app.name,
             time: '${app.usage.inHours}h ${app.usage.inMinutes % 60}m',
             percentage: percentage,
             color: AppTheme.primary,
           ),
         );
      }).toList(),
    );
  }
}

class _AppUsageItem extends StatelessWidget {
  final String name;
  final String time;
  final double percentage;
  final Color color;

  const _AppUsageItem({required this.name, required this.time, required this.percentage, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Text(time, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
