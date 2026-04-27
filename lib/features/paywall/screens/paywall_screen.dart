import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selected = 1; // annual by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 200),
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close,
                          color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Gold accent pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: AppColors.goldAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✨',
                          style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Receipt Radar Pro',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.goldAccent,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                Text(
                  'Unlimited\nscans. Ready\nfor tax season.',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: Colors.white, height: 1.05),
                )
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, curve: Curves.easeOutCubic),

                const SizedBox(height: 28),

                ..._features().asMap().entries.map((e) => _FeatureRow(
                      icon: e.value.$1,
                      title: e.value.$2,
                      subtitle: e.value.$3,
                    ).animate(delay: (200 + e.key * 80).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2)),

                const SizedBox(height: 32),

                Text('Pick your plan', style: AppTextStyles.onDarkH3),
                const SizedBox(height: 14),

                _PlanCard(
                  title: 'Monthly',
                  price: '€4.99',
                  period: '/month',
                  selected: _selected == 0,
                  onTap: () => setState(() => _selected = 0),
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  title: 'Annual',
                  price: '€39',
                  period: '/year',
                  badge: 'SAVE 35%',
                  selected: _selected == 1,
                  onTap: () => setState(() => _selected = 1),
                ),
                const SizedBox(height: 10),
                _PlanCard(
                  title: 'Lifetime',
                  price: '€99',
                  period: 'once',
                  selected: _selected == 2,
                  onTap: () => setState(() => _selected = 2),
                ),
              ],
            ),

            // Pinned CTA
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Demo — RevenueCat checkout would open here.'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text('Unlock Pro →',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cancel anytime · 7-day money-back guarantee',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String, String)> _features() => [
        ('∞', 'Unlimited scans',
            'No more 10/month limit. Scan as much as you need.'),
        ('📊', 'DATEV export',
            'Direct import for your Steuerberater. No more manual entry.'),
        ('☁️', 'Cloud backup',
            'Never lose a receipt. Syncs across your devices.'),
        ('📂', 'Multi-year archive',
            'German law requires 10 years. We handle it for you.'),
        ('🚀', 'Priority support',
            'Email support with <24hr response time.'),
      ];
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: AppColors.goldAccent)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.onDarkH3.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.onDarkBody.copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.goldAccent.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.goldAccent
                : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.goldAccent
                      : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                color: selected ? AppColors.goldAccent : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: AppTextStyles.labelLarge
                              .copyWith(color: Colors.white)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: AppTextStyles.h3.copyWith(color: Colors.white)),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    period,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
