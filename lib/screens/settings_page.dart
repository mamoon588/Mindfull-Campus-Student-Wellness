import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _trustedNameController = TextEditingController();
  final _trustedPhoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<Color> _themeColors = const [
    Color(0xFF2D9D5F), Color(0xFF1976D2), Color(0xFF7B1FA2), Color(0xFFE64A19), Color(0xFFC2185B),
  ];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    _nameController.text = app.userName;
    _emailController.text = app.userEmail;
    _trustedNameController.text = app.trustedPersonName;
    _trustedPhoneController.text = app.trustedPersonPhone;
  }

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose();
    _trustedNameController.dispose(); _trustedPhoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      context.read<AppState>().updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );
      showToast(context, 'Profile updated successfully', kind: ToastKind.success);
    }
  }

  void _saveContact() {
    context.read<AppState>().updateTrustedContact(
      _trustedNameController.text.trim(),
      _trustedPhoneController.text.trim(),
    );
    showToast(context, 'Emergency contact saved', kind: ToastKind.success);
  }

  void _pickTime() async {
    final app = context.read<AppState>();
    final parts = app.reminderTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      app.setReminder(app.reminderEnabled, timeStr);
    }
  }

  void _confirmClearData() async {
    final app = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Reset App?'),
        content: const Text('This will permanently delete ALL your data, including moods, sleep, journals, and account info. You will be logged out.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.clearAllData();
    }
  }

  void _showExportOptions() {
    final app = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Choose Export Format', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Export as PDF'),
              subtitle: const Text('Best for printing or viewing'),
              onTap: () { Navigator.pop(context); app.exportDataAsPDF(); },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Export as CSV'),
              subtitle: const Text('Best for Excel or Google Sheets'),
              onTap: () { Navigator.pop(context); app.exportDataAsCSV(); },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Colors.blue),
              title: const Text('Export as MP3 (Audio)'),
              subtitle: const Text('Generates an audio summary (Mobile Only)'),
              onTap: () { Navigator.pop(context); app.exportDataAsMP3(); },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final isDark = app.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('Profile', 'Update your personal information'),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Name cannot be empty' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                    validator: (v) => !looksLikeEmail(v ?? '') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _saveProfile, child: const Text('Save Profile')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('Appearance', 'Customize how the app looks'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Easier on the eyes at night'),
                  value: app.isDarkMode,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) => app.toggleDarkMode(v),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _themeColors.map((color) {
                    final isSelected = app.themeColorValue == color.toARGB32();
                    return GestureDetector(
                      onTap: () => app.setThemeColor(color.toARGB32()),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 45, height: 45,
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? (isDark ? Colors.white : Colors.black) : Colors.transparent, width: 3),
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 32),

                // 👈 FIXED: Replaced Slider with ChoiceChips for Text Size
                const Text('Text Size', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ChoiceChip(label: const Text('Small'), selected: app.textScale == 0.85, onSelected: (v) => app.setTextScale(0.85)),
                    ChoiceChip(label: const Text('Normal'), selected: app.textScale == 1.0, onSelected: (v) => app.setTextScale(1.0)),
                    ChoiceChip(label: const Text('Large'), selected: app.textScale == 1.15, onSelected: (v) => app.setTextScale(1.15)),
                    ChoiceChip(label: const Text('X-Large'), selected: app.textScale == 1.3, onSelected: (v) => app.setTextScale(1.3)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('Accessibility & Sounds', 'Haptics, Reminders and Audio'),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Haptic Feedback', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Vibrate when tapping habits or timers'),
                  value: app.hapticsEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) => app.setHaptics(v),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Focus Timer Sound', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Play a relaxing chime when focus ends'),
                  value: app.focusSoundEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) => app.setFocusSound(v, app.focusSoundType),
                  contentPadding: EdgeInsets.zero,
                ),
                if (app.focusSoundEnabled) ...[
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('🔔 Bell')),
                      ButtonSegment(value: 1, label: Text('🎵 Soft')),
                      ButtonSegment(value: 2, label: Text('🌿 Nature')),
                    ],
                    selected: {app.focusSoundType},
                    onSelectionChanged: (v) => app.setFocusSound(true, v.first),
                  ),
                ],
                const Divider(),
                SwitchListTile(
                  title: const Text('Daily Check-in Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('Remind me at ${app.reminderTime}'),
                  value: app.reminderEnabled,
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                  onChanged: (v) {
                    app.setReminder(v, app.reminderTime);
                    if (v) _pickTime();
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                if (app.reminderEnabled)
                  TextButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text('Change Time (${app.reminderTime})'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('Emergency Contact', 'Used in your Safety Plan and Crisis Support'),
          AppCard(
            child: Column(
              children: [
                TextFormField(
                  controller: _trustedNameController,
                  decoration: const InputDecoration(labelText: 'Trusted Person Name', prefixIcon: Icon(Icons.contact_phone)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _trustedPhoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _saveContact, child: const Text('Save Contact')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const SectionHeader('Data Management', 'Export or reset your data'),
          AppCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download, color: Colors.blue),
                  title: const Text('Export My Data', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Choose PDF, CSV, or Audio format'),
                  trailing: const Icon(Icons.chevron_right),
                  // 👈 FIXED: Opens the export bottom sheet
                  onTap: _showExportOptions,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Reset App / Clear Data', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red)),
                  subtitle: const Text('Wipe all local data and log out'),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: _confirmClearData,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Center(
            child: Column(
              children: [
                Text('Mindful Campus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Version 1.0.0', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                SizedBox(height: 4),
                Text(
                  'A wellness companion built to help students track their mood, sleep, and habits in a safe, local environment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                SizedBox(height: 8),
                // 👈 FIXED: Changed to Mindfullness Corporation
                Text('Developed by Mindfullness Corporation', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}