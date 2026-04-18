import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const ScreenTherapistApp());
}

class ScreenTherapistApp extends StatelessWidget {
  const ScreenTherapistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()..fetchAnalysisData()),
      ],
      child: MaterialApp(
        title: 'Screen Therapist',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainScreen(),
      ),
    );
  }
}
