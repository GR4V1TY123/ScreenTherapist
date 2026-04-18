import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
    this.borderRadius = 16.0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final shouldBlur = defaultTargetPlatform != TargetPlatform.android;

    Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null
            ? AppTheme.surfaceBright.withValues(alpha: 0.4)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border(
          top: BorderSide(
            color: AppTheme.outlineVariant.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: child,
    );

    if (shouldBlur) {
      card = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
        child: card,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: card,
    );
  }
}
