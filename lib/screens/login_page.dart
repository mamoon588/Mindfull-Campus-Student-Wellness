import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  // Slow "breathing" pulse behind the leaf, a calm touch that echoes the app
  late final AnimationController _pulse =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  bool _showPass = false;
  bool _remember = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final remembered = context.read<AppState>().rememberedEmail;
    _email.text = remembered;
    _remember = remembered.isNotEmpty;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the phone's "remove animations" accessibility setting
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) {
      showToast(context, 'Please fix the highlighted fields.', kind: ToastKind.error);
      return;
    }
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    await app.login(email: _email.text.trim(), remember: _remember);
    if (!mounted) return;
    nav.popUntil((route) => route.isFirst); // back to the root, which is now the dashboard
    toastOn(messenger, '✅ Welcome back, ${app.userName}!', kind: ToastKind.success);
  }

  void _forgotPassword() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot your password?'),
        content: const Text(
            'Your account is saved only on this phone, so there is no email to send a reset link to. '
                'Password reset will be available once online accounts are added.\n\n'
                'For now you can create a new account with Sign Up.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  // Vertical gap: a fixed gap inside the card, but on a phone it also
  // stretches (Spacer) so the content fills the whole screen height.
  List<Widget> _gap(bool fill, double h, {int flex = 1}) =>
      [SizedBox(height: h), if (fill) Spacer(flex: flex)];

  // All the login content. fill = true on phones (spread over the full screen).
  Widget _content({required bool fill, required double hero}) {
    return AutofillGroup(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- Back button ----------
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: IconButton.outlined(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(48, 48),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),
            ..._gap(fill, 8),

            // ---------- Calm leaf with a breathing ring ----------
            ExcludeSemantics(
              child: Center(
                child: SizedBox(
                  width: hero + 30,
                  height: hero + 30,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1.12).animate(
                            CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                        child: Container(
                          width: hero + 24,
                          height: hero + 24,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Color(0x262D9D5F)),
                        ),
                      ),
                      Container(
                        width: hero,
                        height: hero,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFFD9F1E3)),
                        child: Text('🌿', style: TextStyle(fontSize: hero * 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 4),
            const Text('Take a deep breath. Your calm space is waiting.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ..._gap(fill, 22),

            // ---------- Fields ----------
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline, color: AppColors.primary),
              ),
              validator: (v) => looksLikeEmail((v ?? '').trim())
                  ? null
                  : 'Enter a valid email, like name@email.com',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass,
              obscureText: !_showPass,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                suffixIcon: IconButton(
                  tooltip: _showPass ? 'Hide password' : 'Show password',
                  icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.primary),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
            const SizedBox(height: 4),

            // ---------- Remember me + Forgot password ----------
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Remember me', style: TextStyle(fontSize: 14)),
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                ),
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ---------- Login button ----------
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x402D9D5F), blurRadius: 12, offset: Offset(0, 5)),
                ],
              ),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                    : const Text('Log In'),
              ),
            ),
            ..._gap(fill, 12, flex: 2),

            // ---------- Sign up link ----------
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?",
                      style: TextStyle(color: AppColors.muted)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => const RegisterPage())),
                    child: const Text('Sign Up',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F5EA), AppColors.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            final phone = c.maxWidth < 520;

            if (phone) {
              // PHONE: the page covers the whole screen, content spread top to bottom
              final hero = (c.maxHeight * 0.2).clamp(90.0, 140.0);
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _content(fill: true, hero: hero),
                    ),
                  ),
                ),
              );
            }

            // WIDE SCREEN (Chrome / tablet): phone-sized card with rounded corners
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFDDEFE3)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 24,
                            offset: Offset(0, 8)),
                      ],
                    ),
                    child: _content(fill: false, hero: 90),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}