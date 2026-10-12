import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

Future<void> showAuthSheet(BuildContext context, {required bool register}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => AuthSheet(startAsRegister: register),
  );
}

class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key, required this.startAsRegister});
  final bool startAsRegister;

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  late bool _register = widget.startAsRegister;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPass = false;
  bool _remember = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final remembered = context.read<AppState>().rememberedEmail;
    _email.text = remembered;
    _remember = remembered.isNotEmpty;
    _pass.addListener(_refresh);
    _confirm.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final app = context.read<AppState>();

    final email = _email.text.trim();
    final pass = _pass.text;

    String? problem;
    if (_register) {
      if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
        problem = 'Please enter your first and last name.';
      } else if (!looksLikeEmail(email)) {
        problem = 'Please enter a valid email address, like name@university.edu.';
      } else if (!PasswordRules.ok(pass)) {
        problem = 'Your password needs at least 8 characters, a letter and a number.';
      } else if (pass != _confirm.text) {
        problem = 'The two passwords do not match.';
      }
    } else {
      if (!looksLikeEmail(email)) {
        problem = 'Please enter a valid email address.';
      } else if (pass.isEmpty) {
        problem = 'Please enter your password.';
      }
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() => _error = null);

    navigator.pop();
    if (_register) {
      final first = _first.text.trim();
      await app.register(fullName: '$first ${_last.text.trim()}', email: email);
      toastOn(messenger, '🎉 Welcome to Mindful Campus, $first!', kind: ToastKind.success);
    } else {
      await app.login(email: email, remember: _remember);
      toastOn(messenger, '✅ Welcome back, ${app.userName}!', kind: ToastKind.success);
    }
  }

  Widget _rule(bool ok, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18, color: ok ? AppColors.primary : AppColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, color: ok ? AppColors.primaryDark : AppColors.muted)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final pass = _pass.text;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_register ? '✨' : '🔐',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 4),
          Text(_register ? 'Create Your Account' : 'Welcome Back',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              _register
                  ? 'Start your mental wellness journey today'
                  : 'Log in to continue your wellness journey',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 18),
          if (_register) ...[
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _first,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                      decoration: const InputDecoration(labelText: 'First name'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _last,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                      decoration: const InputDecoration(labelText: 'Last name'))),
            ]),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
                labelText: 'Email address',
                hintText: _register ? 'name@university.edu' : 'name@email.com'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            obscureText: !_showPass,
            textInputAction: _register ? TextInputAction.next : TextInputAction.done,
            onSubmitted: _register ? null : (_) => _submit(),
            autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                tooltip: _showPass ? 'Hide password' : 'Show password',
                icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPass = !_showPass),
              ),
            ),
          ),
          if (_register) ...[
            const SizedBox(height: 8),
            _rule(PasswordRules.hasLength(pass), 'At least 8 characters'),
            _rule(PasswordRules.hasLetter(pass), 'A letter'),
            _rule(PasswordRules.hasNumber(pass), 'A number'),
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: !_showPass,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm password'),
            ),
            if (_confirm.text.isNotEmpty)
              _rule(_confirm.text == pass, 'Passwords match'),
          ] else
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Remember my email'),
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? false),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Callout(
                color: AppColors.dangerSoft,
                accent: AppColors.danger,
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
              onPressed: _submit,
              child: Text(_register ? 'Create Account' : 'Log In')),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _register = !_register;
              _error = null;
            }),
            child: Text(_register
                ? 'Already have an account? Log in here'
                : "Don't have an account? Sign up here"),
          ),
        ],
      ),
    );
  }
}
