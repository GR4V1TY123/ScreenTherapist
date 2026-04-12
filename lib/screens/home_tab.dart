import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/top_nav.dart';
import '../widgets/glass_card.dart';
import '../services/screen_time_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // A key to refresh the future builder after granting permission
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 100, bottom: 120, left: 24, right: 24),
            children: [
              const Text('Welcome back, User', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Your Digital Vibe', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              FutureBuilder<ScreenTimeData?>(
                 key: _refreshKey,
                 future: ScreenTimeService.getMetrics(),
                 builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return _DailyRing(data: snapshot.data!);
                    }
                    // Permission not granted
                    return _PermissionCard(onGranted: () {
                       setState(() { _refreshKey = UniqueKey(); });
                    });
                 }
              ),
              const SizedBox(height: 40),
              const _ActiveFocusWidget(),
            ],
          ),
          const Positioned(
            top: 0, left: 0, right: 0,
            child: TopNavRoute(),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final VoidCallback onGranted;
  const _PermissionCard({required this.onGranted});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
           Icon(Icons.lock_outline, size: 60, color: AppTheme.secondary),
           const SizedBox(height: 16),
           const Text('Permission Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           Text(
             'We need Usage Access to provide real-time therapy insights without hardcoding data.',
             textAlign: TextAlign.center,
             style: TextStyle(color: AppTheme.outlineVariant),
           ),
           const SizedBox(height: 24),
           ElevatedButton(
             onPressed: () async {
                await ScreenTimeService.promptPermission();
                onGranted();
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.primary,
               foregroundColor: AppTheme.surface,
             ),
             child: const Text('Grant Access in Settings', style: TextStyle(fontWeight: FontWeight.bold)),
           )
        ],
      ),
    );
  }
}

class _DailyRing extends StatelessWidget {
  final ScreenTimeData data;
  const _DailyRing({required this.data});

  @override
  Widget build(BuildContext context) {
    final duration = data.todayScreenTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    final goalMinutes = 360; 
    final progress = (duration.inMinutes / goalMinutes).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _RingPainter(
                progress: progress,
                trackColor: AppTheme.surfaceContainerHigh,
                gradientStart: AppTheme.primary,
                gradientEnd: AppTheme.tertiary,
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Screen Time', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppTheme.outlineVariant)),
                  const SizedBox(height: 4),
                  Text('${hours}h ${minutes}m', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40)),
                  const SizedBox(height: 4),
                  Text('${data.todayUnlocks} Unlocks Today', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color gradientStart;
  final Color gradientEnd;

  _RingPainter({required this.progress, required this.trackColor, required this.gradientStart, required this.gradientEnd});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
      colors: [gradientStart, gradientEnd],
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ActiveFocusWidget extends StatelessWidget {
  const _ActiveFocusWidget();

  @override
  Widget build(BuildContext context) {
    final isFocusModeActive = context.watch<AppState>().isFocusModeActive;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isFocusModeActive ? AppTheme.primary.withValues(alpha: 0.2) : AppTheme.outlineVariant.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.psychology, color: isFocusModeActive ? AppTheme.primary : AppTheme.outlineVariant, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isFocusModeActive ? 'Focus Mode Active' : 'Detox Paused', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(isFocusModeActive ? 'Notifications silenced and grayscale enabled.' : 'You are currently not in any focus sessions.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
