import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/landing_screen.dart';
import 'services/app_state.dart';
import 'services/voice_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👈 Wrap in try-catch so a plugin failure doesn't freeze the app
  try {
    await VoiceService.instance.init();
  } catch (e) {
    debugPrint('Voice init error: $e');
  }

  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

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
    return Consumer<AppState>(
      builder: (context, app, _) {
        return MaterialApp(
          title: 'Mindful Campus',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(
            isDark: app.isDarkMode,
            seedColor: Color(app.themeColorValue),
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(app.textScale),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: child,
              ),
            );
          },
          home: app.isLoggedIn ? const HomeShell() : const LandingScreen(),
        );
      },
    );
  }
}