import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/receipt_store.dart';
import '../models/receipt.dart';
import '../../../shared/widgets/receipt_image.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;
  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReceipts = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: asyncReceipts.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (receipts) {
          Receipt? receipt;
          try {
            receipt = receipts.firstWhere((r) => r.id == receiptId);
          } catch (_) {
            receipt = null;
          }

          if (receipt == null) {
            return const Center(
              child: Text('Receipt not found'),
            );
          }

          return _DetailContent(receipt: receipt);
        },
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final Receipt receipt;
  const _DetailContent({required this.receipt});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete receipt?', style: AppTextStyles.h4),
        content: Text(
          'This will permanently remove this receipt from your records.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(receiptsProvider.notifier).delete(receipt.id);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = AppConstants.categoryById(receipt.categoryId);
    final fmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  context.push('${AppRoutes.review}?id=${receipt.id}'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmDelete(context, ref),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview (only renders on mobile; null/empty on web)
                if (receipt.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ReceiptImage(path: receipt.imagePath!),
                  ),
                const SizedBox(height: 24),

                // Category pill
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            cat.nameDe,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: cat.color,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Merchant
                Text(receipt.merchant, style: AppTextStyles.h1),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(receipt.date),
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),

                // Total
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 6),
                      Text(fmt.format(receipt.totalAmount),
                          style: AppTextStyles.monoLarge),
                      const Divider(height: 28),
                      _row('Net amount', fmt.format(receipt.netAmount)),
                      const SizedBox(height: 10),
                      _row(
                          'VAT (${receipt.vatRate.toStringAsFixed(0)}%)',
                          fmt.format(receipt.vatAmount)),
                      const SizedBox(height: 10),
                      _row('DATEV account', cat.datevAccount),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                  Text('Notes', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border, width: 0.5),
                    ),
                    child: Text(receipt.notes!,
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(value, style: AppTextStyles.labelMedium),
      ],
    );
  }
}
