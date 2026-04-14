import 'package:flutter/material.dart';

import '../services/daily_usage_service.dart';
import '../services/screen_time_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/top_nav.dart';

class SuggestionsTab extends StatefulWidget {
  const SuggestionsTab({super.key});

  @override
  State<SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends State<SuggestionsTab> {
  bool isLoading = false;
  List<String> suggestions = const [];
  String? errorMessage;

  late Future<SuggestionsInputData?> _inputFuture;

  @override
  void initState() {
    super.initState();
    _inputFuture = _loadInputData();
  }

  Future<SuggestionsInputData?> _loadInputData() async {
    final screen = await ScreenTimeService.getMetrics();
    if (screen == null) return null;

    final today = await DailyUsageService.fetchAndStoreDailyStats() ??
        await DailyUsageService.getStoredDailyStats();
    if (today == null) return null;

    final flags = _deriveFlags(screen);

    return SuggestionsInputData(
      metrics: {
        'screen_time_today': _formatDuration(screen.todayScreenTime),
        'screen_time_weekly': _formatDuration(screen.weeklyScreenTime),
        'unlock_count_today': screen.todayUnlocks,
        'unlock_count_weekly': screen.weeklyUnlocks,
        'focus_score': screen.focusScore.round(),
        'addiction_score': screen.addictionScore.round(),
        'productive_ratio': '${(screen.productiveRatio * 100).round()}%',
        'late_night_usage': _formatDuration(screen.lateNightUsage),
      },
      apps: screen.todayApps
          .take(5)
          .map(
            (a) => {
              'name': a.name,
              'usage': _formatDuration(a.usage),
              'category': a.category,
            },
          )
          .toList(),
      flags: flags,
    );
  }

  List<String> _deriveFlags(ScreenTimeData data) {
    final flags = <String>[];

    final weeklyDailyAverageMinutes = data.weeklyScreenTime.inMinutes / 7.0;
    final todayMinutes = data.todayScreenTime.inMinutes.toDouble();
    if (todayMinutes > weeklyDailyAverageMinutes * 1.2) {
      flags.add('high_screen_time');
    }

    final weeklyUnlockAverage = data.weeklyUnlocks / 7.0;
    if (data.todayUnlocks > weeklyUnlockAverage * 1.2) {
      flags.add('high_unlock_frequency');
    }

    if (data.lateNightUsage.inMinutes > 0) {
      flags.add('late_night_usage');
    }

    if (data.productiveRatio < 0.4) {
      flags.add('low_productive_ratio');
    }

    return flags;
  }

  Future<List<String>> fetchSuggestions(Map<String, dynamic> inputData) async {
    await Future.delayed(const Duration(seconds: 2));

    final flags =
        (inputData['flags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final apps = (inputData['apps'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final topEntertainment = apps.firstWhere(
      (a) => (a['category']?.toString().toLowerCase() ?? '') == 'entertainment',
      orElse: () => const {'name': 'social media'},
    );
    final topEntertainmentName = topEntertainment['name']?.toString() ?? 'social media';

    final generated = <String>[];

    if (flags.contains('high_screen_time')) {
      generated.add(
        'Set a usage cap for $topEntertainmentName to reduce today\'s total screen time.',
      );
    }
    if (flags.contains('high_unlock_frequency')) {
      generated.add(
        'Reduce compulsive checks by batching notifications and checking your phone on schedule.',
      );
    }
    if (flags.contains('late_night_usage')) {
      generated.add(
        'Cut late-night sessions by enabling bedtime mode and keeping the phone away from your bed.',
      );
    }
    if (flags.contains('low_productive_ratio')) {
      generated.add(
        'Start your day with one productive app block before opening entertainment apps.',
      );
    }

    if (generated.isEmpty) {
      generated.add('Your habits are balanced today. Keep the same routine.');
      generated.add('Take short no-phone breaks between intensive app sessions.');
      generated.add('Review weekly trends daily to avoid hidden usage spikes.');
    }

    return generated;
  }

  Future<void> _onGenerateSuggestions(SuggestionsInputData input) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await fetchSuggestions(input.toMap());
      if (!mounted) return;
      setState(() {
        suggestions = response;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          FutureBuilder<SuggestionsInputData?>(
            future: _inputFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final input = snapshot.data;
              if (input == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 42),
                          const SizedBox(height: 10),
                          const Text('Usage data unavailable'),
                          const SizedBox(height: 8),
                          const Text(
                            'Grant usage access to generate personalized suggestions.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () async {
                              await DailyUsageService.openUsageSettings();
                              if (!mounted) return;
                              setState(() {
                                _inputFuture = _loadInputData();
                              });
                            },
                            child: const Text('Open Usage Access Settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.only(top: 100, bottom: 120, left: 20, right: 20),
                children: [
                  const _Header(),
                  const SizedBox(height: 16),
                  _SummaryCard(flags: input.flags),
                  const SizedBox(height: 14),
                  _FlagsSection(flags: input.flags),
                  const SizedBox(height: 14),
                  _SuggestionsSection(
                    isLoading: isLoading,
                    suggestions: suggestions,
                    errorMessage: errorMessage,
                    onRetry: () => _onGenerateSuggestions(input),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _onGenerateSuggestions(input),
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(isLoading ? 'Generating...' : 'Generate Suggestions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
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

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
}

class SuggestionsInputData {
  final Map<String, dynamic> metrics;
  final List<Map<String, dynamic>> apps;
  final List<String> flags;

  const SuggestionsInputData({
    required this.metrics,
    required this.apps,
    required this.flags,
  });

  Map<String, dynamic> toMap() {
    return {
      'metrics': metrics,
      'apps': apps,
      'flags': flags,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggestions', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Improve your digital habits',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<String> flags;

  const _SummaryCard({required this.flags});

  @override
  Widget build(BuildContext context) {
    final summary = flags.isEmpty
        ? 'No concerning behavior detected.'
        : '${flags.take(2).map(_toReadable).join(' and ')} detected.';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.insights_rounded, color: AppTheme.error, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  static String _toReadable(String key) => key.replaceAll('_', ' ');
}

class _FlagsSection extends StatelessWidget {
  final List<String> flags;

  const _FlagsSection({required this.flags});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Key Flags', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (flags.isEmpty)
            Text(
              'No active flags',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: flags
                  .map(
                    (flag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        flag,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  final bool isLoading;
  final List<String> suggestions;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _SuggestionsSection({
    required this.isLoading,
    required this.suggestions,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggestions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 22),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage!,
                  style: TextStyle(color: AppTheme.error),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            )
          else if (suggestions.isEmpty)
            Text(
              'Tap below to generate personalized suggestions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
            )
          else
            Column(
              children: suggestions
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SuggestionItem(text: item),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final String text;

  const _SuggestionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: AppTheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
