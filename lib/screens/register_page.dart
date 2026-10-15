import 'dart:math' as math;

import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../utils.dart';
import '../widgets/common.dart';
import 'login_page.dart';

// Colours used only on the auth pages (same teal as the login page).
const _teal = Color(0xFF2D9D5F); // = AppColors.primary
const _tealSoft = Color(0xFFE8F6EE); // = AppColors.primarySoft
const _title = Color(0xFF272E29); // = AppColors.text
const _fieldBorder = Color(0xFFCBD5CC); // = AppColors.border
const _pageBg = Color(0xFFF6FAF7); // = AppColors.bg
const _muted = Color(0xFF748078); // = AppColors.muted
const _danger = Color(0xFFDC2626);

// =====================================================================
// Countries for the phone-number picker.
// minLen / maxLen = digits of the number WITHOUT the country code and
// without a leading 0 (approximate rules, adjust if you need stricter ones).
// =====================================================================
class _Country {
  const _Country(this.iso, this.name, this.dial, this.minLen, this.maxLen);
  final String iso; // ISO 2-letter code, used to draw the flag image
  final String name;
  final String dial;
  final int minLen;
  final int maxLen;
}

// Pakistan stays first (default); the rest are sorted A-Z in _countries below.
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

// Flag drawn as an image (emoji flags do not render on Windows / Chrome)
Widget _flag(String iso, {double width = 26, double height = 18}) => CountryFlag.fromCountryCode(
  iso,
  theme: ImageTheme(width: width, height: height, shape: const RoundedRectangle(3)),
);

// Digits only, and never longer than the selected country allows
// (+1 only when the user types a leading 0, e.g. 03001234567).
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

  _Country _country = _countries.first; // Pakistan by default
  String? _gender;
  bool _agreed = false;
  bool _showPass = false;
  bool _busy = false;
  bool _tried = false; // true after the first press of "Create Account"
  String? _error; // ONE message line, so the page never grows taller

  @override
  void initState() {
    super.initState();
    _pass.addListener(() => setState(() {})); // live password check
    _confirm.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _university, _email, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  // Phone digits without any leading zeros (03001234567 -> 3001234567)
  String get _phoneDigits =>
      _phone.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');

  bool get _phoneOk {
    final n = _phoneDigits.length;
    if (n < _country.minLen || n > _country.maxLen) return false;
    // Pakistani mobile numbers are 03XX XXXXXXX
    if (_country.dial == '+92' && !_phoneDigits.startsWith('3')) return false;
    return true;
  }

  String get _phoneNeed => _country.minLen == _country.maxLen
      ? '${_country.minLen}'
      : '${_country.minLen}-${_country.maxLen}';

  // The first thing that is wrong, in the order the fields appear
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
      backgroundColor: Colors.white,
      builder: (_) => _CountrySheet(selected: _country),
    );
    if (c != null) {
      setState(() => _country = c);
      // shorten an already-typed number if the new country allows fewer digits
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
      backgroundColor: Colors.white,
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
                        fontSize: 18, fontWeight: FontWeight.w700, color: _title)),
              ),
            ),
            for (final o in options)
              ListTile(
                leading: Icon(o.$2, color: _teal),
                title: Text(o.$1),
                trailing: _gender == o.$1
                    ? const Icon(Icons.check_circle, color: _teal)
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
    final fieldsOk = _form.currentState!.validate(); // paints red borders
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
    nav.popUntil((route) => route.isFirst); // back to the root, which is now the dashboard
    toastOn(messenger, '🎉 Welcome to Mindful Campus, $first!', kind: ToastKind.success);
  }

  // ---------- small UI helpers ----------
  OutlineInputBorder _border(Color color, [double width = 1.2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );

  // Placeholder with a RED asterisk for required fields
  Widget _req(String text, {double size = 14.5}) => Text.rich(
    TextSpan(
      text: text,
      style: TextStyle(color: const Color(0xFF222B33), fontSize: size),
      children: [
        TextSpan(
            text: ' *',
            style: TextStyle(
                color: _danger, fontSize: size, fontWeight: FontWeight.w700)),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  // Compact field style. The error text is hidden on purpose (size 0): an
  // invalid field just gets a red border and the message shows in ONE line
  // above the button, so the layout never jumps and never needs scrolling.
  InputDecoration _dec({String? hint, Widget? hintWidget, IconData? icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hint: hintWidget,
      hintStyle: const TextStyle(color: Color(0xFF222B33), fontSize: 14.5),
      prefixIcon: icon == null ? null : Icon(icon, color: _teal, size: 20),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 36),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      errorStyle: const TextStyle(fontSize: 0, height: 0),
      border: _border(_fieldBorder),
      enabledBorder: _border(_fieldBorder),
      focusedBorder: _border(_teal, 1.8),
      errorBorder: _border(_danger),
      focusedErrorBorder: _border(_danger, 1.8),
    );
  }

  Widget _ruleChip(bool ok, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14, color: ok ? _teal : _muted),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11.5, color: ok ? _teal : _muted)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final pass = _pass.text;
    // On short phones the gaps shrink a little so everything still fits
    final short = MediaQuery.of(context).size.height < 640;
    final gap = short ? 8.0 : 11.0;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: LayoutBuilder(builder: (context, c) {
          // The page only scrolls if the keyboard covers part of it
          // (or the phone is extremely small). Normally nothing scrolls.
          // On a phone the page covers the whole screen; on a wide screen
          // (Chrome / tablet) it is a phone-sized rounded card.
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28), // rounded corners
                      border: Border.all(color: const Color(0xFFDDEFE3)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 24,
                            offset: Offset(0, 8)),
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
                            // ---------- Back button + title on ONE row ----------
                            Row(children: [
                              IconButton.outlined(
                                tooltip: 'Back',
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _teal,
                                  minimumSize: const Size(42, 42),
                                  side: const BorderSide(color: _teal, width: 1.4),
                                ),
                              ),
                              const Expanded(
                                child: Text('🌱 Create Account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: _title)),
                              ),
                              const SizedBox(width: 42), // keeps the title centred
                            ]),
                            SizedBox(height: gap + 2),

                            // ---------- First name | Last name ----------
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _first,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.givenName],
                                  cursorColor: _teal,
                                  decoration: _dec(hintWidget: _req('First name')),
                                  validator: (v) =>
                                  looksLikeName(v ?? '') ? null : 'x',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _last,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.familyName],
                                  cursorColor: _teal,
                                  decoration: _dec(hintWidget: _req('Last name')),
                                  validator: (v) =>
                                  looksLikeName(v ?? '') ? null : 'x',
                                ),
                              ),
                            ]),
                            SizedBox(height: gap),

                            // ---------- Gender (list) | University (optional) ----------
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
                                        suffix: const Icon(Icons.arrow_drop_down,
                                            color: _teal),
                                      ).copyWith(
                                          errorText: state.hasError ? 'x' : null),
                                      child: _gender == null
                                          ? _req('Gender')
                                          : Text(_gender!,
                                          style: const TextStyle(
                                              fontSize: 14.5, color: Colors.black87)),
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
                                  cursorColor: _teal,
                                  decoration: _dec(hint: 'University (optional)')
                                      .copyWith(
                                      hintStyle: const TextStyle(
                                          color: Color(0xFF222B33),
                                          fontSize: 13)),
                                ),
                              ),
                            ]),
                            SizedBox(height: gap),

                            // ---------- Country code | Phone number ----------
                            Row(children: [
                              SizedBox(
                                width: 116,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _pickCountry,
                                  child: InputDecorator(
                                    isEmpty: false,
                                    decoration: _dec(),
                                    child: Row(children: [
                                      Expanded(
                                        child: Row(children: [
                                          _flag(_country.iso, width: 22, height: 15),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(_country.dial,
                                                style: const TextStyle(fontSize: 14.5),
                                                overflow: TextOverflow.ellipsis),
                                          ),
                                        ]),
                                      ),
                                      const Icon(Icons.arrow_drop_down,
                                          size: 22, color: _teal),
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
                                  autofillHints: const [
                                    AutofillHints.telephoneNumberNational
                                  ],
                                  inputFormatters: [_PhoneFormatter(_country.maxLen)],
                                  cursorColor: _teal,
                                  decoration: _dec(hintWidget: _req('Phone number')),
                                  validator: (_) => _phoneOk ? null : 'x',
                                ),
                              ),
                            ]),
                            SizedBox(height: gap),

                            // ---------- Email ----------
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              cursorColor: _teal,
                              decoration:
                              _dec(hintWidget: _req('Email'), icon: Icons.mail_outline_rounded),
                              validator: (v) =>
                              looksLikeEmail((v ?? '').trim()) ? null : 'x',
                            ),
                            SizedBox(height: gap),

                            // ---------- Password | Confirm ----------
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pass,
                                  obscureText: !_showPass,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.newPassword],
                                  cursorColor: _teal,
                                  decoration: _dec(
                                    hintWidget: _req('Password'),
                                    suffix: IconButton(
                                      tooltip: _showPass ? 'Hide password' : 'Show password',
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(
                                          minWidth: 36, minHeight: 36),
                                      icon: Icon(
                                          _showPass
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          size: 20,
                                          color: _teal),
                                      onPressed: () =>
                                          setState(() => _showPass = !_showPass),
                                    ),
                                  ),
                                  validator: (v) =>
                                  PasswordRules.ok(v ?? '') ? null : 'x',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _confirm,
                                  obscureText: !_showPass,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  autofillHints: const [AutofillHints.newPassword],
                                  cursorColor: _teal,
                                  decoration: _dec(hintWidget: _req('Confirm')),
                                  validator: (v) => v == _pass.text ? null : 'x',
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),

                            // ---------- Live password check (one line) ----------
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _ruleChip(PasswordRules.hasLength(pass), '8+'),
                                  _ruleChip(PasswordRules.hasUpper(pass), 'A-Z'),
                                  _ruleChip(PasswordRules.hasLower(pass), 'a-z'),
                                  _ruleChip(PasswordRules.hasNumber(pass), '0-9'),
                                  _ruleChip(PasswordRules.hasSpecial(pass), 'Symbol'),
                                  _ruleChip(
                                      _confirm.text.isNotEmpty && _confirm.text == pass,
                                      'Match'),
                                ],
                              ),
                            ),
                            SizedBox(height: gap - 3),

                            // ---------- Agreement ----------
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setState(() => _agreed = !_agreed),
                              child: Row(children: [
                                Checkbox(
                                  value: _agreed,
                                  activeColor: _teal,
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
                                        color: (_tried && !_agreed) ? _danger : _muted),
                                  ),
                                ),
                              ]),
                            ),

                            // ---------- ONE reserved line for any problem ----------
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(_error ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: _danger,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ),
                            ),

                            // ---------- Create button ----------
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x402D9D5F),
                                      blurRadius: 12,
                                      offset: Offset(0, 5)),
                                ],
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _teal,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  textStyle: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w600),
                                ),
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                    : const Text('Create Account'),
                              ),
                            ),

                            // ---------- Login link ----------
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account?',
                                    style: TextStyle(color: _muted, fontSize: 14)),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                          builder: (_) => const LoginPage())),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _teal,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    minimumSize: const Size(48, 40),
                                  ),
                                  child: const Text('Log In',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700, fontSize: 14)),
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

// =====================================================================
// Bottom sheet with a search box and the list of countries
// =====================================================================
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
    final list = _countries
        .where((c) => c.name.toLowerCase().contains(q) || c.dial.contains(q))
        .toList();
    final media = MediaQuery.of(context);
    final height =
    math.min(media.size.height * 0.7, media.size.height - media.viewInsets.bottom - 80);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select your country',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: _title)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                cursorColor: _teal,
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: const Icon(Icons.search, color: _teal),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _fieldBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _fieldBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _teal, width: 1.8)),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const Center(
                  child: Text('No country found', style: TextStyle(color: _muted)))
                  : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final c = list[i];
                  final isSelected = c.name == widget.selected.name;
                  return ListTile(
                    leading: SizedBox(width: 34, child: Center(child: _flag(c.iso, width: 30, height: 21))),
                    title: Text(c.name),
                    trailing: Text(c.dial,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? _teal : _title)),
                    selected: isSelected,
                    selectedColor: _teal,
                    selectedTileColor: _tealSoft,
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