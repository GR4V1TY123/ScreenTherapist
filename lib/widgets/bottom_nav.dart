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
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF141f38).withAlpha(153), // 60% opacity
        borderRadius: BorderRadius.circular(32),
        border: const Border(
          top: BorderSide(color: Colors.white24, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128), // 50%
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
        ), // Added padding to avoid overflow
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.max, // Let flex handle layout
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_max,
                label: 'HOME',
                index: 0,
                isActive: state.currentTab == 0,
                onTap: () => state.setTab(0),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.insights,
                label: 'ANALYTICS',
                index: 1,
                isActive: state.currentTab == 1,
                onTap: () => state.setTab(1),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.auto_awesome,
                label:
                    'IDEAS', // Shortened from SUGGESTIONS to prevent text overflow on narrow devices
                index: 2,
                isActive: state.currentTab == 2,
                onTap: () => state.setTab(2),
              ),
            ),
            Expanded(
              child: _NavItem(
                icon: Icons.person,
                label: 'PROFILE',
                index: 3,
                isActive: state.currentTab == 3,
                onTap: () {}, // empty navigation for now
              ),
            ),
          ],
        ),
      ),
    );

    if (shouldBlur) {
      navSurface = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: navSurface,
        ),
      );
    } else {
      navSurface = ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: navSurface,
      );
    }

    return navSurface;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primary : AppTheme.outlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        transform: Matrix4.diagonal3Values(
          isActive ? 1.05 : 1.0,
          isActive ? 1.05 : 1.0,
          1.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: isActive
                  ? BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(153),
                          blurRadius: 10,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                icon,
                color: isActive ? AppTheme.primary : color,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9, // Slightly smaller font
                  letterSpacing: 1.0, // Reduced letter spacing
                  fontWeight: FontWeight.bold,
                  color: isActive ? AppTheme.primary : color,
                  shadows: isActive
                      ? [
                          Shadow(
                            color: AppTheme.primary.withAlpha(150),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
