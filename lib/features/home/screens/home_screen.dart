import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_store.dart';
import '../../receipt/models/receipt.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReceipts = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: asyncReceipts.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error: $e', style: AppTextStyles.bodyMedium),
            ),
          ),
          data: (receipts) => _HomeContent(receipts: receipts),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.scanner),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text(
          'Scan Receipt',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final List<Receipt> receipts;
  const _HomeContent({required this.receipts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalThisMonth = _totalThisMonth(receipts);
    final vatThisMonth   = _vatThisMonth(receipts);
    final countThisMonth = _countThisMonth(receipts);
    final recentReceipts = receipts.take(5).toList();

    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Receipt Radar', style: AppTextStyles.h1),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.settings),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.settings_outlined, size: 20),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, curve: Curves.easeOutCubic),
          ),
        ),

        // ── Hero stats card ──
        SliverToBoxAdapter(
          child: _StatsCard(
            total: totalThisMonth,
            vat: vatThisMonth,
            count: countThisMonth,
          )
              .animate(delay: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
        ),

        // ── Quick actions ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.receipt_long_outlined,
                    label: 'All Receipts',
                    sub: '${receipts.length} total',
                    color: AppColors.accent,
                    onTap: () => context.push(AppRoutes.list),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.ios_share_rounded,
                    label: 'Export CSV',
                    sub: 'DATEV ready',
                    color: AppColors.goldAccent,
                    onTap: () => context.push(AppRoutes.export),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOutCubic),
        ),

        // ── Recent receipts header ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent', style: AppTextStyles.h3),
                if (receipts.length > 5)
                  TextButton(
                    onPressed: () => context.push(AppRoutes.list),
                    child: Text(
                      'See all',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Recent receipts list ──
        if (recentReceipts.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyState(onTap: () => context.push(AppRoutes.scanner)),
          )
        else
          SliverList.builder(
            itemCount: recentReceipts.length,
            itemBuilder: (ctx, i) => _ReceiptRow(
              receipt: recentReceipts[i],
              onTap: () => context.push(
                '${AppRoutes.detail}?id=${recentReceipts[i].id}',
              ),
            ).animate(delay: Duration(milliseconds: 250 + i * 60))
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.1),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  double _totalThisMonth(List<Receipt> rs) {
    final now = DateTime.now();
    return rs
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold<double>(0, (s, r) => s + r.totalAmount);
  }

  double _vatThisMonth(List<Receipt> rs) {
    final now = DateTime.now();
    return rs
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold<double>(0, (s, r) => s + r.vatAmount);
  }

  int _countThisMonth(List<Receipt> rs) {
    final now = DateTime.now();
    return rs
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .length;
  }
}

// ══════════════════════════════════════════
//  Stats card
// ══════════════════════════════════════════
class _StatsCard extends StatelessWidget {
  final double total;
  final double vat;
  final int count;

  const _StatsCard({
    required this.total,
    required this.vat,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.darkCardGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THIS MONTH',
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(total),
            style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'VAT Paid',
                  value: fmt.format(vat),
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Receipts',
                  value: '$count',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  Quick action tile
// ══════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label, style: AppTextStyles.labelLarge),
            Text(sub,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  Receipt row
// ══════════════════════════════════════════
class _ReceiptRow extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;

  const _ReceiptRow({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = AppConstants.categoryById(receipt.categoryId);
    final fmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');
    final dateFmt = DateFormat('d MMM');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchant,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cat.nameDe} · ${dateFmt.format(receipt.date)}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              fmt.format(receipt.totalAmount),
              style: AppTextStyles.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  Empty state
// ══════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          const Text('📸', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No receipts yet', style: AppTextStyles.h4),
          const SizedBox(height: 4),
          Text(
            'Tap the button below to scan\nyour first receipt',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Scan Now'),
          ),
        ],
      ),
    );
  }
}
