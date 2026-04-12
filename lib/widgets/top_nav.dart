import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopNavRoute extends StatelessWidget {
  const TopNavRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppTheme.surface.withValues(alpha: 0.8), // simulating backdrop blur
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: AppTheme.primary),
                const SizedBox(width: 12),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                  ).createShader(bounds),
                  child: Text(
                    'Screen Therapist',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceContainerHigh,
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Icon(Icons.person, color: AppTheme.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
