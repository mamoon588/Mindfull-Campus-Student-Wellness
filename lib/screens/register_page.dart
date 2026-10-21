import 'dart:math' as math;

import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'login_page.dart';

class _Country {
  const _Country(this.iso, this.name, this.dial, this.minLen, this.maxLen);
  final String iso;
  final String name;
  final String dial;
  final int minLen;
  final int maxLen;
}

const _rawCountries = [
  _Country('PK', 'Pakistan', '+92', 10, 10),
  _Country('IN', 'India', '+91', 10, 10),
  _Country('BD', 'Bangladesh', '+880', 10, 10),
  _Country('AF', 'Afghanistan', '+93', 9, 9),
  _Country('AE', 'United Arab Emirates', '+971', 9, 9),
  _Country('SA', 'Saudi Arabia', '+966', 9, 9),
  _Country('GB', 'United Kingdom', '+44', 10, 10),
  _Country('US', 'United States', '+1', 10, 10),
  _Country('CA', 'Canada', '+1', 10, 10),
  _Country('TR', 'Turkey', '+90', 10, 10),
  _Country('QA', 'Qatar', '+974', 8, 8),
  _Country('KW', 'Kuwait', '+965', 8, 8),
  _Country('OM', 'Oman', '+968', 8, 8),
  _Country('BH', 'Bahrain', '+973', 8, 8),
  _Country('MY', 'Malaysia', '+60', 9, 10),
  _Country('AU', 'Australia', '+61', 9, 9),
  _Country('DE', 'Germany', '+49', 10, 11),
  _Country('FR', 'France', '+33', 9, 9),
  _Country('CN', 'China', '+86', 11, 11),
  _Country('IR', 'Iran', '+98', 10, 10),
  _Country('LK', 'Sri Lanka', '+94', 9, 9),
  _Country('NP', 'Nepal', '+977', 10, 10),
  _Country('EG', 'Egypt', '+20', 10, 10),
  _Country('NG', 'Nigeria', '+234', 10, 10),
  _Country('ZA', 'South Africa', '+27', 9, 9),
  _Country('ID', 'Indonesia', '+62', 9, 12),
  _Country('RU', 'Russia', '+7', 10, 10),
  _Country('KZ', 'Kazakhstan', '+7', 10, 10),
  _Country('JP', 'Japan', '+81', 9, 10),
  _Country('KR', 'South Korea', '+82', 9, 10),
  _Country('SG', 'Singapore', '+65', 8, 8),
  _Country('HK', 'Hong Kong', '+852', 8, 8),
  _Country('TH', 'Thailand', '+66', 9, 9),
  _Country('VN', 'Vietnam', '+84', 9, 10),
  _Country('PH', 'Philippines', '+63', 10, 10),
  _Country('IT', 'Italy', '+39', 9, 10),
  _Country('ES', 'Spain', '+34', 9, 9),
  _Country('PT', 'Portugal', '+351', 9, 9),
  _Country('NL', 'Netherlands', '+31', 9, 9),
  _Country('BE', 'Belgium', '+32', 8, 9),
  _Country('CH', 'Switzerland', '+41', 9, 9),
  _Country('SE', 'Sweden', '+46', 7, 10),
  _Country('NO', 'Norway', '+47', 8, 8),
  _Country('DK', 'Denmark', '+45', 8, 8),
  _Country('FI', 'Finland', '+358', 9, 10),
  _Country('IE', 'Ireland', '+353', 9, 9),
  _Country('AT', 'Austria', '+43', 10, 12),
  _Country('PL', 'Poland', '+48', 9, 9),
  _Country('GR', 'Greece', '+30', 10, 10),
  _Country('UA', 'Ukraine', '+380', 9, 9),
  _Country('CZ', 'Czechia', '+420', 9, 9),
  _Country('RO', 'Romania', '+40', 9, 9),
  _Country('HU', 'Hungary', '+36', 9, 9),
  _Country('BR', 'Brazil', '+55', 10, 11),
  _Country('MX', 'Mexico', '+52', 10, 10),
  _Country('AR', 'Argentina', '+54', 10, 11),
  _Country('CO', 'Colombia', '+57', 10, 10),
  _Country('CL', 'Chile', '+56', 9, 9),
  _Country('PE', 'Peru', '+51', 9, 9),
  _Country('KE', 'Kenya', '+254', 9, 9),
  _Country('GH', 'Ghana', '+233', 9, 9),
  _Country('ET', 'Ethiopia', '+251', 9, 9),
  _Country('TZ', 'Tanzania', '+255', 9, 9),
  _Country('UG', 'Uganda', '+256', 9, 9),
  _Country('ZW', 'Zimbabwe', '+263', 9, 9),
  _Country('MU', 'Mauritius', '+230', 8, 8),
  _Country('MA', 'Morocco', '+212', 9, 9),
  _Country('DZ', 'Algeria', '+213', 9, 9),
  _Country('TN', 'Tunisia', '+216', 8, 8),
  _Country('JO', 'Jordan', '+962', 9, 9),
  _Country('LB', 'Lebanon', '+961', 7, 8),
  _Country('IQ', 'Iraq', '+964', 10, 10),
  _Country('YE', 'Yemen', '+967', 9, 9),
  _Country('IL', 'Israel', '+972', 9, 9),
  _Country('UZ', 'Uzbekistan', '+998', 9, 9),
  _Country('BT', 'Bhutan', '+975', 8, 8),
  _Country('MV', 'Maldives', '+960', 7, 7),
  _Country('MM', 'Myanmar', '+95', 8, 10),
  _Country('KH', 'Cambodia', '+855', 8, 9),
  _Country('NZ', 'New Zealand', '+64', 8, 10),
];

final List<_Country> _countries = [
  _rawCountries.first,
  ...(_rawCountries.skip(1).toList()..sort((a, b) => a.name.compareTo(b.name))),
];

Widget _flag(String iso, {double width = 26, double height = 18}) => CountryFlag.fromCountryCode(
  iso,
  width: width,
  height: height,
);

class _PhoneFormatter extends TextInputFormatter {
  const _PhoneFormatter(this.maxLen);
  final int maxLen;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limit = digits.startsWith('0') ? maxLen + 1 : maxLen;
    final cut = digits.length > limit ? digits.substring(0, limit) : digits;
    return TextEditingValue(
      text: cut,
      selection: TextSelection.collapsed(offset: cut.length),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _university = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  _Country _country = _countries.first;
  String? _gender;
  bool _agreed = false;
  bool _showPass = false;
  bool _showConfirm = false;
  bool _busy = false;
  bool _tried = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pass.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _university, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _phoneDigits =>
      _phone.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');

  bool get _phoneOk {
    final n = _phoneDigits.length;
    if (n < _country.minLen || n > _country.maxLen) return false;
    if (_country.dial == '+92' && !_phoneDigits.startsWith('3')) return false;
    return true;
  }

  String get _phoneNeed => _country.minLen == _country.maxLen
      ? '${_country.minLen}'
      : '${_country.minLen}-${_country.maxLen}';

  String? _firstProblem() {
    if (!looksLikeName(_first.text) || !looksLikeName(_last.text)) {
      return 'Enter your first and last name.';
    }
    if (_gender == null) return 'Select your gender.';
    if (!_phoneOk) {
      return (_country.dial == '+92' && _phoneDigits.length == 10)
          ? 'Pakistani mobile numbers start with 03.'
          : 'Phone number needs $_phoneNeed digits.';
    }
    if (!looksLikeEmail(_email.text.trim())) return 'Enter a valid email address.';
    if (!PasswordRules.ok(_pass.text)) return 'Use 8+ chars with upper, lower, digit & symbol.';
    if (_confirm.text != _pass.text) return 'The two passwords do not match.';
    if (!_agreed) return 'Please tick the box to continue.';
    return null;
  }

  Future<void> _pickCountry() async {
    final c = await showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (_) => _CountrySheet(selected: _country),
    );
    if (c != null) {
      setState(() => _country = c);
      _phone.value = _PhoneFormatter(c.maxLen)
          .formatEditUpdate(TextEditingValue.empty, _phone.value);
    }
  }

  Future<String?> _pickGender() {
    const options = [
      ('Male', Icons.male),
      ('Female', Icons.female),
      ('Other', Icons.transgender),
    ];
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select your gender',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            for (final o in options)
              ListTile(
                leading: Icon(o.$2, color: AppColors.primary),
                title: Text(o.$1),
                trailing: _gender == o.$1
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, o.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _tried = true);
    final fieldsOk = _form.currentState!.validate();
    final problem = _firstProblem();
    if (!fieldsOk || problem != null) {
      setState(() => _error = problem ?? 'Please fix the red fields.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final app = context.read<AppState>();
    final first = _first.text.trim();
    await app.register(
      fullName: '$first ${_last.text.trim()}',
      email: _email.text.trim(),
      phone: '${_country.dial} $_phoneDigits',
      gender: _gender!,
      university: _university.text.trim(),
    );
    if (!mounted) return;
    nav.popUntil((route) => route.isFirst);
    toastOn(messenger, '🎉 Welcome to Mindful Campus, $first!', kind: ToastKind.success);
  }

  OutlineInputBorder _border(Color color, [double width = 1.2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );

  Widget _req(String text, {double size = 14.5, required Color textColor}) => Text.rich(
    TextSpan(
      text: text,
      style: TextStyle(color: textColor, fontSize: size),
      children: [
        TextSpan(
            text: ' *',
            style: TextStyle(
                color: AppColors.danger, fontSize: size, fontWeight: FontWeight.w700)),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  InputDecoration _dec({String? hint, Widget? hintWidget, IconData? icon, Widget? suffix, required bool isDark, required Color textColor}) {
    final borderColor = isDark ? Colors.grey.shade700 : const Color(0xFFCBD5CC);
    return InputDecoration(
      hintText: hint,
      hint: hintWidget,
      hintStyle: TextStyle(color: textColor, fontSize: 14.5),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primary, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      border: _border(borderColor),
      enabledBorder: _border(borderColor),
      focusedBorder: _border(AppColors.primary, 1.8),
      errorBorder: _border(AppColors.danger),
      focusedErrorBorder: _border(AppColors.danger, 1.8),
    );
  }

  Widget _ruleChip(bool ok, String text, Color mutedColor) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14, color: ok ? AppColors.primary : mutedColor),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11.5, color: ok ? AppColors.primary : mutedColor)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pass = _pass.text;
    final short = MediaQuery.of(context).size.height < 640;
    final gap = short ? 8.0 : 11.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    // 👈 FIXED: Explicitly cast to Color to prevent null errors
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final Color mutedColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade700);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          final phone = c.maxWidth < 520;
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(phone ? 0 : 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight - (phone ? 0 : 16)),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    decoration: phone
                        ? null
                        : BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFDDEFE3)),
                      boxShadow: [
                        BoxShadow(
                            color: isDark ? Colors.black45 : const Color(0x1A000000),
                            blurRadius: 24,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _form,
                        autovalidateMode:
                        _tried ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              IconButton.outlined(
                                tooltip: 'Back',
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back),
                                style: IconButton.styleFrom(
                                  backgroundColor: cardColor,
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size(42, 42),
                                  side: const BorderSide(color: AppColors.primary, width: 1.4),
                                ),
                              ),
                              Expanded(
                                child: Text('🌱 Create Account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: textColor)),
                              ),
                              const SizedBox(width: 42),
                            ]),
                            SizedBox(height: gap + 2),

                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _first,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.givenName],
                                  cursorColor: AppColors.primary,
                                  decoration: _dec(hintWidget: _req('First name', textColor: mutedColor), isDark: isDark, textColor: mutedColor),
                                  validator: (v) => looksLikeName(v ?? '') ? null : 'x',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _last,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.familyName],
                                  cursorColor: AppColors.primary,
                                  decoration: _dec(hintWidget: _req('Last name', textColor: mutedColor), isDark: isDark, textColor: mutedColor),
                                  validator: (v) => looksLikeName(v ?? '') ? null : 'x',
                                ),
                              ),
                            ]),
                            SizedBox(height: gap),

                            Row(children: [
                              Expanded(
                                child: FormField<String>(
                                  validator: (_) => _gender == null ? 'x' : null,
                                  builder: (state) => InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () async {
                                      final g = await _pickGender();
                                      if (g != null) {
                                        setState(() => _gender = g);
                                        state.didChange(g);
                                      }
                                    },
                                    child: InputDecorator(
                                      isEmpty: false,
                                      decoration: _dec(
                                          suffix: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                          isDark: isDark, textColor: mutedColor
                                      ).copyWith(errorText: state.hasError ? 'x' : null),
                                      child: _gender == null
                                          ? _req('Gender', textColor: mutedColor)
                                          : Text(_gender!, style: TextStyle(fontSize: 14.5, color: textColor)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _university,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  cursorColor: AppColors.primary,
                                  decoration: _dec(hint: 'University (optional)', isDark: isDark, textColor: mutedColor)
                                      .copyWith(hintStyle: TextStyle(color: mutedColor, fontSize: 13)),
                                ),
                              ),
                            ]),
                            SizedBox(height: gap),

                            Row(children: [
                              SizedBox(
                                width: 116,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _pickCountry,
                                  child: InputDecorator(
                                    isEmpty: false,
                                    decoration: _dec(isDark: isDark, textColor: mutedColor),
                                    child: Row(children: [
                                      Expanded(
                                        child: Row(children: [
                                          _flag(_country.iso, width: 22, height: 15),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            // 👈 Dynamic text color for +92
                                            child: Text(_country.dial,
                                                style: TextStyle(fontSize: 14.5, color: textColor),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                        ]),
                                      ),
                                      const Icon(Icons.arrow_drop_down, size: 22, color: AppColors.primary),
                                    ]),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.telephoneNumberNational],
                                  inputFormatters: [_PhoneFormatter(_country.maxLen)],
                                  cursorColor: AppColors.primary,
                                  decoration: _dec(hintWidget: _req('Phone number', textColor: mutedColor), isDark: isDark, textColor: mutedColor),
                                  validator: (_) => _phoneOk ? null : 'x',
                                ),
                              ),
                            ]),
                            SizedBox(height: gap),

                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              cursorColor: AppColors.primary,
                              decoration: _dec(hintWidget: _req('Email', textColor: mutedColor), icon: Icons.mail_outline_rounded, isDark: isDark, textColor: mutedColor),
                              validator: (v) => looksLikeEmail((v ?? '').trim()) ? null : 'x',
                            ),
                            SizedBox(height: gap),

                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pass,
                                  obscureText: !_showPass,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.newPassword],
                                  cursorColor: AppColors.primary,
                                  decoration: _dec(
                                      hintWidget: _req('Password', textColor: mutedColor),
                                      suffix: IconButton(
                                        tooltip: _showPass ? 'Hide password' : 'Show password',
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        icon: Icon(_showPass ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20, color: AppColors.primary),
                                        onPressed: () => setState(() => _showPass = !_showPass),
                                      ),
                                      isDark: isDark, textColor: mutedColor
                                  ),
                                  validator: (v) => PasswordRules.ok(v ?? '') ? null : 'x',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _confirm,
                                  obscureText: !_showConfirm,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  autofillHints: const [AutofillHints.newPassword],
                                  cursorColor: AppColors.primary,
                                  decoration: _dec(
                                      hintWidget: _req('Confirm', textColor: mutedColor),
                                      suffix: IconButton(
                                        tooltip: _showConfirm ? 'Hide password' : 'Show password',
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                        icon: Icon(_showConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20, color: AppColors.primary),
                                        onPressed: () => setState(() => _showConfirm = !_showConfirm),
                                      ),
                                      isDark: isDark, textColor: mutedColor
                                  ),
                                  validator: (v) => v == _pass.text ? null : 'x',
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _ruleChip(PasswordRules.hasLength(pass), '8+', mutedColor),
                                  _ruleChip(PasswordRules.hasUpper(pass), 'A-Z', mutedColor),
                                  _ruleChip(PasswordRules.hasLower(pass), 'a-z', mutedColor),
                                  _ruleChip(PasswordRules.hasNumber(pass), '0-9', mutedColor),
                                  _ruleChip(PasswordRules.hasSpecial(pass), 'Symbol', mutedColor),
                                  _ruleChip(_confirm.text.isNotEmpty && _confirm.text == pass, 'Match', mutedColor),
                                ],
                              ),
                            ),
                            SizedBox(height: gap - 3),

                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => _agreed = !_agreed),
                              child: Row(children: [
                                Checkbox(
                                  value: _agreed,
                                  activeColor: AppColors.primary,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  onChanged: (v) => setState(() => _agreed = v ?? false),
                                ),
                                Expanded(
                                  child: Text(
                                    'I understand Mindful Campus is a self-care tool, not a replacement for professional help.',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.25,
                                        color: (_tried && !_agreed) ? AppColors.danger : mutedColor),
                                  ),
                                ),
                              ]),
                            ),

                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(_error ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ),

                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [BoxShadow(color: Color(0x402D9D5F), blurRadius: 12, offset: Offset(0, 5))],
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : const Text('Create Account'),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Already have an account?', style: TextStyle(color: mutedColor, fontSize: 14)),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(builder: (_) => const LoginPage())),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    minimumSize: const Size(48, 40),
                                  ),
                                  child: const Text('Log In', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selected});
  final _Country selected;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final list = _countries.where((c) => c.name.toLowerCase().contains(q) || c.dial.contains(q)).toList();
    final media = MediaQuery.of(context);
    final height = math.min(media.size.height * 0.7, media.size.height - media.viewInsets.bottom - 80);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final Color mutedColor = Theme.of(context).textTheme.bodyMedium?.color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade700);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select your country', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5CC))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : const Color(0xFFCBD5CC))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No country found', style: TextStyle(color: mutedColor)))
                  : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final c = list[i];
                  final isSelected = c.name == widget.selected.name;
                  return ListTile(
                    leading: SizedBox(width: 34, child: Center(child: _flag(c.iso, width: 30, height: 21))),
                    title: Text(c.name, style: TextStyle(color: textColor)),
                    trailing: Text(c.dial, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? AppColors.primary : textColor)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    selectedTileColor: AppColors.primary.withAlpha(isDark ? 40 : 20),
                    onTap: () => Navigator.pop(context, c),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}