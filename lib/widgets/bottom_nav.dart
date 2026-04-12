import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../state/app_state.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shouldBlur = defaultTargetPlatform != TargetPlatform.android;

    Widget navSurface = Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.1),
            blurRadius: 50,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_max_outlined,
            label: 'Home',
            index: 0,
            isActive: state.currentTab == 0,
            onTap: () => state.setTab(0),
          ),
          _NavItem(
            icon: Icons.insights_outlined,
            label: 'Analytics',
            index: 1,
            isActive: state.currentTab == 1,
            onTap: () => state.setTab(1),
          ),
          _NavItem(
            icon: Icons.auto_awesome,
            label: 'Suggestions',
            index: 2,
            isActive: state.currentTab == 2,
            isSpecial: true,
            onTap: () => state.setTab(2),
          ),
        ],
      ),
    );

    if (shouldBlur) {
      navSurface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: navSurface,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: navSurface,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final bool isSpecial;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    this.isSpecial = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive 
        ? AppTheme.primary 
        : (isSpecial ? AppTheme.primary : Colors.blueGrey.shade400);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        transform: Matrix4.diagonal3Values(isActive ? 1.05 : 1.0, isActive ? 1.05 : 1.0, 1.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: isSpecial && isActive
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.6),
                          blurRadius: 16,
                        )
                      ],
                    )
                  : null,
              child: Icon(
                icon,
                color: isActive ? AppTheme.secondary : color,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive ? AppTheme.secondary : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
