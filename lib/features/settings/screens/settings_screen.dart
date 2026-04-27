import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/receipt_store.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Settings', style: AppTextStyles.h4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Pro upgrade card
          _ProUpgradeCard(onTap: () => context.push(AppRoutes.paywall)),
          const SizedBox(height: 24),

          const _SectionLabel('DATA'),
          _SettingsTile(
            icon: Icons.delete_outline,
            iconColor: AppColors.error,
            title: 'Clear all receipts',
            subtitle: 'Permanently remove all data',
            onTap: () => _confirmClear(context, ref),
          ),

          const SizedBox(height: 24),

          const _SectionLabel('ABOUT'),
          _SettingsTile(
            icon: Icons.info_outline,
            iconColor: AppColors.info,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            iconColor: AppColors.accent,
            title: 'Privacy',
            subtitle: 'All data stays on your device',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.mail_outline,
            iconColor: AppColors.goldAccent,
            title: 'Contact support',
            subtitle: 'hello@receiptradar.app',
            onTap: () {},
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Made with ❤️ for German freelancers',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear all receipts?', style: AppTextStyles.h4),
        content: Text(
          'This will permanently delete all your scanned receipts. '
          'This cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(receiptsProvider.notifier).clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All receipts cleared')),
        );
      }
    }
  }
}

class _ProUpgradeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _ProUpgradeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF15201F), Color(0xFF3D2F15)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4)),
              ),
              child: const Center(
                child: Text('✨',
                    style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade to Pro',
                      style: AppTextStyles.onDarkH3.copyWith(fontSize: 17)),
                  const SizedBox(height: 2),
                  Text(
                    'Unlimited scans + DATEV export',
                    style: AppTextStyles.onDarkBody.copyWith(
                        fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward,
                color: AppColors.goldAccent.withValues(alpha: 0.9), size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text, style: AppTextStyles.labelSmall),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle,
                      style:
                          AppTextStyles.bodySmall.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
