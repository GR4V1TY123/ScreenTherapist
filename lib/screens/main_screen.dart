import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/bottom_nav.dart';
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
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: BottomNav(),
            ),
          ),
        ],
      ),
    );
  }
}
