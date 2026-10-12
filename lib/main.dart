import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/landing_screen.dart';
import 'services/app_state.dart';
import 'services/voice_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VoiceService.instance.init();
  final state = await AppState.create();
  runApp(ChangeNotifierProvider<AppState>.value(
    value: state,
    child: const MindfulCampusApp(),
  ));
}

class MindfulCampusApp extends StatelessWidget {
  const MindfulCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mindful Campus',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
      home: Consumer<AppState>(
        builder: (context, app, _) =>
            app.isLoggedIn ? const HomeShell() : const LandingScreen(),
      ),
    );
  }
}
