import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/call.dart';
import 'login_page.dart';
import 'register_page.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _Slide {
  const _Slide(this.emoji, this.title, this.body, this.tint);
  final String emoji;
  final String title;
  final String body;
  final Color tint;
}

const _slides = [
  _Slide('🌿', 'Check in with yourself',
      'Log your mood in two taps and see how your week is going.', Color(0xFFD9F1E3)),
  _Slide('🌬️', 'Breathe, sleep, write',
      'Guided breathing, a sleep log and a private journal, all in one place.',
      Color(0xFFDCEBFA)),
  _Slide('🤝', 'Help is one tap away',
      'Crisis helplines stay within reach, wherever you are in the app.',
      Color(0xFFF6E3E3)),
];

class _LandingScreenState extends State<LandingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final mutedColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                // 👈 Dynamic gradient for light/dark mode
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), bgColor]
                      : [const Color(0xFFE3F5EA), bgColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: '🧠 Mindful'),
                          TextSpan(
                              text: 'Campus', style: TextStyle(color: AppColors.primary)),
                        ]),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _slides.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) {
                          final s = _slides[i];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 150,
                                    height: 150,
                                    alignment: Alignment.center,
                                    decoration:
                                    BoxDecoration(color: s.tint, shape: BoxShape.circle),
                                    child: Text(s.emoji, style: const TextStyle(fontSize: 70)),
                                  ),
                                  const SizedBox(height: 28),
                                  Text(s.title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                          color: textColor)), // 👈 Dynamic Text Color
                                  const SizedBox(height: 10),
                                  Text(s.body,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 16, color: mutedColor, height: 1.45)), // 👈 Dynamic Text Color
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            Semantics(
                              label: 'Page ${i + 1} of ${_slides.length}',
                              selected: i == _page,
                              button: true,
                              child: GestureDetector(
                                onTap: () => _controller.animateToPage(i,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    width: i == _page ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == _page ? AppColors.primary : AppColors.border,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            decoration: BoxDecoration(
              color: cardColor, // 👈 Dynamic Card Color
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                    color: isDark ? Colors.black45 : const Color(0x14000000),
                    blurRadius: 16,
                    offset: const Offset(0, -4)
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const RegisterPage())),
                    child: const Text('Get started'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const LoginPage())),
                    child: const Text('I already have an account'),
                  ),
                  const SizedBox(height: 10),
                  Text('🔒 Your entries stay on this phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: mutedColor)),
                  TextButton(
                    onPressed: () => callNumber(context, '1166'),
                    child: const Text('In crisis? Call 1166',
                        style: TextStyle(
                            color: AppColors.danger, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}