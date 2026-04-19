import 'dart:io';
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
import '../widgets/category_picker.dart';

class ReceiptReviewScreen extends ConsumerStatefulWidget {
  final String receiptId;
  const ReceiptReviewScreen({super.key, required this.receiptId});

  @override
  ConsumerState<ReceiptReviewScreen> createState() =>
      _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends ConsumerState<ReceiptReviewScreen> {
  late TextEditingController _merchantCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _vatCtrl;
  late TextEditingController _notesCtrl;
  late DateTime _date;
  late double _vatRate;
  late String _categoryId;
  Receipt? _receipt;

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController();
    _totalCtrl = TextEditingController();
    _vatCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _date = DateTime.now();
    _vatRate = 19.0;
    _categoryId = 'other';
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _totalCtrl.dispose();
    _vatCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _syncFromReceipt(Receipt r) {
    if (_receipt?.id == r.id) return; // already synced
    _receipt = r;
    _merchantCtrl.text = r.merchant;
    _totalCtrl.text = r.totalAmount.toStringAsFixed(2);
    _vatCtrl.text = r.vatAmount.toStringAsFixed(2);
    _notesCtrl.text = r.notes ?? '';
    _date = r.date;
    _vatRate = r.vatRate;
    _categoryId = r.categoryId;
  }

  Future<void> _save() async {
    if (_receipt == null) return;
    final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
    final vat = double.tryParse(_vatCtrl.text.replaceAll(',', '.')) ?? 0;

    final updated = _receipt!.copyWith(
      merchant: _merchantCtrl.text.trim().isEmpty
          ? 'Unknown'
          : _merchantCtrl.text.trim(),
      date: _date,
      totalAmount: total,
      vatAmount: vat,
      vatRate: _vatRate,
      categoryId: _categoryId,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    await ref.read(receiptsProvider.notifier).updateReceipt(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt saved ✓'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
    context.go(AppRoutes.home);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final asyncReceipts = ref.watch(receiptsProvider);

    return asyncReceipts.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (receipts) {
        final receipt = receipts.firstWhere(
          (r) => r.id == widget.receiptId,
          orElse: () => receipts.isNotEmpty
              ? receipts.first
              : Receipt(
                  merchant: 'Unknown',
                  date: DateTime.now(),
                  totalAmount: 0,
                ),
        );
        _syncFromReceipt(receipt);
        return _buildContent(receipt);
      },
    );
  }

  Widget _buildContent(Receipt receipt) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Review Receipt', style: AppTextStyles.h4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          // Image preview
          if (receipt.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(receipt.imagePath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppColors.bgTertiary,
                  child: const Center(
                    child: Icon(Icons.image_not_supported,
                        size: 40, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Merchant
          _fieldLabel('Merchant'),
          TextField(
            controller: _merchantCtrl,
            decoration:
                const InputDecoration(hintText: 'e.g. Shell Deutschland'),
          ),
          const SizedBox(height: 16),

          // Date
          _fieldLabel('Date'),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(_date),
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amounts row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Total (€)'),
                    TextField(
                      controller: _totalCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('VAT (€)'),
                    TextField(
                      controller: _vatCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(hintText: '0.00'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // VAT rate selector
          _fieldLabel('VAT Rate'),
          Row(
            children: AppConstants.vatRates.map((rate) {
              final isSelected = rate == _vatRate;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _vatRate = rate),
                  child: Container(
                    margin: EdgeInsets.only(
                        right: rate == AppConstants.vatRates.last ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.accent : AppColors.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                        width: isSelected ? 0 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${rate.toInt()}%',
                        style: AppTextStyles.labelLarge.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Category picker
          _fieldLabel('Tax Category'),
          CategoryPicker(
            selectedId: _categoryId,
            onSelect: (id) => setState(() => _categoryId = id),
          ),
          const SizedBox(height: 20),

          // Notes
          _fieldLabel('Notes (optional)'),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'e.g. Client meeting, project name...',
            ),
          ),
          const SizedBox(height: 24),

          // Tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accent.withOpacity(0.15), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Double-check amounts — the OCR is smart but not perfect. Your Steuerberater will thank you.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentDark,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Save Receipt'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.labelSmall),
    );
  }
}
