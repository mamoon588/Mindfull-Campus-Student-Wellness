import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/call.dart';
import '../widgets/common.dart';

class CrisisPage extends StatelessWidget {
  const CrisisPage({super.key});

  @override
  Widget build(BuildContext context) {
    const contacts = [
      ('📞', '1166 Helpline', 'National Mental Health', '1166', true),
      ('🤝', 'Taskeen', '0316-8275336', '0316-8275336', false),
      ('👥', 'Rozan', '0800-22444', '0800-22444', false),
      ('🚑', 'Rescue 1122', 'Emergency', '1122', true),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('🆘 Crisis Support (Pakistan)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              children: [
                const Text('⚠️ Need Immediate Help?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Trained counselors available 24/7',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                const Text('1166',
                    style: TextStyle(
                        fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.danger)),
                const Text('National Mental Health Helpline',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  onPressed: () => callNumber(context, '1166'),
                  child: const Text('📞 Call 1166 now'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final (icon, title, subtitle, number, emergency) in contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => callNumber(context, number),
                color: emergency ? AppColors.dangerSoft : Colors.white,
                child: Row(children: [
                  Text(icon, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(subtitle, style: const TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.call, color: AppColors.primary),
                ]),
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'Mindful Campus is not a substitute for professional care. '
            'If you or someone you know is in danger, call emergency services immediately.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
