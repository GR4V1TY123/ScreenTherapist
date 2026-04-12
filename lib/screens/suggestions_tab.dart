import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/top_nav.dart';
import '../widgets/glass_card.dart';

class SuggestionsTab extends StatelessWidget {
  const SuggestionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 80, bottom: 120, left: 24, right: 24),
            children: const [
              _HeaderSection(),
              SizedBox(height: 40),
              _DailyChallengeCard(),
              SizedBox(height: 40),
              _BentoGrid(),
              SizedBox(height: 40),
              _ImprovementTips(),
            ],
          ),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopNavRoute(),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Smart Suggestions', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40)),
        const SizedBox(height: 8),
        Text('Personalized digital wellness roadmap based on your AI insights', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.outlineVariant)),
      ],
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard();

  @override
  Widget build(BuildContext context) {
    final isFocusModeActive = context.watch<AppState>().isFocusModeActive;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.emoji_events, size: 120, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TODAY's QUEST", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.secondary)),
                      Text("Digital Sunset", style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
                    ),
                    child: Text('+250 XP', style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("No screen time for 2 hours before bed", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.onSurface.withValues(alpha: 0.7))),
                  Text("75%", style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.secondary)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    width: isFocusModeActive ? constraints.maxWidth : constraints.maxWidth * 0.75,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.secondary, AppTheme.secondaryContainer]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.4), blurRadius: 12)],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.read<AppState>().toggleFocusMode(),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Center(
                          child: Text(
                            isFocusModeActive ? 'Focus Mode Active' : 'Start Focus Mode',
                            style: const TextStyle(color: Color(0xFF000a7b), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text('View History', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _BentoGrid extends StatelessWidget {
  const _BentoGrid();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.tertiary),
            const SizedBox(width: 8),
            Text('AI-Based Recommendations', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        const SizedBox(height: 24),
        if (!state.isDismissed('circadian')) ...[
          _LargeCard(
            id: 'circadian',
            title: 'Optimize Circadian Rhythm',
            desc: 'Your data shows a correlation between midnight phone usage and morning fatigue. We suggest enabling Grayscale mode after 10 PM.',
            icon: Icons.brightness_3,
            iconColor: AppTheme.primary,
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: _SmallCard(
                title: 'Mindful Pause',
                desc: '3 min breathwork',
                icon: Icons.self_improvement,
                color: AppTheme.tertiary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _SmallCard(
                title: 'Silence Mode',
                desc: 'Focus block active',
                icon: Icons.notifications_off,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!state.isDismissed('social_cap')) ...[
           _VerticalCard(
            id: 'social_cap',
            title: 'Social Media Cap',
            desc: 'Limit Instagram to 30m today to regain 1.5h of productivity.',
            icon: Icons.timer,
            color: AppTheme.secondary,
           )
        ]
      ],
    );
  }
}

class _LargeCard extends StatelessWidget {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color iconColor;

  const _LargeCard({required this.id, required this.title, required this.desc, required this.icon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 24),
          Row(
            children: [
              InkWell(
                onTap: () {
                  context.read<AppState>().dismissRecommendation(id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suggestion Applied!')));
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
                  child: Text('APPLY SUGGESTION', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.primary)),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => context.read<AppState>().dismissRecommendation(id),
                child: Text('DISMISS', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.outlineVariant)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _VerticalCard extends StatelessWidget {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _VerticalCard({required this.id, required this.title, required this.desc, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.surfaceContainerHigh, AppTheme.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(desc, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 32),
          InkWell(
            onTap: () {
                context.read<AppState>().dismissRecommendation(id);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder Set!')));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: color.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text('SET REMINDER', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color))),
            ),
          )
        ],
      ),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  const _SmallCard({required this.title, required this.desc, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: TextStyle(fontSize: 11, color: AppTheme.outlineVariant)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ImprovementTips extends StatelessWidget {
  const _ImprovementTips();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: [
             Icon(Icons.psychology, color: AppTheme.primary),
             const SizedBox(width: 8),
             Text('Mental Wellness', style: Theme.of(context).textTheme.headlineSmall),
           ],
        ),
        const SizedBox(height: 16),
        _TipItem(title: 'Digital Minimalism Guide', color: AppTheme.primary),
        const SizedBox(height: 12),
        _TipItem(title: 'Journaling for Focus', color: AppTheme.primary, isHighlighted: true),
        const SizedBox(height: 32),
        Row(
           children: [
             Icon(Icons.bolt, color: AppTheme.secondary),
             const SizedBox(width: 8),
             Text('Productivity', style: Theme.of(context).textTheme.headlineSmall),
           ],
        ),
        const SizedBox(height: 16),
        _TipItem(title: 'Batch Notification Strategy', color: AppTheme.secondary),
        const SizedBox(height: 12),
        _TipItem(title: 'Deep Work Environment', color: AppTheme.secondary, isHighlighted: true),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final String title;
  final Color color;
  final bool isHighlighted;

  const _TipItem({required this.title, required this.color, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted ? Border(left: BorderSide(color: color, width: 4)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
        ],
      ),
    );
  }
}
