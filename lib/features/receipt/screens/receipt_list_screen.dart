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

class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});
  @override
  ConsumerState<ReceiptListScreen> createState() =>
      _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final asyncReceipts = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('All Receipts', style: AppTextStyles.h4),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => context.push(AppRoutes.export),
          ),
        ],
      ),
      body: asyncReceipts.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (receipts) {
          final filtered = _filter == 'all'
              ? receipts
              : receipts.where((r) => r.categoryId == _filter).toList();

          // Sort: newest date first
          filtered.sort((a, b) => b.date.compareTo(a.date));

          return Column(
            children: [
              // Category filter chips
              _FilterBar(
                selected: _filter,
                onSelect: (id) => setState(() => _filter = id),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyList()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _ListRow(
                          receipt: filtered[i],
                          onTap: () => context.push(
                              '${AppRoutes.detail}?id=${filtered[i].id}'),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterBar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      ('all', 'All'),
      ...AppConstants.taxCategories.map((c) => (c.id, c.nameDe)),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (id, label) = options[i];
          final isSelected = id == selected;
          return GestureDetector(
            onTap: () => onSelect(id),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onTap;
  const _ListRow({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = AppConstants.categoryById(receipt.categoryId);
    final fmt = NumberFormat.currency(locale: 'de_DE', symbol: '€');

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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text(cat.emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receipt.merchant,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${cat.nameDe} · ${DateFormat('d MMM yyyy').format(receipt.date)}',
                    style:
                        AppTextStyles.bodySmall.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(fmt.format(receipt.totalAmount),
                    style: AppTextStyles.labelLarge),
                Text(
                  'incl. ${fmt.format(receipt.vatAmount)} VAT',
                  style:
                      AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗂️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text('No receipts in this category',
                style: AppTextStyles.h4),
            const SizedBox(height: 4),
            Text(
              'Try a different filter or scan a new receipt',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
