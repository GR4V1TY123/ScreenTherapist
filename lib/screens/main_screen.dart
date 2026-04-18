import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/bottom_nav.dart';
import '../theme/app_theme.dart';
import 'home_tab.dart';
import 'analytics_tab.dart';
import 'suggestions_tab.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentTab = context.watch<AppState>().currentTab;

    Widget buildBody() {
      switch (currentTab) {
        case 0:
          return const HomeTab();
        case 1:
          return const AnalyticsTab();
        case 2:
          return const SuggestionsTab();
        default:
          return const SuggestionsTab();
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: buildBody(),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(child: BottomNav()),
          ),
          Positioned(
            bottom: 112,
            right: 24,
            child: SafeArea(
              child: FloatingActionButton(
                onPressed: () {},
                elevation: 12,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryContainer],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(100),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF101b8b),
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
