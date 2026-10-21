import 'package:flutter/material.dart';
import '../theme.dart';

enum ToastKind { info, success, error }

void toastOn(ScaffoldMessengerState messenger, String message,
    {ToastKind kind = ToastKind.info}) {
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
    backgroundColor: switch (kind) {
      ToastKind.error => AppColors.danger,
      ToastKind.success => const Color(0xFF22A15A),
      ToastKind.info => AppColors.text,
    },
  ));
}

void showToast(BuildContext context, String message,
    {ToastKind kind = ToastKind.info}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m != null) toastOn(m, message, kind: kind);
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final bgColor = color ?? Theme.of(context).cardColor;

    // 👈 HCI FIX: Automatically check if background is light. If so, force dark text.
    final isLightBackground = bgColor.computeLuminance() > 0.5;

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(50)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: isLightBackground ? const Color(0xFF272E29) : Colors.white),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, this.subtitle, {super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150))),
        ],
      ),
    );
  }
}

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            for (final e in items.entries)
              DropdownMenuItem<T>(
                value: e.key,
                child: Text(e.value, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class Callout extends StatelessWidget {
  const Callout({super.key, required this.color, required this.child, this.accent});
  final Color color;
  final Color? accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 👈 HCI FIX: Automatically fix text color inside Callouts
    final isLightBackground = color.computeLuminance() > 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: accent == null ? null : Border(left: BorderSide(color: accent!, width: 3)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: isLightBackground ? const Color(0xFF272E29) : Colors.white),
        child: child,
      ),
    );
  }
}

class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.spacing = 10,
  });
  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var j = 0; j < columns; j++) ...[
              if (j > 0) SizedBox(width: spacing),
              Expanded(child: j < slice.length ? slice[j] : const SizedBox.shrink()),
            ],
          ],
        ),
      ));
      if (i + columns < children.length) rows.add(SizedBox(height: spacing));
    }
    return Column(children: rows);
  }
}