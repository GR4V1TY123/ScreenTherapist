import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class PersonalizationCard extends StatelessWidget {
  final Personalization personalization;

  const PersonalizationCard({super.key, required this.personalization});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Personalized Insights',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip(
                label: 'Avg Screen Time',
                value: '${personalization.personalAvgScreenTime.toInt()}m',
              ),
              _StatChip(
                label: 'Avg Focus',
                value: '${personalization.personalAvgFocus.toInt()}',
              ),
              _StatChip(
                label: 'Avg Addiction',
                value: '${personalization.personalAvgAddiction.toInt()}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (personalization.strengths.isNotEmpty) ...[
            Text(
              '💪 Your Strengths',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...personalization.strengths.map(
              (s) =>
                  Text('• $s', style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 12),
          ],
          if (personalization.improvementAreas.isNotEmpty) ...[
            Text(
              '🎯 Areas for Improvement',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            ...personalization.improvementAreas.map(
              (a) =>
                  Text('• $a', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
