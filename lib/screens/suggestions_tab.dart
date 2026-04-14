import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  static const _endpoint = 'https://screentherapist.onrender.com/suggestions';

  final TextEditingController _queryController = TextEditingController();
  bool isLoading = false;
  SuggestionsResponse? suggestionsResponse;
  String? errorMessage;

  late Future<SuggestionsInputData?> _inputFuture;

  @override
  void initState() {
    super.initState();
    _queryController.text =
        'I get distracted by short videos and keep checking my phone at night. Help me reduce this.';
    _inputFuture = _loadInputData();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
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
        'unlock_count_today': '${screen.todayUnlocks}',
        'unlock_count_weekly': '${screen.weeklyUnlocks}',
        'focus_score': '${screen.focusScore.round()}',
        'addiction_score': '${screen.addictionScore.round()}',
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

  Future<SuggestionsResponse> fetchSuggestions(SuggestionsInputData inputData) async {
    final payload = inputData.toPayload(query: _queryController.text.trim());
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Request failed (${response.statusCode}). Please try again.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format from suggestions API.');
    }

    if (decoded['error'] != null) {
      throw Exception(decoded['error'].toString());
    }

    return SuggestionsResponse.fromJson(decoded);
  }

  Future<void> _onGenerateSuggestions(SuggestionsInputData input) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      suggestionsResponse = null;
    });

    try {
      final response = await fetchSuggestions(input);
      if (!mounted) return;
      setState(() {
        suggestionsResponse = response;
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
                  _UserQuerySection(controller: _queryController),
                  const SizedBox(height: 14),
                  _SuggestionsSection(
                    isLoading: isLoading,
                    response: suggestionsResponse,
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
  final Map<String, String> metrics;
  final List<Map<String, String>> apps;
  final List<String> flags;

  const SuggestionsInputData({
    required this.metrics,
    required this.apps,
    required this.flags,
  });

  Map<String, dynamic> toPayload({required String query}) {
    return {
      'query': query.isEmpty ? 'I want better screen-time habits and focus.' : query,
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

class _UserQuerySection extends StatelessWidget {
  final TextEditingController controller;

  const _UserQuerySection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Concern', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Add your goal or challenge so suggestions are personalized.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Example: I overuse Instagram after 10 PM and miss sleep.',
              filled: true,
              fillColor: AppTheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.35)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  final bool isLoading;
  final SuggestionsResponse? response;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _SuggestionsSection({
    required this.isLoading,
    required this.response,
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
          else if (response == null)
            Text(
              'Tap below to generate personalized suggestions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.outlineVariant),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response!.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text('Action Plan', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (response!.suggestions.isEmpty)
                  Text(
                    'No suggestions returned by the API.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.outlineVariant),
                  )
                else
                  ...response!.suggestions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SuggestionEntryCard(item: item),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Alternative Activities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (response!.alternativeActivities.isEmpty)
                  Text(
                    'No alternatives available.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppTheme.outlineVariant),
                  )
                else
                  ...response!.alternativeActivities
                      .map((item) => _AlternativeActivityCard(item: item)),
              ],
            ),
        ],
      ),
    );
  }
}

class _SuggestionEntryCard extends StatelessWidget {
  final SuggestionEntry item;

  const _SuggestionEntryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(item.priority);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.priority.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.reason, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.play_arrow_rounded, size: 18, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.action,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.error;
      case 'medium':
        return const Color(0xFFFFB74D);
      default:
        return AppTheme.secondary;
    }
  }
}

class _AlternativeActivityCard extends StatelessWidget {
  final AlternativeActivity item;

  const _AlternativeActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.basedOn, style: Theme.of(context).textTheme.titleSmall),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  item.type,
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(item.suggestion, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class SuggestionsResponse {
  final String summary;
  final List<SuggestionEntry> suggestions;
  final List<AlternativeActivity> alternativeActivities;

  const SuggestionsResponse({
    required this.summary,
    required this.suggestions,
    required this.alternativeActivities,
  });

  factory SuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionsResponse(
      summary: json['summary']?.toString() ?? 'Suggestions generated.',
      suggestions: (json['suggestions'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SuggestionEntry.fromJson)
          .toList(),
      alternativeActivities: (json['alternative_activities'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(AlternativeActivity.fromJson)
          .toList(),
    );
  }
}

class SuggestionEntry {
  final String title;
  final String reason;
  final String action;
  final String priority;

  const SuggestionEntry({
    required this.title,
    required this.reason,
    required this.action,
    required this.priority,
  });

  factory SuggestionEntry.fromJson(Map<String, dynamic> json) {
    return SuggestionEntry(
      title: json['title']?.toString() ?? 'Suggestion',
      reason: json['reason']?.toString() ?? 'No reason provided.',
      action: json['action']?.toString() ?? 'No action provided.',
      priority: json['priority']?.toString() ?? 'low',
    );
  }
}

class AlternativeActivity {
  final String basedOn;
  final String suggestion;
  final String type;

  const AlternativeActivity({
    required this.basedOn,
    required this.suggestion,
    required this.type,
  });

  factory AlternativeActivity.fromJson(Map<String, dynamic> json) {
    return AlternativeActivity(
      basedOn: json['based_on']?.toString() ?? 'Current behavior',
      suggestion: json['suggestion']?.toString() ?? 'Take a short break away from your phone.',
      type: json['type']?.toString() ?? 'mental',
    );
  }
}
