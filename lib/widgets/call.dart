import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common.dart';

/// Opens the phone dialer with [number] pre-filled.
Future<void> callNumber(BuildContext context, String number) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = Uri(scheme: 'tel', path: number.replaceAll('-', ''));
  try {
    final ok = await launchUrl(uri);
    if (!ok) {
      toastOn(messenger, 'Could not open the phone app. Please dial $number.',
          kind: ToastKind.error);
    }
  } catch (_) {
    toastOn(messenger, 'Could not open the phone app. Please dial $number.',
        kind: ToastKind.error);
  }
}
